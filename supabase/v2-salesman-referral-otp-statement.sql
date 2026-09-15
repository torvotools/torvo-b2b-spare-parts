-- TORVO V2 SALESMAN REFERRAL OTP + STATEMENT
-- Install after customer/dealer referral network, dealer-salesman mapping and staff identity foundations.
-- OTP delivery remains a trusted WhatsApp provider/worker responsibility. Plain OTP is never stored.

create table if not exists salesman_referral_otp_challenges(
  id uuid primary key default gen_random_uuid(),
  referral_id uuid not null references customer_dealer_referrals(id) on delete cascade,
  salesman_user_id uuid not null references app_users(id) on delete restrict,
  otp_hash text not null,
  expires_at timestamptz not null,
  attempts integer not null default 0 check(attempts between 0 and 5),
  verified_at timestamptz,
  consumed_at timestamptz,
  created_at timestamptz not null default now(),
  check(expires_at>created_at)
);
create index if not exists idx_salesman_referral_otp_active on salesman_referral_otp_challenges(salesman_user_id,referral_id,created_at desc);
alter table salesman_referral_otp_challenges enable row level security;
revoke all on salesman_referral_otp_challenges from anon,authenticated;

create table if not exists salesman_referral_verifications(
  id uuid primary key default gen_random_uuid(),
  referral_id uuid not null unique references customer_dealer_referrals(id) on delete restrict,
  salesman_user_id uuid not null references app_users(id) on delete restrict,
  dealer_id uuid not null references dealers(id) on delete restrict,
  verified_at timestamptz not null default now(),
  otp_challenge_id uuid not null references salesman_referral_otp_challenges(id) on delete restrict
);
alter table salesman_referral_verifications enable row level security;
revoke all on salesman_referral_verifications from anon,authenticated;

create or replace function salesman_start_referral_otp(p_referral_code text)
returns table(challenge_id uuid,expires_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;r customer_dealer_referrals%rowtype;v_id uuid;v_exp timestamptz:=now()+interval '10 minutes';v_plain text;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true and role='salesman';
 if not found then raise exception 'ACTIVE SALESMAN REQUIRED';end if;
 select * into r from customer_dealer_referrals where referral_code=upper(btrim(p_referral_code)) for update;
 if not found or r.status in('expired','cancelled') or r.expires_at<=now() then raise exception 'ACTIVE REFERRAL REQUIRED';end if;
 if r.dealer_id is null then raise exception 'REFERRAL DEALER REQUIRED';end if;
 if not exists(select 1 from dealer_salesman_mapping m where m.dealer_id=r.dealer_id and m.salesman_user_id=u.id and coalesce(m.active,true)=true) then raise exception 'SALESMAN NOT MAPPED TO REFERRAL DEALER';end if;
 -- Generate six digits server-side. Provider worker sends this value through WhatsApp; DB stores only crypt hash.
 v_plain:=lpad((floor(random()*1000000))::int::text,6,'0');
 update salesman_referral_otp_challenges set consumed_at=coalesce(consumed_at,now()) where salesman_user_id=u.id and referral_id=r.id and verified_at is null and consumed_at is null;
 insert into salesman_referral_otp_challenges(referral_id,salesman_user_id,otp_hash,expires_at) values(r.id,u.id,crypt(v_plain,gen_salt('bf')),v_exp) returning id into v_id;
 insert into integration_events(integration_type,entity_type,entity_id,direction,event_type,status,request_key,response_summary) values('whatsapp','salesman_referral_otp',v_id::text,'outbound','SALESMAN_REFERRAL_OTP','pending','salesman-referral-otp:'||v_id::text,'TRUSTED WORKER MUST DELIVER OTP; OTP VALUE MUST NOT BE LOGGED OR RETURNED TO CLIENT');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'SALESMAN_REFERRAL_OTP_REQUESTED','customer_dealer_referral',r.id::text,jsonb_build_object('challenge_id',v_id,'expires_at',v_exp));
 return query select v_id,v_exp;
end$$;
revoke all on function salesman_start_referral_otp(text) from public,anon;grant execute on function salesman_start_referral_otp(text) to authenticated;

create or replace function salesman_verify_referral_otp(p_challenge_id uuid,p_otp text)
returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;c salesman_referral_otp_challenges%rowtype;r customer_dealer_referrals%rowtype;v uuid;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true and role='salesman';if not found then raise exception 'ACTIVE SALESMAN REQUIRED';end if;
 select * into c from salesman_referral_otp_challenges where id=p_challenge_id for update;
 if not found or c.salesman_user_id<>u.id or c.consumed_at is not null or c.verified_at is not null then raise exception 'OTP CHALLENGE NOT ACTIVE';end if;
 if c.expires_at<=now() then update salesman_referral_otp_challenges set consumed_at=now() where id=c.id;raise exception 'OTP EXPIRED';end if;
 if c.attempts>=5 then update salesman_referral_otp_challenges set consumed_at=now() where id=c.id;raise exception 'OTP ATTEMPT LIMIT REACHED';end if;
 update salesman_referral_otp_challenges set attempts=attempts+1 where id=c.id;
 if nullif(btrim(p_otp),'') is null or crypt(btrim(p_otp),c.otp_hash)<>c.otp_hash then raise exception 'INVALID OTP';end if;
 select * into r from customer_dealer_referrals where id=c.referral_id for update;if not found or r.dealer_id is null then raise exception 'REFERRAL NOT AVAILABLE';end if;
 if not exists(select 1 from dealer_salesman_mapping m where m.dealer_id=r.dealer_id and m.salesman_user_id=u.id and coalesce(m.active,true)=true) then raise exception 'SALESMAN NOT MAPPED TO REFERRAL DEALER';end if;
 update salesman_referral_otp_challenges set verified_at=now(),consumed_at=now() where id=c.id;
 insert into salesman_referral_verifications(referral_id,salesman_user_id,dealer_id,otp_challenge_id) values(r.id,u.id,r.dealer_id,c.id) on conflict(referral_id) do update set salesman_user_id=excluded.salesman_user_id,dealer_id=excluded.dealer_id,verified_at=now(),otp_challenge_id=excluded.otp_challenge_id returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'SALESMAN_REFERRAL_OTP_VERIFIED','customer_dealer_referral',r.id::text,jsonb_build_object('verification_id',v,'dealer_id',r.dealer_id));return v;
end$$;
revoke all on function salesman_verify_referral_otp(uuid,text) from public,anon;grant execute on function salesman_verify_referral_otp(uuid,text) to authenticated;

create or replace function salesman_my_referral_statement(p_from date default null,p_to date default null)
returns table(referral_id uuid,referral_code text,dealer_id uuid,dealer_name text,product_id uuid,product_name text,status text,created_at timestamptz,verified_at timestamptz,benefit_given_at timestamptz)
language sql security definer set search_path=public as $$
 select r.id,r.referral_code,r.dealer_id,d.shop_name,r.product_id,c.name,r.status,r.created_at,v.verified_at,r.benefit_given_at
 from salesman_referral_verifications v join app_users u on u.id=v.salesman_user_id join customer_dealer_referrals r on r.id=v.referral_id join dealers d on d.id=r.dealer_id join catalog_items c on c.id=r.product_id
 where u.auth_user_id=auth.uid() and u.active=true and u.role='salesman' and (p_from is null or r.created_at::date>=p_from) and (p_to is null or r.created_at::date<=p_to)
 order by r.created_at desc;
$$;
revoke all on function salesman_my_referral_statement(date,date) from public,anon;grant execute on function salesman_my_referral_statement(date,date) to authenticated;
