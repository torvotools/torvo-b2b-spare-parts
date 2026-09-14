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

-- Stable public settings facade. Values are intentionally non-sensitive and sourced from Admin-managed settings.
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
  )
  select
    coalesce(nullif(w.setting_value->>'customer_number',''),'7027751533')::text,
    coalesce(nullif(w.setting_value->>'customer_number',''),'7027751533')::text,
    coalesce((f.setting_value->>'customer_referral')::boolean,true),
    coalesce((f.setting_value->>'repair_service')::boolean,true),
    coalesce((f.setting_value->>'customer_catalog')::boolean,true)
  from (select 1) q left join w on true left join f on true;
$$;
revoke all on function public_business_settings() from public;
grant execute on function public_business_settings() to anon,authenticated;
