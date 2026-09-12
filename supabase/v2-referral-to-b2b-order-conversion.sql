-- TORVO V2 CUSTOMER REFERRAL -> EXISTING DEALER B2B SALES ORDER
-- FINAL MODEL: NO PARALLEL DEMAND/ORDER TABLE.
-- CUSTOMER -> DEALER REFERRAL -> DEALER NEEDS ITEM -> EXISTING sales_documents SALES ORDER.
-- Dealer A/B/C rate remains private and is resolved server-side. Customer retail price is never stored.
-- Run after v2-dealer-link.sql, v2-customer-dealer-referral-network.sql and core sales/inventory schema.

alter table sales_documents add column if not exists source_type text not null default 'standard' check(source_type in('standard','customer_referral'));
alter table sales_documents add column if not exists source_referral_id uuid references customer_dealer_referrals(id) on delete restrict;
create unique index if not exists uq_sales_document_referral_order on sales_documents(source_referral_id) where doc_type='sales_order' and source_type='customer_referral' and source_referral_id is not null;
create index if not exists idx_sales_documents_source_referral on sales_documents(source_referral_id) where source_referral_id is not null;

create table if not exists referral_business_events(
 id bigint generated always as identity primary key,referral_id uuid not null references customer_dealer_referrals(id) on delete restrict,
 dealer_id uuid references dealers(id) on delete restrict,event_type text not null check(event_type in('referral_verified','benefit_given','dealer_torvo_order_created','dealer_torvo_order_fulfilled')),
 sales_order_id uuid references sales_documents(id) on delete restrict,actor_user_id uuid references app_users(id) on delete set null,created_at timestamptz not null default now());
create index if not exists idx_referral_business_events_ref on referral_business_events(referral_id,created_at);

-- AVAILABLE is returned only from authoritative inventory.current_qty.
create or replace function dealer_referral_supply_status(p_referral_code text)
returns table(referral_id uuid,product_id uuid,product_name text,torvo_supply_status text,available_qty numeric)
language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_ref customer_dealer_referrals%rowtype;v_qty numeric;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role<>'dealer' or v_user.dealer_id is null then raise exception 'DEALER ACCESS REQUIRED';end if;
 perform 1 from dealers where id=v_user.dealer_id and status='approved';if not found then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 select * into v_ref from customer_dealer_referrals where referral_code=upper(btrim(p_referral_code));
 if v_ref.id is null or v_ref.dealer_id<>v_user.dealer_id or v_ref.status not in('verified_by_dealer','benefit_given') then raise exception 'VERIFIED DEALER REFERRAL REQUIRED';end if;
 select i.current_qty into v_qty from inventory i where i.item_id=v_ref.product_id;
 return query select v_ref.id,v_ref.product_id,c.name,case when coalesce(v_qty,0)>0 then 'AVAILABLE'::text else 'NOT CURRENTLY AVAILABLE'::text end,coalesce(v_qty,0) from catalog_items c where c.id=v_ref.product_id and c.active=true;
end$$;
revoke all on function dealer_referral_supply_status(text) from public;grant execute on function dealer_referral_supply_status(text) to authenticated;

-- Creates the real existing Sales Order directly; repeated submission returns the same referral order.
create or replace function dealer_order_referral_item(p_referral_code text,p_qty numeric default 1)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_ref customer_dealer_referrals%rowtype;v_rg text;v_rate numeric;v_order uuid;v_amount numeric;
begin
 if p_qty is null or p_qty<=0 then raise exception 'VALID QUANTITY REQUIRED';end if;
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role<>'dealer' or v_user.dealer_id is null then raise exception 'DEALER ACCESS REQUIRED';end if;
 select rate_group into v_rg from dealers where id=v_user.dealer_id and status='approved';if v_rg is null then raise exception 'APPROVED DEALER RATE GROUP REQUIRED';end if;
 select * into v_ref from customer_dealer_referrals where referral_code=upper(btrim(p_referral_code)) for update;
 if v_ref.id is null or v_ref.dealer_id<>v_user.dealer_id or v_ref.status not in('verified_by_dealer','benefit_given') then raise exception 'VERIFIED DEALER REFERRAL REQUIRED';end if;
 select id into v_order from sales_documents where source_type='customer_referral' and source_referral_id=v_ref.id and doc_type='sales_order' limit 1;if v_order is not null then return v_order;end if;
 perform 1 from catalog_items where id=v_ref.product_id and active=true;if not found then raise exception 'ITEM NOT AVAILABLE';end if;
 select selling_rate into v_rate from item_rates where item_id=v_ref.product_id and rate_group=v_rg and min_qty<=p_qty order by min_qty desc limit 1;if v_rate is null then raise exception 'DEALER RATE NOT AVAILABLE FOR THIS QUANTITY';end if;
 v_amount:=round(p_qty*v_rate,2);
 insert into sales_documents(dealer_id,doc_type,status,subtotal,final_payable,created_by,revision_no,dealer_modification_limit,dealer_modifications_used,source_type,source_referral_id) values(v_user.dealer_id,'sales_order','submitted',v_amount,v_amount,v_user.id,1,2,0,'customer_referral',v_ref.id) returning id into v_order;
 update sales_documents set root_order_id=v_order where id=v_order;
 insert into sales_document_lines(document_id,item_id,qty,rate,amount) values(v_order,v_ref.product_id,p_qty,v_rate,v_amount);
 insert into sales_order_revisions(sales_order_id,revision_no,changed_by,actor_role,change_reason,after_data) values(v_order,1,v_user.id,'dealer','CUSTOMER REFERRAL ORDER FROM TORVO',jsonb_build_object('referral_id',v_ref.id,'item_id',v_ref.product_id,'qty',p_qty,'subtotal',v_amount));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(v_user.id,'REFERRAL_PURCHASE_ORDER_SUBMITTED','sales_order',v_order::text,jsonb_build_object('dealer_id',v_user.dealer_id,'referral_id',v_ref.id,'subtotal',v_amount));
 insert into referral_business_events(referral_id,dealer_id,event_type,sales_order_id,actor_user_id) values(v_ref.id,v_user.dealer_id,'dealer_torvo_order_created',v_order,v_user.id);return v_order;
end$$;
revoke all on function dealer_order_referral_item(text,numeric) from public;grant execute on function dealer_order_referral_item(text,numeric) to authenticated;

alter table referral_business_events enable row level security;revoke all on referral_business_events from anon,authenticated;

-- Production install does NOT create referral_b2b_demands. If an earlier development DB executed that temporary bridge, retire it later only after dependency/data audit.
