-- TORVO V2 CUSTOMER REFERRAL -> DEALER B2B DEMAND CONVERSION
-- FINAL COMMERCIAL LOOP:
-- CUSTOMER DISCOVERS ITEM -> TORVO REFERS DEALER -> DEALER VERIFIES CODE ->
-- IF DEALER NEEDS THE ITEM, CREATE A LINKED TORVO B2B DEMAND/ORDER REQUEST.
-- Customer never sees Dealer A/B/C rate. Dealer base retail price is never stored here.
-- Run after v2-customer-dealer-referral-network.sql and the core sales/catalog schema.

-- A small bridge table is intentional: it links referral attribution to the existing B2B sales flow
-- without duplicating Sales Order/PO/accounting tables.
create table if not exists referral_b2b_demands(
 id uuid primary key default gen_random_uuid(),
 referral_id uuid not null references customer_dealer_referrals(id) on delete restrict,
 dealer_id uuid not null references dealers(id) on delete restrict,
 product_id uuid not null references catalog_items(id) on delete restrict,
 requested_qty numeric not null default 1 check(requested_qty>0),
 status text not null default 'requested' check(status in('requested','converted_to_order','fulfilled','cancelled')),
 sales_order_id uuid,
 created_by uuid not null references app_users(id),
 created_at timestamptz not null default now(),
 converted_at timestamptz,
 fulfilled_at timestamptz,
 unique(referral_id,dealer_id,product_id)
);
create index if not exists idx_referral_b2b_demands_dealer on referral_b2b_demands(dealer_id,status,created_at desc);
create index if not exists idx_referral_b2b_demands_referral on referral_b2b_demands(referral_id);

-- Audit the funnel without pretending the Customer's retail transaction is TORVO's transaction.
create table if not exists referral_business_events(
 id bigint generated always as identity primary key,
 referral_id uuid not null references customer_dealer_referrals(id) on delete restrict,
 dealer_id uuid references dealers(id) on delete restrict,
 event_type text not null check(event_type in('referral_verified','benefit_given','dealer_torvo_demand_created','dealer_torvo_order_linked','dealer_torvo_demand_fulfilled')),
 related_id uuid,
 actor_user_id uuid references app_users(id) on delete set null,
 created_at timestamptz not null default now()
);
create index if not exists idx_referral_business_events_ref on referral_business_events(referral_id,created_at);

-- Server-authoritative availability indicator for an authenticated Dealer.
-- It intentionally returns no public retail price. Quantity is based only on current stock data when available.
create or replace function dealer_referral_supply_status(p_referral_code text)
returns table(referral_id uuid,product_id uuid,product_name text,torvo_supply_status text,available_qty numeric)
language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_dealer dealers%rowtype;v_ref customer_dealer_referrals%rowtype;v_qty numeric:=null;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role<>'dealer' then raise exception 'DEALER ACCESS REQUIRED';end if;
 select d.* into v_dealer from dealers d where d.id=v_user.dealer_id and d.status='approved';
 if v_dealer.id is null then select d.* into v_dealer from dealers d where d.mobile=v_user.mobile and d.status='approved';end if;
 if v_dealer.id is null then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 select * into v_ref from customer_dealer_referrals where referral_code=upper(btrim(p_referral_code));
 if v_ref.id is null or v_ref.dealer_id<>v_dealer.id or v_ref.status not in('verified_by_dealer','benefit_given') then raise exception 'VERIFIED DEALER REFERRAL REQUIRED';end if;
 -- Inventory table names differ across earlier V2 modules; do not invent stock. Until an authoritative stock view is installed, status is CHECK LIVE STOCK.
 return query select v_ref.id,v_ref.product_id,c.name,'CHECK LIVE STOCK'::text,v_qty from catalog_items c where c.id=v_ref.product_id;
end$$;
revoke all on function dealer_referral_supply_status(text) from public;
grant execute on function dealer_referral_supply_status(text) to authenticated;

-- Dealer expresses demand for the referred Customer's item. This does not create a fake completed Sales Order.
-- The existing authorized Sales Order service converts this bridge row after applying Dealer rate, stock and approval rules.
create or replace function dealer_create_referral_b2b_demand(p_referral_code text,p_qty numeric default 1)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_dealer dealers%rowtype;v_ref customer_dealer_referrals%rowtype;v_id uuid;
begin
 if p_qty is null or p_qty<=0 then raise exception 'VALID QUANTITY REQUIRED';end if;
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role<>'dealer' then raise exception 'DEALER ACCESS REQUIRED';end if;
 select d.* into v_dealer from dealers d where d.id=v_user.dealer_id and d.status='approved';
 if v_dealer.id is null then select d.* into v_dealer from dealers d where d.mobile=v_user.mobile and d.status='approved';end if;
 if v_dealer.id is null then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 select * into v_ref from customer_dealer_referrals where referral_code=upper(btrim(p_referral_code)) for update;
 if v_ref.id is null or v_ref.dealer_id<>v_dealer.id or v_ref.status not in('verified_by_dealer','benefit_given') then raise exception 'VERIFIED DEALER REFERRAL REQUIRED';end if;
 insert into referral_b2b_demands(referral_id,dealer_id,product_id,requested_qty,created_by)
 values(v_ref.id,v_dealer.id,v_ref.product_id,p_qty,v_user.id)
 on conflict(referral_id,dealer_id,product_id) do update set requested_qty=excluded.requested_qty
 returning id into v_id;
 insert into referral_business_events(referral_id,dealer_id,event_type,related_id,actor_user_id)
 values(v_ref.id,v_dealer.id,'dealer_torvo_demand_created',v_id,v_user.id);
 return v_id;
end$$;
revoke all on function dealer_create_referral_b2b_demand(text,numeric) from public;
grant execute on function dealer_create_referral_b2b_demand(text,numeric) to authenticated;

alter table referral_b2b_demands enable row level security;
alter table referral_business_events enable row level security;
revoke all on referral_b2b_demands,referral_business_events from anon,authenticated;
