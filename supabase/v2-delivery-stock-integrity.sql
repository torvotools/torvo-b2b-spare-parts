-- TORVO V2 PAYMENT -> ACTUAL DELIVERY -> EXACTLY-ONCE STOCK DEDUCTION
-- Requires v2-schema.sql, v2-payment-idempotency.sql, v2-delivery-rpc.sql and inventory_movements foundation.
-- ESTIMATE / PICKED / PACKED / READY never deduct inventory.
-- This migration becomes the final outbound-sales stock definition.
-- STAGING RUNTIME VERIFICATION REQUIRED BEFORE PRODUCTION.

alter table public.payments add column if not exists request_key text;
create unique index if not exists idx_payments_request_key_uq on public.payments(request_key) where request_key is not null;

-- One durable finalization marker per Estimate. This is the exactly-once boundary.
create table if not exists public.delivery_stock_finalizations (
  estimate_id uuid primary key references public.sales_documents(id) on delete restrict,
  request_key text not null unique,
  finalized_by uuid not null references public.app_users(id),
  finalized_at timestamptz not null default now(),
  paid_amount_snapshot numeric not null,
  payable_snapshot numeric not null,
  tracking_code_snapshot text,
  details jsonb not null default '{}'::jsonb
);
alter table public.delivery_stock_finalizations enable row level security;
revoke all on public.delivery_stock_finalizations from anon,authenticated;

-- Canonical stock history is inventory_movements, shared by Purchase Entry, corrections and Delivery.
-- Do not maintain a second parallel sales stock ledger.

create or replace function public.record_payment(p_estimate uuid,p_status text,p_amount numeric,p_request_key text) returns uuid
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;pid uuid;f numeric;already numeric;existing payments%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 if p_status not in('cash','pending','received') or p_amount is null or p_amount<=0 or nullif(trim(p_request_key),'') is null then raise exception 'Valid payment required';end if;
 select * into existing from payments where request_key=trim(p_request_key);
 if found then
   if existing.estimate_id=p_estimate and existing.status=p_status and existing.amount=p_amount then return existing.id;end if;
   raise exception 'Payment request key already used';
 end if;
 select final_payable into f from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 select coalesce(sum(amount),0) into already from payments where estimate_id=p_estimate and status in('cash','received');
 if p_status in('cash','received') and already+p_amount>f then raise exception 'Payment exceeds estimate payable';end if;
 insert into payments(estimate_id,status,amount,received_at,recorded_by,request_key)
 values(p_estimate,p_status,p_amount,case when p_status in('cash','received') then now() end,a.id,trim(p_request_key)) returning id into pid;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'INTERNAL_PAYMENT_NOTED','estimate',p_estimate::text,jsonb_build_object('payment_id',pid,'status',p_status,'amount',p_amount,'request_key',trim(p_request_key)));
 return pid;
end;$$;
revoke all on function public.record_payment(uuid,text,numeric,text) from public,anon;
grant execute on function public.record_payment(uuid,text,numeric,text) to authenticated;

create or replace function public.finalize_actual_delivery(p_estimate uuid,p_request_key text,p_tracking_code text default null) returns void
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d sales_documents%rowtype;paid numeric;disp dispatches%rowtype;ln record;existing delivery_stock_finalizations%rowtype;current_stock numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
 if nullif(trim(p_request_key),'') is null then raise exception 'Delivery request key required';end if;

 select * into existing from delivery_stock_finalizations where request_key=trim(p_request_key);
 if found then
   if existing.estimate_id=p_estimate then return;end if;
   raise exception 'Delivery request key already used';
 end if;
 select * into existing from delivery_stock_finalizations where estimate_id=p_estimate;
 if found then raise exception 'Actual delivery already finalized';end if;

 select * into d from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 select coalesce(sum(amount),0) into paid from payments where estimate_id=p_estimate and status in('cash','received');
 if paid<d.final_payable then raise exception 'Full required payment not received';end if;
 select * into disp from dispatches where estimate_id=p_estimate for update;
 if not found then raise exception 'Dispatch not found';end if;
 if disp.status not in('ready_for_dispatch','dispatched') then raise exception 'Order is not ready for actual delivery';end if;
 if not exists(select 1 from sales_document_lines where document_id=p_estimate) then raise exception 'Estimate has no items';end if;

 for ln in select item_id,sum(qty) qty from sales_document_lines where document_id=p_estimate group by item_id order by item_id loop
   select current_qty into current_stock from inventory where item_id=ln.item_id for update;
   if not found then raise exception 'Inventory row missing for item %',ln.item_id;end if;
   if current_stock<ln.qty then raise exception 'Insufficient stock for item %',ln.item_id;end if;
 end loop;

 for ln in select item_id,sum(qty) qty from sales_document_lines where document_id=p_estimate group by item_id order by item_id loop
   update inventory set current_qty=current_qty-ln.qty,updated_at=now() where item_id=ln.item_id;
   insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by)
   values(ln.item_id,-ln.qty,'ACTUAL DELIVERY','estimate',p_estimate,a.id);
 end loop;

 update dispatches set status='delivered',tracking_code=coalesce(nullif(trim(p_tracking_code),''),tracking_code),delivered_at=coalesce(delivered_at,now()),stock_deducted_at=coalesce(stock_deducted_at,now()),updated_by=a.id where id=disp.id;
 update sales_documents set status='delivered' where id=p_estimate;
 insert into delivery_stock_finalizations(estimate_id,request_key,finalized_by,paid_amount_snapshot,payable_snapshot,tracking_code_snapshot,details)
 values(p_estimate,trim(p_request_key),a.id,paid,d.final_payable,coalesce(nullif(trim(p_tracking_code),''),disp.tracking_code),jsonb_build_object('stock_deducted',true,'deduction_point','actual_delivery','canonical_ledger','inventory_movements'));
 perform recalculate_dealer_scheme_progress(d.dealer_id);
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'ACTUAL_DELIVERY_FINALIZED','estimate',p_estimate::text,jsonb_build_object('payment_received',paid,'payable',d.final_payable,'stock_deducted_once',true,'request_key',trim(p_request_key),'scheme_progress_refreshed',true));
end;$$;
revoke all on function public.finalize_actual_delivery(uuid,text,text) from public,anon;
grant execute on function public.finalize_actual_delivery(uuid,text,text) to authenticated;

-- Legacy delivery function remains as a compatibility wrapper only; it cannot implement another stock-deduction path.
create or replace function public.deliver_estimate(p_estimate uuid) returns void
language plpgsql security definer set search_path=public as $$
begin
 perform public.finalize_actual_delivery(p_estimate,'LEGACY-DELIVERY-'||p_estimate::text,null);
end;$$;
revoke all on function public.deliver_estimate(uuid) from public,anon;
grant execute on function public.deliver_estimate(uuid) to authenticated;

-- Defense in depth: authenticated browser code cannot bypass the controlled stock RPCs.
revoke insert,update,delete on public.inventory from anon,authenticated;
revoke insert,update,delete on public.inventory_movements from anon,authenticated;
