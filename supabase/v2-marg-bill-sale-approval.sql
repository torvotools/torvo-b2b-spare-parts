-- TORVO V2 MARG BILL APPROVAL -> SALE -> STOCK OUT -> DISPATCH
-- Owner-approved replacement for the old payment-before-fulfilment stage.
-- Install after Estimate, inventory, dispatch and audit foundations.
-- Payment is NOT a prerequisite. Stock posts exactly once when an authorized Marg bill is approved.

create table if not exists public.sale_bill_approvals(
 id uuid primary key default gen_random_uuid(),
 estimate_id uuid not null unique references public.sales_documents(id) on delete restrict,
 estimate_number text not null unique,
 marg_bill_number text not null unique,
 status text not null default 'approved' check(status in('approved','reversed')),
 approved_by uuid not null references public.app_users(id),
 approved_at timestamptz not null default now(),
 reversed_by uuid references public.app_users(id),
 reversed_at timestamptz,
 reversal_reason text,
 details jsonb not null default '{}'::jsonb
);
alter table public.sale_bill_approvals enable row level security;
revoke all on public.sale_bill_approvals from anon,authenticated;

create or replace function public.approve_marg_bill_sale(p_estimate uuid,p_marg_bill_number text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;e sales_documents%rowtype;bill text;estno text;sid uuid;ln record;q numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Owner/Admin/Accountant authorization required';end if;
 bill:=upper(btrim(coalesce(p_marg_bill_number,'')));
 if bill='' or length(bill)>80 then raise exception 'Valid Marg bill number required';end if;
 select * into e from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 if not exists(select 1 from sales_document_lines where document_id=e.id) then raise exception 'Estimate has no items';end if;
 select id into sid from sale_bill_approvals where estimate_id=e.id;
 if sid is not null then raise exception 'Estimate already posted as Sale';end if;
 if exists(select 1 from sale_bill_approvals where marg_bill_number=bill) then raise exception 'Marg bill number already used';end if;
 estno:='EST-'||upper(substr(replace(e.id::text,'-',''),1,12));
 for ln in select item_id,sum(qty) qty from sales_document_lines where document_id=e.id group by item_id order by item_id loop
  select current_qty into q from inventory where item_id=ln.item_id for update;
  if not found then raise exception 'Inventory row missing for item %',ln.item_id;end if;
  if q<ln.qty then raise exception 'Insufficient stock for item %',ln.item_id;end if;
 end loop;
 for ln in select item_id,sum(qty) qty from sales_document_lines where document_id=e.id group by item_id order by item_id loop
  update inventory set current_qty=current_qty-ln.qty,updated_at=now() where item_id=ln.item_id;
  insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by)
  values(ln.item_id,-ln.qty,'MARG BILL APPROVED SALE','estimate',e.id,a.id);
 end loop;
 insert into sale_bill_approvals(estimate_id,estimate_number,marg_bill_number,approved_by,details)
 values(e.id,estno,bill,a.id,jsonb_build_object('stock_deducted',true,'deduction_point','marg_bill_approval','final_payable',e.final_payable))
 returning id into sid;
 update sales_documents set status='sale_approved',locked_at=coalesce(locked_at,now()),lock_reason='MARG BILL APPROVED: '||bill where id=e.id;
 insert into dispatches(estimate_id,status,updated_by) values(e.id,'pick_list',a.id)
 on conflict(estimate_id) do update set updated_by=excluded.updated_by;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'MARG_BILL_SALE_APPROVED','estimate',e.id::text,jsonb_build_object('sale_bill_approval_id',sid,'estimate_number',estno,'marg_bill_number',bill,'stock_deducted_once',true,'dispatch_created',true));
 return sid;
end$$;
revoke all on function public.approve_marg_bill_sale(uuid,text) from public,anon;
grant execute on function public.approve_marg_bill_sale(uuid,text) to authenticated;

create or replace function public.get_marg_bill_sale_queue()
returns table(estimate_id uuid,estimate_number text,dealer_id uuid,final_payable numeric,marg_bill_number text,sale_status text,dispatch_status text,approved_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Staff authorization required';end if;
 return query select e.id,s.estimate_number,e.dealer_id,e.final_payable,s.marg_bill_number,s.status,d.status,s.approved_at
 from sale_bill_approvals s join sales_documents e on e.id=s.estimate_id
 left join dispatches d on d.estimate_id=e.id
 where s.status='approved' order by s.approved_at desc;
end$$;
revoke all on function public.get_marg_bill_sale_queue() from public,anon;
grant execute on function public.get_marg_bill_sale_queue() to authenticated;
