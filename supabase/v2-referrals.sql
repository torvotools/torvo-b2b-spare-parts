-- TORVO V2 referral program foundation.
create table if not exists referral_rules(
 id uuid primary key default gen_random_uuid(),
 name text not null,
 reward_points numeric not null default 0 check(reward_points>=0),
 min_delivered_sales numeric not null default 0 check(min_delivered_sales>=0),
 active boolean not null default true,
 created_by uuid references app_users(id),
 created_at timestamptz not null default now()
);
create table if not exists dealer_referrals(
 id uuid primary key default gen_random_uuid(),
 referrer_dealer_id uuid not null references dealers(id),
 referred_dealer_id uuid not null references dealers(id),
 rule_id uuid not null references referral_rules(id),
 status text not null default 'pending' check(status in('pending','qualified','rewarded','rejected')),
 qualified_at timestamptz,
 rewarded_at timestamptz,
 created_by uuid references app_users(id),
 created_at timestamptz not null default now(),
 check(referrer_dealer_id<>referred_dealer_id),
 unique(referred_dealer_id)
);
create index if not exists idx_referrals_referrer on dealer_referrals(referrer_dealer_id,status);
alter table referral_rules enable row level security;alter table dealer_referrals enable row level security;
drop policy if exists referral_rules_read on referral_rules;create policy referral_rules_read on referral_rules for select to authenticated using(current_app_role() in('owner','admin') or(current_app_role()='dealer' and active=true));
drop policy if exists dealer_referrals_read on dealer_referrals;create policy dealer_referrals_read on dealer_referrals for select to authenticated using(current_app_role() in('owner','admin') or referrer_dealer_id=current_dealer_id() or referred_dealer_id=current_dealer_id());

create or replace function create_referral_rule(p_name text,p_reward_points numeric,p_min_delivered_sales numeric default 0)
returns uuid language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;v uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 if nullif(trim(p_name),'') is null or p_reward_points<0 or p_min_delivered_sales<0 then raise exception 'Invalid referral rule';end if;
 insert into referral_rules(name,reward_points,min_delivered_sales,created_by) values(trim(p_name),p_reward_points,p_min_delivered_sales,a.id) returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REFERRAL_RULE_CREATED','referral_rule',v::text,jsonb_build_object('name',trim(p_name),'reward_points',p_reward_points,'min_delivered_sales',p_min_delivered_sales));return v;end;$$;
revoke all on function create_referral_rule(text,numeric,numeric) from public,anon;grant execute on function create_referral_rule(text,numeric,numeric) to authenticated;

create or replace function create_dealer_referral(p_referrer uuid,p_referred uuid,p_rule uuid)
returns uuid language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;v uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 if p_referrer=p_referred then raise exception 'Dealer cannot refer itself';end if;
 if not exists(select 1 from dealers where id=p_referrer and status='approved') or not exists(select 1 from dealers where id=p_referred and status='approved') then raise exception 'Both dealers must be approved';end if;
 if not exists(select 1 from referral_rules where id=p_rule and active=true) then raise exception 'Active referral rule required';end if;
 insert into dealer_referrals(referrer_dealer_id,referred_dealer_id,rule_id,created_by) values(p_referrer,p_referred,p_rule,a.id) returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_REFERRAL_CREATED','dealer_referral',v::text,jsonb_build_object('referrer',p_referrer,'referred',p_referred,'rule_id',p_rule));return v;
exception when unique_violation then raise exception 'Referred dealer already has a referral record';end;$$;
revoke all on function create_dealer_referral(uuid,uuid,uuid) from public,anon;grant execute on function create_dealer_referral(uuid,uuid,uuid) to authenticated;

create or replace function evaluate_dealer_referral(p_referral uuid)
returns text language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;r dealer_referrals%rowtype;rule referral_rules%rowtype;v_sales numeric:=0;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 select * into r from dealer_referrals where id=p_referral for update;if not found then raise exception 'Referral not found';end if;if r.status in('rewarded','rejected') then return r.status;end if;
 select * into rule from referral_rules where id=r.rule_id;if not found or rule.active=false then raise exception 'Referral rule inactive';end if;
 select coalesce(sum(e.final_payable),0) into v_sales from sales_documents e join dispatches d on d.estimate_id=e.id where e.doc_type='estimate' and e.dealer_id=r.referred_dealer_id and d.status='delivered';
 if v_sales<rule.min_delivered_sales then return 'pending';end if;
 update dealer_referrals set status='qualified',qualified_at=coalesce(qualified_at,now()) where id=r.id;
 if rule.reward_points>0 then
   begin insert into reward_ledger(dealer_id,points,reason,entry_type,source_type,source_id,created_by) values(r.referrer_dealer_id,rule.reward_points,'Referral reward','earn','dealer_referral',r.id::text,a.id);exception when unique_violation then null;end;
 end if;
 update dealer_referrals set status='rewarded',rewarded_at=coalesce(rewarded_at,now()) where id=r.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REFERRAL_REWARDED','dealer_referral',r.id::text,jsonb_build_object('referrer',r.referrer_dealer_id,'referred',r.referred_dealer_id,'delivered_sales',v_sales,'reward_points',rule.reward_points));return 'rewarded';end;$$;
revoke all on function evaluate_dealer_referral(uuid) from public,anon;grant execute on function evaluate_dealer_referral(uuid) to authenticated;
