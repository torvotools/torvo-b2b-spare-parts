-- TORVO V2 DEALER PIN AUTH FOUNDATION
-- DEALER LOGIN IS SEPARATE FROM STAFF WHATSAPP OTP.
-- PIN IS NEVER STORED IN PLAINTEXT. APPLY TO STAGING FIRST.
create extension if not exists pgcrypto;

create table if not exists dealer_login_credentials(
 dealer_id uuid primary key references dealers(id) on delete cascade,
 pin_hash text,
 pin_set_at timestamptz,
 failed_attempts integer not null default 0 check(failed_attempts>=0),
 locked_until timestamptz,
 updated_at timestamptz not null default now()
);
alter table dealer_login_credentials enable row level security;

create table if not exists dealer_pin_recovery_challenges(
 id uuid primary key default gen_random_uuid(),
 dealer_id uuid not null references dealers(id) on delete cascade,
 verified_by text not null check(verified_by in('whatsapp_otp','admin_verified')),
 created_at timestamptz not null default now(),
 expires_at timestamptz not null,
 used_at timestamptz
);
alter table dealer_pin_recovery_challenges enable row level security;
create index if not exists idx_dealer_pin_recovery on dealer_pin_recovery_challenges(dealer_id,expires_at desc);

-- TRUSTED SERVER/ADMIN ONLY AFTER APPROVED DEALER IDENTITY OR VERIFIED RECOVERY CHALLENGE.
create or replace function dealer_set_pin(p_dealer_id uuid,p_pin text,p_recovery_challenge_id uuid default null)
returns void language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;c dealer_pin_recovery_challenges%rowtype;begin
 if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN_MUST_BE_4_DIGITS';end if;
 select * into d from dealers where id=p_dealer_id and status='approved';
 if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;
 if p_recovery_challenge_id is not null then
  select * into c from dealer_pin_recovery_challenges where id=p_recovery_challenge_id and dealer_id=d.id and used_at is null and expires_at>now() for update;
  if c.id is null then raise exception 'VERIFIED_RECOVERY_REQUIRED';end if;
  update dealer_pin_recovery_challenges set used_at=now() where id=c.id;
 end if;
 insert into dealer_login_credentials(dealer_id,pin_hash,pin_set_at,failed_attempts,locked_until,updated_at)
 values(d.id,crypt(p_pin,gen_salt('bf')),now(),0,null,now())
 on conflict(dealer_id) do update set pin_hash=excluded.pin_hash,pin_set_at=now(),failed_attempts=0,locked_until=null,updated_at=now();
end$$;

-- TRUSTED SERVER ONLY. RETURNS DEALER ID AFTER PIN VERIFICATION; DOES NOT CREATE A BROWSER AUTH IDENTITY.
create or replace function dealer_verify_pin(p_mobile text,p_pin text)
returns uuid language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;c dealer_login_credentials%rowtype;m text;begin
 m:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
 if length(m)<>10 or p_pin !~ '^[0-9]{4}$' then raise exception 'INVALID_LOGIN';end if;
 select * into d from dealers where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and status='approved' order by created_at desc limit 1;
 if d.id is null then raise exception 'INVALID_LOGIN';end if;
 select * into c from dealer_login_credentials where dealer_id=d.id for update;
 if c.dealer_id is null or c.pin_hash is null then raise exception 'PIN_SETUP_REQUIRED';end if;
 if c.locked_until is not null and c.locked_until>now() then raise exception 'LOGIN_TEMPORARILY_LOCKED';end if;
 if crypt(p_pin,c.pin_hash)<>c.pin_hash then
  update dealer_login_credentials set failed_attempts=failed_attempts+1,locked_until=case when failed_attempts+1>=5 then now()+interval '15 minutes' else null end,updated_at=now() where dealer_id=d.id;
  raise exception 'INVALID_LOGIN';
 end if;
 update dealer_login_credentials set failed_attempts=0,locked_until=null,updated_at=now() where dealer_id=d.id;
 return d.id;
end$$;

-- TRUSTED SERVER ONLY AFTER REAL WHATSAPP OTP/ADMIN VERIFICATION.
create or replace function dealer_create_recovery_challenge(p_dealer_id uuid,p_verified_by text,p_minutes integer default 10)
returns uuid language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;rid uuid;begin
 if p_verified_by not in('whatsapp_otp','admin_verified') then raise exception 'VERIFICATION_REQUIRED';end if;
 if p_minutes<5 or p_minutes>30 then raise exception 'EXPIRY_MUST_BE_5_TO_30_MINUTES';end if;
 select * into d from dealers where id=p_dealer_id and status='approved';if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;
 insert into dealer_pin_recovery_challenges(dealer_id,verified_by,expires_at) values(d.id,p_verified_by,now()+make_interval(mins=>p_minutes)) returning id into rid;return rid;
end$$;

revoke all on function dealer_set_pin(uuid,text,uuid) from public,anon,authenticated;
revoke all on function dealer_verify_pin(text,text) from public,anon,authenticated;
revoke all on function dealer_create_recovery_challenge(uuid,text,integer) from public,anon,authenticated;
-- These functions intentionally remain trusted-server only. A server worker must establish the real authenticated Dealer session after verification.
