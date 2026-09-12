-- TORVO V2 PAYMENT -> ACTUAL DELIVERY -> EXACTLY-ONCE STOCK DEDUCTION
-- Requires v2-schema.sql and sales/payment/dispatch foundation.
-- PICKED/PACKED/READY/ESTIMATE never deduct inventory.
-- Staging runtime verification required before production.

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.catalog_items(id) on delete restrict,
  movement_type text not null check(movement_type in('purchase_in','delivery_out','conversion_in','conversion_out','correction_in','correction_out')),
  qty numeric not null check(qty>0),
  reference_type text not null,
  reference_id uuid not null,
  request_key text not null unique,
  actor_id uuid references public.app_users(id),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_stock_movements_item_created on public.stock_movements(item_id,created_at desc);
create index if not exists idx_stock_movements_reference on public.stock_movements(reference_type,reference_id);
alter table public.stock_movements enable row level security;
revoke all on public.stock_movements from anon,authenticated;

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

-- Replace payment recorder so replaying the same request key cannot create another payment.
create or replace function public.record_payment(p_estimate uuid,p_status text,p_amount numeric,p_request_key text) returns uuid
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;pid uuid;f numeric;already numeric;existing payments%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 if p_status not in('cash','pending','received') or p_amount<=0 or nullif(trim(p_request_key),'') is null then raise exception 'Valid payment required';end if;
 select * into existing from payments where request_key=trim(p_request_key);
 if found then
   if existing.estimate_id=p_estimate and existing.status=p_status and existing.amount=p_amount then return existing.id; end if;
   raise exception 'Payment request key already used';
 end if;
 select final_payable into f from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 select coalesce(sum(amount),0) into already from payments where estimate_id=p_estimate and status in('cash','received');
 if p_status in('cash','received') and already+p_amount>f then raise exception 'Payment exceeds estimate payable';end if;
 insert into payments(estimate_id,status,amount,received_at,recorded_by,request_key) values(p_estimate,p_status,p_amount,case when p_status in('cash','received') then now() end,a.id,trim(p_request_key)) returning id into pid;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'INTERNAL_PAYMENT_NOTED','estimate',p_estimate::text,jsonb_build_object('payment_id',pid,'status',p_status,'amount',p_amount,'request_key',trim(p_request_key)));
 return pid;
end;$$;
revoke all on function public.record_payment(uuid,text,numeric,text) from public;
grant execute on function public.record_payment(uuid,text,numeric,text) to authenticated;

-- Actual delivery is the ONLY outbound sales stock-deduction point.
-- Full payment/cash must be satisfied first. A transaction + row locks make the operation atomic.
create or replace function public.finalize_actual_delivery(
  p_estimate uuid,
  p_request_key text,
  p_tracking_code text default null
) returns void
language plpgsql security definer set search_path=public as $$
declare
 a app_users%rowtype; d sales_documents%rowtype; paid numeric; disp_status text; ln record;
 existing delivery_stock_finalizations%rowtype; current_qty numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
 if nullif(trim(p_request_key),'') is null then raise exception 'Delivery request key required';end if;

 select * into existing from delivery_stock_finalizations where request_key=trim(p_request_key);
 if found then
   if existing.estimate_id=p_estimate then return; end if;
   raise exception 'Delivery request key already used';
 end if;
 select * into existing from delivery_stock_finalizations where estimate_id=p_estimate;
 if found then return; end if;

 select * into d from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 select coalesce(sum(amount),0) into paid from payments where estimate_id=p_estimate and status in('cash','received');
 if paid<d.final_payable then raise exception 'Required payment not received';end if;

 select status into disp_status from dispatches where estimate_id=p_estimate for update;
 if not found then raise exception 'Dispatch not found';end if;
 if disp_status not in('ready_for_dispatch','dispatched') then raise exception 'Order is not ready for actual delivery';end if;

 -- Lock and validate every inventory row before any deduction.
 for ln in select l.item_id,sum(l.qty) qty from sales_document_lines l where l.document_id=p_estimate group by l.item_id order by l.item_id loop
   select i.current_qty into current_qty from inventory i where i.item_id=ln.item_id for update;
   if not found then raise exception 'Inventory row missing for item %',ln.item_id;end if;
   if current_qty<ln.qty then raise exception 'Insufficient stock for item %',ln.item_id;end if;
 end loop;

 for ln in select l.item_id,sum(l.qty) qty from sales_document_lines l where l.document_id=p_estimate group by l.item_id order by l.item_id loop
   update inventory set current_qty=current_qty-ln.qty,updated_at=now() where item_id=ln.item_id;
   insert into stock_movements(item_id,movement_type,qty,reference_type,reference_id,request_key,actor_id,details)
   values(ln.item_id,'delivery_out',ln.qty,'estimate',p_estimate,trim(p_request_key)||':'||ln.item_id::text,a.id,jsonb_build_object('estimate_id',p_estimate));
 end loop;

 update dispatches set status='delivered',tracking_code=coalesce(nullif(trim(p_tracking_code),''),tracking_code),updated_by=a.id where estimate_id=p_estimate;
 update sales_documents set status='delivered' where id=p_estimate;
 insert into delivery_stock_finalizations(estimate_id,request_key,finalized_by,paid_amount_snapshot,payable_snapshot,tracking_code_snapshot,details)
 values(p_estimate,trim(p_request_key),a.id,paid,d.final_payable,nullif(trim(p_tracking_code),''),jsonb_build_object('stock_deducted',true,'deduction_point','actual_delivery'));
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'ACTUAL_DELIVERY_FINALIZED','estimate',p_estimate::text,jsonb_build_object('payment_received',paid,'payable',d.final_payable,'stock_deducted_once',true,'request_key',trim(p_request_key)));
end;$$;
revoke all on function public.finalize_actual_delivery(uuid,text,text) from public;
grant execute on function public.finalize_actual_delivery(uuid,text,text) to authenticated;

-- Defense-in-depth: client roles cannot directly manipulate inventory or finalization ledger.
revoke insert,update,delete on public.inventory from anon,authenticated;
