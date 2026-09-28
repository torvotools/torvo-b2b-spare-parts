-- TORVO V2 MARG BILL APPROVAL -> SALE -> STOCK OUT -> DISPATCH
-- Owner-approved replacement for Payment-gated outbound sale posting.
-- STAGING ONLY until genuine transaction acceptance. Production requires Owner approval.
-- Internal legacy sales_order names remain compatibility identifiers; user-facing terminology is QUOTATION.

create sequence if not exists public.torvo_estimate_number_seq start 1;
alter table public.sales_documents add column if not exists estimate_number text;
create unique index if not exists uq_sales_documents_estimate_number on public.sales_documents(estimate_number) where estimate_number is not null;
create or replace function public.torvo_assign_estimate_number() returns trigger language plpgsql set search_path=public as $begin if new.doc_type='estimate' and new.estimate_number is null then new.estimate_number:='EST-'||to_char(current_date,'YYYY')||'-'||lpad(nextval('public.torvo_estimate_number_seq')::text,6,'0');end if;return new;end$;
drop trigger if exists trg_torvo_assign_estimate_number on public.sales_documents;
create trigger trg_torvo_assign_estimate_number before insert on public.sales_documents for each row execute function public.torvo_assign_estimate_number();
update public.sales_documents set estimate_number='EST-'||to_char(created_at,'YYYY')||'-LEGACY-'||upper(substr(replace(id::text,'-',''),1,8)) where doc_type='estimate' and estimate_number is null;


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

create or replace function public.approve_marg_bill_sale(p_estimate_number text,p_marg_bill_no text)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 a public.app_users%rowtype;e public.sales_documents%rowtype;ln record;
 bill text;sid uuid;stock numeric;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'OWNER / ADMIN / ACCOUNTANT AUTHORIZATION REQUIRED';end if;
 bill:=upper(btrim(coalesce(p_marg_bill_no,'')));
 if bill='' or length(bill)>80 then raise exception 'VALID MARG BILL NUMBER REQUIRED';end if;

 if nullif(upper(btrim(coalesce(p_estimate_number,''))),'') is null then raise exception 'ESTIMATE NUMBER REQUIRED';end if;
 select * into e from public.sales_documents where estimate_number=upper(btrim(p_estimate_number)) and doc_type='estimate' for update;
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

revoke all on function public.approve_marg_bill_sale(text,text) from public,anon;
grant execute on function public.approve_marg_bill_sale(text,text) to authenticated;

comment on function public.approve_marg_bill_sale(text,text) is
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

-- Final delivery compatibility wrapper for the new Sale-posting model.
-- Marg-posted Sales have already reduced stock, so delivery only closes Dispatch/Estimate.
-- Legacy non-Marg transactions retain the old finalization path until historical cutover is complete.
create or replace function public.finalize_actual_delivery(p_estimate uuid,p_request_key text,p_tracking_code text default null)
returns void language plpgsql security definer set search_path=public as $$
declare a public.app_users%rowtype;d public.sales_documents%rowtype;disp public.dispatches%rowtype;s public.marg_bill_sales%rowtype;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'NOT AUTHORIZED';end if;
 if nullif(btrim(coalesce(p_request_key,'')),'') is null then raise exception 'DELIVERY REQUEST KEY REQUIRED';end if;
 select * into d from public.sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'ESTIMATE NOT FOUND';end if;
 select * into s from public.marg_bill_sales where estimate_id=d.id and status in('posted','corrected');
 if not found then raise exception 'MARG BILL APPROVED SALE REQUIRED BEFORE DELIVERY';end if;
 select * into disp from public.dispatches where estimate_id=d.id for update;
 if not found then raise exception 'DISPATCH NOT FOUND';end if;
 if disp.status='delivered' then return;end if;
 if disp.status not in('ready_for_dispatch') then raise exception 'ORDER IS NOT READY FOR DELIVERY';end if;
 update public.dispatches set status='delivered',
   tracking_code=coalesce(nullif(upper(btrim(coalesce(p_tracking_code,''))),''),tracking_code),
   delivered_at=coalesce(delivered_at,now()),stock_deducted_at=coalesce(stock_deducted_at,s.approved_at),updated_by=a.id
 where id=disp.id;
 update public.sales_documents set status='delivered' where id=d.id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'ACTUAL_DELIVERY_FINALIZED','estimate',d.id::text,
   jsonb_build_object('marg_bill_sale_id',s.id,'marg_bill_no',s.marg_bill_no,'stock_deduction_point','marg_bill_sale','stock_deducted_again',false,'request_key',btrim(p_request_key)));
end;$$;
revoke all on function public.finalize_actual_delivery(uuid,text,text) from public,anon;
grant execute on function public.finalize_actual_delivery(uuid,text,text) to authenticated;


create or replace function public.get_marg_bill_sale_queue() returns table(estimate_id uuid,estimate_number text,dealer_id uuid,final_payable numeric,marg_bill_number text,sale_status text,dispatch_status text,approved_at timestamptz) language plpgsql stable security definer set search_path=public as $$declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'STAFF AUTHORIZATION REQUIRED';end if;return query select e.id,e.estimate_number,e.dealer_id,e.final_payable,s.marg_bill_no,s.status,d.status,s.approved_at from marg_bill_sales s join sales_documents e on e.id=s.estimate_id left join dispatches d on d.estimate_id=e.id where s.status in('posted','corrected') order by s.approved_at desc;end$$;
revoke all on function public.get_marg_bill_sale_queue() from public,anon;grant execute on function public.get_marg_bill_sale_queue() to authenticated;


-- ESTIMATE MODIFICATION: allowed only before Marg Bill Sale posting.
create or replace function public.revise_estimate_before_sale(p_estimate_number text,p_lines jsonb,p_reason text)
returns integer language plpgsql security definer set search_path=public as $$
declare a public.app_users%rowtype;e public.sales_documents%rowtype;ln jsonb;iid uuid;q numeric;r numeric;amt numeric;sub numeric:=0;rev integer;before_json jsonb;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'OWNER / ADMIN / ACCOUNTANT AUTHORIZATION REQUIRED';end if;
 if nullif(btrim(coalesce(p_reason,'')),'') is null then raise exception 'REVISION REASON REQUIRED';end if;
 select * into e from public.sales_documents where estimate_number=upper(btrim(p_estimate_number)) and doc_type='estimate' for update;
 if not found then raise exception 'ESTIMATE NOT FOUND';end if;
 if exists(select 1 from public.marg_bill_sales where estimate_id=e.id) then raise exception 'SALE ALREADY POSTED; USE CONTROLLED SALE REVERSAL';end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'ESTIMATE ITEMS REQUIRED';end if;
 select coalesce(jsonb_agg(jsonb_build_object('item_id',item_id,'qty',qty,'rate',rate,'amount',amount) order by id),'[]'::jsonb) into before_json from public.sales_document_lines where document_id=e.id;
 create temporary table if not exists pg_temp.torvo_estimate_revision(item_id uuid,qty numeric,rate numeric,amount numeric) on commit drop;truncate pg_temp.torvo_estimate_revision;
 for ln in select * from jsonb_array_elements(p_lines) loop
  begin iid:=(ln->>'item_id')::uuid;q:=(ln->>'qty')::numeric;r:=(ln->>'rate')::numeric;exception when others then raise exception 'INVALID ESTIMATE LINE';end;
  if q<=0 or r<0 or not exists(select 1 from public.catalog_items where id=iid and active=true) then raise exception 'INVALID ESTIMATE LINE / ITEM';end if;
  amt:=round(q*r,2);sub:=sub+amt;insert into pg_temp.torvo_estimate_revision values(iid,q,r,amt);
 end loop;
 delete from public.sales_document_lines where document_id=e.id;
 insert into public.sales_document_lines(document_id,item_id,qty,rate,amount) select e.id,item_id,qty,rate,amount from pg_temp.torvo_estimate_revision;
 rev:=coalesce(e.revision_no,1)+1;
 update public.sales_documents set subtotal=sub,final_payable=sub+coalesce(e.freight,0)+coalesce(e.other_charges,0),revision_no=rev,status='estimate_revised' where id=e.id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'ESTIMATE_REVISED_BEFORE_SALE','estimate',e.id::text,jsonb_build_object('estimate_number',e.estimate_number,'revision_no',rev,'reason',upper(btrim(p_reason)),'before_lines',before_json,'new_subtotal',sub));
 return rev;
end;$$;
revoke all on function public.revise_estimate_before_sale(text,jsonb,text) from public,anon;
grant execute on function public.revise_estimate_before_sale(text,jsonb,text) to authenticated;

-- POSTED SALE REVERSAL: restores stock exactly once and cancels outbound dispatch before delivery.
create or replace function public.reverse_marg_bill_sale(p_estimate_number text,p_reason text)
returns void language plpgsql security definer set search_path=public as $$
declare a public.app_users%rowtype;e public.sales_documents%rowtype;s public.marg_bill_sales%rowtype;d public.dispatches%rowtype;ln record;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'OWNER / ADMIN AUTHORIZATION REQUIRED';end if;
 if nullif(btrim(coalesce(p_reason,'')),'') is null then raise exception 'REVERSAL REASON REQUIRED';end if;
 select * into e from public.sales_documents where estimate_number=upper(btrim(p_estimate_number)) and doc_type='estimate' for update;
 if not found then raise exception 'ESTIMATE NOT FOUND';end if;
 select * into s from public.marg_bill_sales where estimate_id=e.id for update;
 if not found or s.status='reversed' then raise exception 'ACTIVE POSTED SALE REQUIRED';end if;
 select * into d from public.dispatches where estimate_id=e.id for update;
 if found and d.status='delivered' then raise exception 'DELIVERED SALE CANNOT BE REVERSED HERE';end if;
 for ln in select item_id,sum(qty) qty from public.sales_document_lines where document_id=e.id group by item_id order by item_id loop
  insert into public.inventory(item_id,current_qty,updated_at) values(ln.item_id,ln.qty,now()) on conflict(item_id) do update set current_qty=public.inventory.current_qty+excluded.current_qty,updated_at=now();
  insert into public.inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by) values(ln.item_id,ln.qty,'MARG BILL SALE REVERSAL','marg_bill_sale',s.id,a.id);
 end loop;
 update public.marg_bill_sales set status='reversed',correction_reason=upper(btrim(p_reason)) where id=s.id;
 delete from public.dispatches where estimate_id=e.id and status<>'delivered';
 update public.sales_documents set status='sale_reversed' where id=e.id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'MARG_BILL_SALE_REVERSED','estimate',e.id::text,jsonb_build_object('sale_id',s.id,'marg_bill_no',s.marg_bill_no,'reason',upper(btrim(p_reason)),'stock_restored',true));
end;$$;
revoke all on function public.reverse_marg_bill_sale(text,text) from public,anon;
grant execute on function public.reverse_marg_bill_sale(text,text) to authenticated;
