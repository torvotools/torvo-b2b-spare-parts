-- TORVO V2 REFERRAL + REPAIR ROUTING EXTENSION
-- FINAL MODEL: PRODUCT PURCHASE AND REPAIR/SERVICE USE ONE CUSTOMER/DEALER NETWORK.
-- RUN AFTER v2-customer-dealer-referral-network.sql. STAGING REVIEW REQUIRED.

create table if not exists customer_service_requirements(
 id uuid primary key default gen_random_uuid(),customer_id uuid not null references customer_contacts(id) on delete restrict,
 intent text not null default 'repair_service' check(intent='repair_service'),brand text,model_number text,problem_description text not null,customer_pin_code text not null,
 status text not null default 'received' check(status in('received','dealers_offered','dealer_assigned','customer_referred','code_verified','benefit_given','closed','cancelled')),
 assigned_dealer_id uuid references dealers(id) on delete restrict,referral_id uuid references customer_dealer_referrals(id) on delete restrict,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index if not exists idx_service_requirements_status on customer_service_requirements(status,created_at desc);
create index if not exists idx_service_requirements_pin on customer_service_requirements(customer_pin_code,status);

create table if not exists customer_requirement_media(
 id uuid primary key default gen_random_uuid(),requirement_id uuid not null references customer_service_requirements(id) on delete cascade,
 media_type text not null check(media_type in('photo','video')),storage_path text not null unique,mime_type text not null,size_bytes bigint not null check(size_bytes>0),created_at timestamptz not null default now());
create index if not exists idx_requirement_media_requirement on customer_requirement_media(requirement_id,created_at);

create table if not exists customer_service_dealer_offers(
 id uuid primary key default gen_random_uuid(),requirement_id uuid not null references customer_service_requirements(id) on delete cascade,
 dealer_id uuid not null references dealers(id) on delete restrict,offered_by uuid not null references app_users(id),
 status text not null default 'offered' check(status in('offered','can_repair','need_more_details','cannot_repair','assigned','withdrawn')),
 dealer_note text,offered_at timestamptz not null default now(),responded_at timestamptz,assigned_at timestamptz,unique(requirement_id,dealer_id));
create index if not exists idx_service_offers_dealer on customer_service_dealer_offers(dealer_id,status,offered_at desc);

-- Temporary field leads are deliberately minimal. They are NOT approved Dealers and must be converted into the existing Dealer onboarding/master flow.
create table if not exists dealer_discovery_leads(
 id uuid primary key default gen_random_uuid(),shop_name text not null,contact_person text,mobile text not null,whatsapp text,pin_code text not null,area text,
 capability text not null default 'product_sales' check(capability in('product_sales','repair_service','both')),source text not null default 'salesman_field',submitted_by uuid not null references app_users(id),
 status text not null default 'new' check(status in('new','duplicate','verification_pending','converted','rejected')),converted_dealer_id uuid references dealers(id) on delete restrict,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create unique index if not exists uq_dealer_discovery_open_mobile on dealer_discovery_leads(mobile) where status in('new','verification_pending');

create or replace function public_find_torvo_dealers_expanded(p_pin_code text,p_repair_only boolean default false,p_limit integer default 12)
returns table(dealer_id uuid,shop_name text,address text,pin_code text,map_url text,latitude numeric,longitude numeric,product_sales_available boolean,repair_service_available boolean,authorized_service_center boolean,authorized_service_note text,match_type text)
language sql security definer set search_path=public as $$
 with eligible as(select d.*,coalesce(nullif(d.public_pin_code,''),d.pin_code) effective_pin from dealers d where d.status='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null and(not p_repair_only or d.repair_service_available=true)),
 ranked as(select e.*,case when e.effective_pin=btrim(p_pin_code) then 0 else 1 end match_rank from eligible e)
 select r.id,r.shop_name,coalesce(nullif(r.public_address,''),r.address),r.effective_pin,r.map_url,r.latitude,r.longitude,r.product_sales_available,r.repair_service_available,r.authorized_service_center,r.authorized_service_note,case when r.match_rank=0 then 'EXACT_PIN' else 'OTHER_AREA' end from ranked r order by r.match_rank,r.shop_name limit greatest(1,least(coalesce(p_limit,12),30));$$;
revoke all on function public_find_torvo_dealers_expanded(text,boolean,integer) from public;grant execute on function public_find_torvo_dealers_expanded(text,boolean,integer) to anon,authenticated;

-- Authoritative Dealer identity is app_users.dealer_id. Mobile fallback is intentionally removed.
create or replace function dealer_respond_service_offer(p_offer_id uuid,p_response text,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_dealer dealers%rowtype;v_offer customer_service_dealer_offers%rowtype;v_status text;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role<>'dealer' or v_user.dealer_id is null then raise exception 'DEALER ACCESS REQUIRED';end if;
 select * into v_dealer from dealers where id=v_user.dealer_id and status='approved' and repair_service_available=true;
 if v_dealer.id is null then raise exception 'APPROVED REPAIR DEALER LINK REQUIRED';end if;
 v_status:=case upper(btrim(p_response)) when 'YES' then 'can_repair' when 'NEED_MORE_DETAILS' then 'need_more_details' when 'NO' then 'cannot_repair' else null end;
 if v_status is null then raise exception 'INVALID RESPONSE';end if;
 select * into v_offer from customer_service_dealer_offers where id=p_offer_id and dealer_id=v_dealer.id for update;
 if v_offer.id is null then raise exception 'OFFER NOT FOUND';end if;if v_offer.status in('assigned','withdrawn') then raise exception 'OFFER IS CLOSED';end if;
 update customer_service_dealer_offers set status=v_status,dealer_note=nullif(btrim(p_note),''),responded_at=coalesce(responded_at,now()) where id=v_offer.id;return v_offer.id;
end$$;
revoke all on function dealer_respond_service_offer(uuid,text,text) from public;grant execute on function dealer_respond_service_offer(uuid,text,text) to authenticated;

alter table customer_service_requirements enable row level security;alter table customer_requirement_media enable row level security;alter table customer_service_dealer_offers enable row level security;alter table dealer_discovery_leads enable row level security;
revoke all on customer_service_requirements,customer_requirement_media,customer_service_dealer_offers,dealer_discovery_leads from anon,authenticated;
