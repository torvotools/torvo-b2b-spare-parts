-- TORVO V2 MARG BILL APPROVAL -> SALE -> STOCK OUT -> DISPATCH
-- Owner-approved replacement for Payment-gated outbound sale posting.
-- STAGING ONLY until genuine transaction acceptance. Production requires Owner approval.
-- Internal legacy sales_order names remain compatibility identifiers; user-facing terminology is QUOTATION.

create table if not exists public.marg_bill_sales(
  id uuid primary key default gen_random_uuid(),
  estimate_id uuid not null unique references public.sales_documents(id) on delete restrict,
  marg_bill_no text not null,
  approved_by uuid not null references public.app_users(id),
  approved_at timestamptz not null default now(),
  estimate_total_snapshot numeric not null check(estimate_total_snapshot>=0),
  status text not null default 'posted' check(status in('posted','corrected','reversed')),
  correction_of uuid references public.marg_bill_sales(id) on delete restrict,
  correction_reason text,
  created_at timestamptz not null default now()
);
create unique index if not exists uq_marg_bill_sales_bill_no on public.marg_bill_sales(upper(btrim(marg_bill_no)));
alter table public.marg_bill_sales enable row level security;
revoke all on public.marg_bill_sales from anon,authenticated;

create or replace function public.approve_marg_bill_sale(p_estimate uuid,p_marg_bill_no text)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 a public.app_users%rowtype;e public.sales_documents%rowtype;ln record;
 bill text;sid uuid;stock numeric;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'OWNER / ADMIN / ACCOUNTANT AUTHORIZATION REQUIRED';end if;
 bill:=upper(btrim(coalesce(p_marg_bill_no,'')));
 if bill='' or length(bill)>80 then raise exception 'VALID MARG BILL NUMBER REQUIRED';end if;

 select * into e from public.sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'ESTIMATE NOT FOUND';end if;
 if e.status in('delivered') then raise exception 'DELIVERED ESTIMATE CANNOT BE POSTED AS A NEW SALE';end if;
 if exists(select 1 from public.marg_bill_sales where estimate_id=e.id) then raise exception 'ESTIMATE ALREADY POSTED AS SALE';end if;
 if exists(select 1 from public.marg_bill_sales where upper(btrim(marg_bill_no))=bill) then raise exception 'MARG BILL NUMBER ALREADY USED';end if;
 if not exists(select 1 from public.sales_document_lines where document_id=e.id) then raise exception 'ESTIMATE HAS NO ITEMS';end if;

 -- Serialize inventory rows in deterministic item order and validate all stock before any deduction.
 for ln in select item_id,sum(qty) qty from public.sales_document_lines where document_id=e.id group by item_id order by item_id loop
   select current_qty into stock from public.inventory where item_id=ln.item_id for update;
   if not found then raise exception 'INVENTORY ROW MISSING FOR ITEM %',ln.item_id;end if;
   if stock<ln.qty then raise exception 'INSUFFICIENT STOCK FOR ITEM %',ln.item_id;end if;
 end loop;

 insert into public.marg_bill_sales(estimate_id,marg_bill_no,approved_by,estimate_total_snapshot)
 values(e.id,bill,a.id,e.final_payable) returning id into sid;

 for ln in select item_id,sum(qty) qty from public.sales_document_lines where document_id=e.id group by item_id order by item_id loop
   update public.inventory set current_qty=current_qty-ln.qty,updated_at=now() where item_id=ln.item_id;
   insert into public.inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by)
   values(ln.item_id,-ln.qty,'MARG BILL APPROVED SALE','marg_bill_sale',sid,a.id);
 end loop;

 insert into public.dispatches(estimate_id,status,updated_by)
 values(e.id,'pick_list',a.id)
 on conflict(estimate_id) do update set
   status=case when public.dispatches.status='delivered' then public.dispatches.status else 'pick_list' end,
   updated_by=excluded.updated_by;

 update public.sales_documents set status='sale_posted' where id=e.id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'MARG_BILL_SALE_POSTED','estimate',e.id::text,
   jsonb_build_object('sale_id',sid,'marg_bill_no',bill,'stock_deducted',true,'dispatch_created',true,'payment_gate',false));
 return sid;
end;$$;

revoke all on function public.approve_marg_bill_sale(uuid,text) from public,anon;
grant execute on function public.approve_marg_bill_sale(uuid,text) to authenticated;

comment on function public.approve_marg_bill_sale(uuid,text) is
'TORVO V2 atomic Marg Bill approval boundary. Validates unique bill + stock, posts Sale, deducts stock exactly in the same transaction and creates Dispatch pick-list.';

-- Legacy actual-delivery stock deduction must not double-deduct a Marg-posted Sale.
create or replace function public.assert_sale_stock_not_already_posted(p_estimate uuid)
returns void language plpgsql stable security definer set search_path=public as $$
begin
 if exists(select 1 from public.marg_bill_sales where estimate_id=p_estimate and status in('posted','corrected')) then
   raise exception 'STOCK ALREADY DEDUCTED AT MARG BILL SALE POSTING';
 end if;
end;$$;
revoke all on function public.assert_sale_stock_not_already_posted(uuid) from public,anon,authenticated;
