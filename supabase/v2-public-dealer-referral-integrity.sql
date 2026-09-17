-- TORVO V2 PUBLIC DEALER REFERRAL INTEGRITY
-- Install after v2-customer-public-runtime-contract.sql and v2-public-lead-source.sql.
-- PUBLIC WEBSITE IS REFERRAL-ONLY: NO TORVO RETAIL PRICE/CHECKOUT/PAYMENT.

-- Canonical public locator. A Dealer is visible only when approved, opted into referrals,
-- profile-verified, product-sales capable and explicitly covers the requested PIN.
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
) language plpgsql security definer set search_path=public as $$
declare p text:=btrim(coalesce(p_pin_code,''));
begin
  if p !~ '^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED'; end if;
  return query
  select d.id,d.shop_name,coalesce(nullif(d.public_address,''),d.address),
         coalesce(nullif(d.public_pin_code,''),d.pin_code),d.map_url,d.latitude,d.longitude,
         d.product_sales_available,d.repair_service_available,d.authorized_service_center,
         case when d.authorized_service_center=true then d.authorized_service_note else null end,
         'EXACT_PIN'::text
  from dealers d
  where d.status='approved'
    and d.customer_referral_enabled=true
    and d.referral_profile_verified_at is not null
    and d.product_sales_available=true
    and coalesce(nullif(d.public_pin_code,''),d.pin_code)=p
    and (not coalesce(p_repair_only,false) or d.repair_service_available=true)
  order by d.shop_name
  limit greatest(1,least(coalesce(p_limit,12),50));
end$$;
revoke all on function public_find_torvo_dealers_expanded(text,boolean,integer) from public;
grant execute on function public_find_torvo_dealers_expanded(text,boolean,integer) to anon,authenticated;

-- Canonical profile projection. Never exposes Dealer rates, purchase cost, internal identity or private notes.
create or replace function public_dealer_profile(p_dealer_id uuid)
returns table(dealer_id uuid,shop_name text,address text,city text,district text,state text,pin_code text,mobile text,whatsapp text,map_url text,repair_service boolean)
language sql security definer set search_path=public as $$
  select d.id,d.shop_name,coalesce(nullif(d.public_address,''),d.address),d.city,d.district,d.state,
         coalesce(nullif(d.public_pin_code,''),d.pin_code),d.mobile,coalesce(nullif(d.whatsapp,''),d.mobile),
         d.map_url,d.repair_service_available
  from dealers d
  where d.id=p_dealer_id and d.status='approved' and d.customer_referral_enabled=true
    and d.referral_profile_verified_at is not null and d.product_sales_available=true
  limit 1
$$;
revoke all on function public_dealer_profile(uuid) from public;
grant execute on function public_dealer_profile(uuid) to anon,authenticated;

-- Replace public referral creation with a source-aware, dealer/PIN-bound contract.
drop function if exists public.public_create_customer_referral(text,text,text,uuid,uuid,boolean,text);
create or replace function public_create_customer_referral(
  p_full_name text,
  p_mobile text,
  p_pin_code text,
  p_product_id uuid,
  p_dealer_id uuid default null,
  p_marketing_opt_in boolean default false,
  p_lead_source text default 'WEBSITE'
) returns table(referral_id uuid,referral_code text,benefit_type text,benefit_value numeric,benefit_text text,expires_at timestamptz,enquiry_id uuid)
language plpgsql security definer set search_path=public as $$
declare
  m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
  p text:=btrim(coalesce(p_pin_code,''));
  src text:=upper(btrim(coalesce(p_lead_source,'WEBSITE')));
  c customer_contacts%rowtype;b referral_benefit_campaigns%rowtype;r customer_dealer_referrals%rowtype;
begin
  if length(btrim(coalesce(p_full_name,'')))<2 then raise exception 'CUSTOMER NAME REQUIRED'; end if;
  if length(m)<>10 then raise exception '10-DIGIT MOBILE / WHATSAPP REQUIRED'; end if;
  if p !~ '^[0-9]{6}$' then raise exception '6-DIGIT PIN CODE REQUIRED'; end if;
  if src not in('WEBSITE','FACEBOOK','INSTAGRAM','YOUTUBE','WHATSAPP','EMAIL') then src:='WEBSITE'; end if;
  if not exists(select 1 from catalog_items i where i.id=p_product_id and coalesce(i.active,true)=true) then raise exception 'ACTIVE PRODUCT REQUIRED'; end if;
  if p_dealer_id is null then raise exception 'SELECT VERIFIED DEALER REQUIRED'; end if;
  if not exists(select 1 from dealers d where d.id=p_dealer_id and d.status='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null and d.product_sales_available=true and coalesce(nullif(d.public_pin_code,''),d.pin_code)=p) then raise exception 'SELECTED DEALER DOES NOT HAVE VERIFIED COVERAGE FOR THIS PIN'; end if;

  insert into customer_contacts(full_name,mobile,whatsapp,pin_code,marketing_opt_in,marketing_opt_in_at,marketing_opt_in_source,marketing_opt_out_at,consent_updated_at,updated_at)
  values(upper(btrim(p_full_name)),m,m,p,p_marketing_opt_in,case when p_marketing_opt_in then now() end,src,case when not p_marketing_opt_in then now() end,now(),now())
  on conflict(mobile) do update set full_name=excluded.full_name,whatsapp=excluded.whatsapp,pin_code=excluded.pin_code,marketing_opt_in=excluded.marketing_opt_in,marketing_opt_in_at=case when excluded.marketing_opt_in then coalesce(customer_contacts.marketing_opt_in_at,now()) else null end,marketing_opt_in_source=src,marketing_opt_out_at=case when excluded.marketing_opt_in then null else now() end,consent_updated_at=now(),updated_at=now()
  returning * into c;
  insert into customer_marketing_consent_events(customer_id,opted_in,source) values(c.id,p_marketing_opt_in,src);

  select x.* into b from referral_benefit_campaigns x where x.active=true and (x.starts_at is null or x.starts_at<=now()) and (x.ends_at is null or x.ends_at>=now()) and (x.scope='all' or (x.scope='product' and x.product_id=p_product_id) or (x.scope='item_type' and x.item_type=(select i.item_type from catalog_items i where i.id=p_product_id))) order by case x.scope when 'product' then 1 when 'item_type' then 2 else 3 end,x.created_at desc limit 1;
  insert into customer_dealer_referrals(referral_code,customer_id,product_id,dealer_id,benefit_campaign_id,customer_pin_code,status,expires_at,dealer_selected_at)
  values('TRV-'||upper(substr(encode(gen_random_bytes(6),'hex'),1,10)),c.id,p_product_id,p_dealer_id,b.id,p,'dealer_selected',now()+interval '30 days',now()) returning * into r;
  return query select r.id,r.referral_code,b.benefit_type,b.benefit_value,b.benefit_text,r.expires_at,null::uuid;
end$$;
revoke all on function public_create_customer_referral(text,text,text,uuid,uuid,boolean,text) from public;
grant execute on function public_create_customer_referral(text,text,text,uuid,uuid,boolean,text) to anon,authenticated;
