-- TORVO V2 PUBLIC CUSTOMER RUNTIME CONTRACT
-- Runtime-compatible public dealer locator/referral/repair/settings RPCs used by CustomerApp.
-- Install after v2-customer-dealer-referral-network.sql, v2-customer-marketing-consent-segmentation.sql and v2-admin-managed-experience.sql.
-- PUBLIC CUSTOMER HAS NO TORVO SELLING PRICE/CHECKOUT/PAYMENT.

create table if not exists customer_repair_requirements(
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customer_contacts(id) on delete restrict,
  pin_code text not null check(pin_code ~ '^[0-9]{6}$'),
  brand text,
  model_number text,
  problem_description text not null,
  status text not null default 'submitted' check(status in('submitted','routed','accepted','closed','cancelled')),
  routed_dealer_id uuid references dealers(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table customer_repair_requirements enable row level security;
revoke all on customer_repair_requirements from anon,authenticated;
create index if not exists customer_repair_requirements_pin_status_idx on customer_repair_requirements(pin_code,status,created_at desc);

create or replace function public_find_torvo_dealers_expanded(
  p_pin_code text,
  p_repair_only boolean default false,
  p_limit integer default 12
) returns table(
  dealer_id uuid,
  shop_name text,
  address text,
  pin_code text,
  map_url text,
  latitude numeric,
  longitude numeric,
  product_sales_available boolean,
  repair_service_available boolean,
  authorized_service_center boolean,
  authorized_service_note text,
  match_type text
) language sql security definer set search_path=public as $$
  select d.id,
         d.shop_name,
         coalesce(nullif(d.public_address,''),d.address),
         coalesce(nullif(d.public_pin_code,''),d.pin_code),
         d.map_url,d.latitude,d.longitude,
         d.product_sales_available,d.repair_service_available,
         d.authorized_service_center,d.authorized_service_note,
         'EXACT_PIN'::text
  from dealers d
  where d.status='approved'
    and d.customer_referral_enabled=true
    and d.referral_profile_verified_at is not null
    and coalesce(nullif(d.public_pin_code,''),d.pin_code)=btrim(p_pin_code)
    and (not coalesce(p_repair_only,false) or d.repair_service_available=true)
  order by d.shop_name
  limit greatest(1,least(coalesce(p_limit,12),50));
$$;
revoke all on function public_find_torvo_dealers_expanded(text,boolean,integer) from public;
grant execute on function public_find_torvo_dealers_expanded(text,boolean,integer) to anon,authenticated;

create or replace function public_create_customer_referral(
  p_full_name text,
  p_mobile text,
  p_pin_code text,
  p_product_id uuid,
  p_dealer_id uuid default null,
  p_marketing_opt_in boolean default false
) returns table(referral_id uuid,referral_code text,benefit_type text,benefit_value numeric,benefit_text text,expires_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare
  m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
  c customer_contacts%rowtype;
  b referral_benefit_campaigns%rowtype;
  r customer_dealer_referrals%rowtype;
begin
  if length(m)<>10 then raise exception '10-DIGIT MOBILE REQUIRED'; end if;
  if coalesce(p_pin_code,'')!~'^[0-9]{6}$' then raise exception '6-DIGIT PIN CODE REQUIRED'; end if;
  if nullif(btrim(p_full_name),'') is null then raise exception 'CUSTOMER NAME REQUIRED'; end if;
  if not exists(select 1 from catalog_items i where i.id=p_product_id and coalesce(i.active,true)=true) then raise exception 'ACTIVE PRODUCT REQUIRED'; end if;
  if p_dealer_id is not null and not exists(
    select 1 from dealers d where d.id=p_dealer_id and d.status='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null
  ) then raise exception 'APPROVED VERIFIED DEALER REQUIRED'; end if;

  insert into customer_contacts(full_name,mobile,whatsapp,pin_code,marketing_opt_in,marketing_opt_in_at,marketing_opt_in_source,marketing_opt_out_at,consent_updated_at,updated_at)
  values(upper(btrim(p_full_name)),m,m,btrim(p_pin_code),p_marketing_opt_in,case when p_marketing_opt_in then now() end,'PUBLIC WEBSITE',case when not p_marketing_opt_in then now() end,now(),now())
  on conflict(mobile) do update set
    full_name=excluded.full_name,whatsapp=excluded.whatsapp,pin_code=excluded.pin_code,
    marketing_opt_in=excluded.marketing_opt_in,
    marketing_opt_in_at=case when excluded.marketing_opt_in then coalesce(customer_contacts.marketing_opt_in_at,now()) else null end,
    marketing_opt_in_source='PUBLIC WEBSITE',
    marketing_opt_out_at=case when excluded.marketing_opt_in then null else now() end,
    consent_updated_at=now(),updated_at=now()
  returning * into c;
  insert into customer_marketing_consent_events(customer_id,opted_in,source)
  values(c.id,p_marketing_opt_in,'PUBLIC WEBSITE');

  select x.* into b from referral_benefit_campaigns x
  where x.active=true
    and (x.starts_at is null or x.starts_at<=now())
    and (x.ends_at is null or x.ends_at>=now())
    and (x.scope='all' or (x.scope='product' and x.product_id=p_product_id) or (x.scope='item_type' and x.item_type=(select i.item_type from catalog_items i where i.id=p_product_id)))
  order by case x.scope when 'product' then 1 when 'item_type' then 2 else 3 end,x.created_at desc limit 1;

  insert into customer_dealer_referrals(referral_code,customer_id,product_id,dealer_id,benefit_campaign_id,customer_pin_code,status,expires_at,dealer_selected_at)
  values('TRV-'||upper(substr(encode(gen_random_bytes(6),'hex'),1,10)),c.id,p_product_id,p_dealer_id,b.id,btrim(p_pin_code),case when p_dealer_id is null then 'created' else 'dealer_selected' end,now()+interval '30 days',case when p_dealer_id is null then null else now() end)
  returning * into r;

  return query select r.id,r.referral_code,b.benefit_type,b.benefit_value,b.benefit_text,r.expires_at;
end$$;
revoke all on function public_create_customer_referral(text,text,text,uuid,uuid,boolean) from public;
grant execute on function public_create_customer_referral(text,text,text,uuid,uuid,boolean) to anon,authenticated;

create or replace function public_create_repair_request(
  p_full_name text,
  p_mobile text,
  p_pin_code text,
  p_brand text default null,
  p_model_number text default null,
  p_problem_description text default null,
  p_marketing_opt_in boolean default false
) returns table(requirement_id uuid,status text)
language plpgsql security definer set search_path=public as $$
declare
  m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
  c customer_contacts%rowtype;
  rid uuid;
begin
  if length(m)<>10 then raise exception '10-DIGIT MOBILE REQUIRED'; end if;
  if coalesce(p_pin_code,'')!~'^[0-9]{6}$' then raise exception '6-DIGIT PIN CODE REQUIRED'; end if;
  if nullif(btrim(p_full_name),'') is null then raise exception 'CUSTOMER NAME REQUIRED'; end if;
  if length(btrim(coalesce(p_problem_description,'')))<5 then raise exception 'PROBLEM DESCRIPTION REQUIRED'; end if;

  insert into customer_contacts(full_name,mobile,whatsapp,pin_code,marketing_opt_in,marketing_opt_in_at,marketing_opt_in_source,marketing_opt_out_at,consent_updated_at,updated_at)
  values(upper(btrim(p_full_name)),m,m,btrim(p_pin_code),p_marketing_opt_in,case when p_marketing_opt_in then now() end,'PUBLIC REPAIR REQUEST',case when not p_marketing_opt_in then now() end,now(),now())
  on conflict(mobile) do update set
    full_name=excluded.full_name,whatsapp=excluded.whatsapp,pin_code=excluded.pin_code,
    marketing_opt_in=excluded.marketing_opt_in,
    marketing_opt_in_at=case when excluded.marketing_opt_in then coalesce(customer_contacts.marketing_opt_in_at,now()) else null end,
    marketing_opt_in_source='PUBLIC REPAIR REQUEST',
    marketing_opt_out_at=case when excluded.marketing_opt_in then null else now() end,
    consent_updated_at=now(),updated_at=now()
  returning * into c;
  insert into customer_marketing_consent_events(customer_id,opted_in,source)
  values(c.id,p_marketing_opt_in,'PUBLIC REPAIR REQUEST');

  insert into customer_repair_requirements(customer_id,pin_code,brand,model_number,problem_description)
  values(c.id,btrim(p_pin_code),upper(nullif(btrim(p_brand),'')),upper(nullif(btrim(p_model_number),'')),upper(btrim(p_problem_description)))
  returning id into rid;
  return query select rid,'submitted'::text;
end$$;
revoke all on function public_create_repair_request(text,text,text,text,text,text,boolean) from public;
grant execute on function public_create_repair_request(text,text,text,text,text,text,boolean) to anon,authenticated;

-- Owner/Admin repair inbox. Customer contact details stay behind authenticated privileged RPCs.
create or replace function admin_repair_requirements(p_status text default null,p_limit integer default 100)
returns table(requirement_id uuid,customer_name text,mobile text,pin_code text,brand text,model_number text,problem_description text,status text,routed_dealer_id uuid,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED'; end if;
  return query select r.id,c.full_name,c.mobile,r.pin_code,r.brand,r.model_number,r.problem_description,r.status,r.routed_dealer_id,r.created_at
  from customer_repair_requirements r join customer_contacts c on c.id=r.customer_id
  where p_status is null or r.status=lower(btrim(p_status)) order by r.created_at desc limit greatest(1,least(coalesce(p_limit,100),500));
end$$;

create or replace function admin_route_repair_requirement(p_requirement_id uuid,p_dealer_id uuid,p_reason text)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;r customer_repair_requirements%rowtype;
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED'; end if;
  if nullif(btrim(coalesce(p_reason,'')),'') is null then raise exception 'ROUTING REASON REQUIRED'; end if;
  select * into r from customer_repair_requirements where id=p_requirement_id for update;
  if r.id is null then raise exception 'REPAIR REQUIREMENT NOT FOUND'; end if;
  if r.status in('closed','cancelled') then raise exception 'CLOSED OR CANCELLED REQUIREMENT CANNOT BE ROUTED'; end if;
  if not exists(select 1 from dealers d where d.id=p_dealer_id and d.status='approved' and d.repair_service_available=true) then raise exception 'APPROVED REPAIR DEALER REQUIRED'; end if;
  update customer_repair_requirements set routed_dealer_id=p_dealer_id,status='routed',updated_at=now() where id=p_requirement_id;
  insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'REPAIR_REQUIREMENT_ROUTED','CUSTOMER_REPAIR_REQUIREMENT',p_requirement_id::text,jsonb_build_object('dealer_id',p_dealer_id,'reason',upper(btrim(p_reason))));
  return true;
end$$;
revoke all on function admin_repair_requirements(text,integer),admin_route_repair_requirement(uuid,uuid,text) from public,anon;
grant execute on function admin_repair_requirements(text,integer),admin_route_repair_requirement(uuid,uuid,text) to authenticated;

-- Dealer can only see and act on repair requests routed to their own approved dealer account.
create or replace function dealer_repair_requirements(p_status text default null,p_limit integer default 100)
returns table(requirement_id uuid,customer_name text,mobile text,pin_code text,brand text,model_number text,problem_description text,status text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;did uuid;
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role<>'dealer' then raise exception 'ACTIVE DEALER REQUIRED'; end if;
  select d.id into did from dealers d where d.app_user_id=u.id and d.status='approved' and d.repair_service_available=true limit 1;
  if did is null then raise exception 'APPROVED REPAIR DEALER REQUIRED'; end if;
  return query select r.id,c.full_name,c.mobile,r.pin_code,r.brand,r.model_number,r.problem_description,r.status,r.created_at
  from customer_repair_requirements r join customer_contacts c on c.id=r.customer_id
  where r.routed_dealer_id=did and (p_status is null or r.status=lower(btrim(p_status)))
  order by r.created_at desc limit greatest(1,least(coalesce(p_limit,100),500));
end$$;

create or replace function dealer_update_repair_requirement(p_requirement_id uuid,p_status text)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;did uuid;r customer_repair_requirements%rowtype;s text:=lower(btrim(coalesce(p_status,'')));
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role<>'dealer' then raise exception 'ACTIVE DEALER REQUIRED'; end if;
  select d.id into did from dealers d where d.app_user_id=u.id and d.status='approved' and d.repair_service_available=true limit 1;
  if did is null then raise exception 'APPROVED REPAIR DEALER REQUIRED'; end if;
  if s not in('accepted','closed') then raise exception 'DEALER STATUS MUST BE ACCEPTED OR CLOSED'; end if;
  select * into r from customer_repair_requirements where id=p_requirement_id and routed_dealer_id=did for update;
  if r.id is null then raise exception 'ROUTED REPAIR REQUIREMENT NOT FOUND'; end if;
  if r.status in('closed','cancelled') then raise exception 'REPAIR REQUIREMENT ALREADY FINAL'; end if;
  if s='closed' and r.status<>'accepted' then raise exception 'ACCEPT REPAIR REQUIREMENT BEFORE CLOSING'; end if;
  update customer_repair_requirements set status=s,updated_at=now() where id=p_requirement_id;
  insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,case when s='accepted' then 'REPAIR_REQUIREMENT_ACCEPTED' else 'REPAIR_REQUIREMENT_CLOSED' end,'CUSTOMER_REPAIR_REQUIREMENT',p_requirement_id::text,jsonb_build_object('dealer_id',did,'status',upper(s)));
  return true;
end$$;
revoke all on function dealer_repair_requirements(text,integer),dealer_update_repair_requirement(uuid,text) from public,anon;
grant execute on function dealer_repair_requirements(text,integer),dealer_update_repair_requirement(uuid,text) to authenticated;

-- Stable public settings facade. Values are intentionally non-sensitive and sourced from Admin-managed settings.
-- Customer/support and business WhatsApp channels stay independent so Admin can change either without a code deployment.
-- Legacy or manually-edited JSON must never make the public facade fail because PostgreSQL boolean casts reject malformed text.
create or replace function public_business_settings() returns table(
  support_mobile text,
  whatsapp_mobile text,
  referral_enabled boolean,
  repair_service_enabled boolean,
  customer_catalog_enabled boolean
) language sql security definer set search_path=public as $$
  with w as(
    select setting_value from admin_managed_settings
    where setting_key='whatsapp_channels' and public_read=true and active=true
  ), f as(
    select setting_value from admin_managed_settings
    where setting_key='feature_switches' and active=true
  ), safe as(
    select
      w.setting_value as wv,
      f.setting_value as fv,
      case lower(coalesce(w.setting_value->>'customer_active','true')) when 'true' then true when 'false' then false else true end as customer_active,
      case lower(coalesce(w.setting_value->>'business_active','true')) when 'true' then true when 'false' then false else true end as business_active,
      case lower(coalesce(f.setting_value->>'customer_referral','true')) when 'true' then true when 'false' then false else true end as customer_referral,
      case lower(coalesce(f.setting_value->>'repair_service','true')) when 'true' then true when 'false' then false else true end as repair_service,
      case lower(coalesce(f.setting_value->>'customer_catalog','true')) when 'true' then true when 'false' then false else true end as customer_catalog
    from (select 1) q left join w on true left join f on true
  )
  select
    case when customer_active then coalesce(nullif(wv->>'customer_number',''),'7027751533') else '7027751533' end::text,
    case when business_active then coalesce(nullif(wv->>'business_number',''),nullif(wv->>'customer_number',''),'7027751533') else coalesce(nullif(wv->>'customer_number',''),'7027751533') end::text,
    customer_referral,
    repair_service,
    customer_catalog
  from safe;
$$;
revoke all on function public_business_settings() from public;
grant execute on function public_business_settings() to anon,authenticated;
