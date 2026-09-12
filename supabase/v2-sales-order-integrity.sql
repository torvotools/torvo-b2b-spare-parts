-- TORVO V2 SALES / PURCHASE ORDER INTEGRITY HARDENING
-- Install after v2-schema.sql and before business/order RPCs that rely on these guards.
-- Staging verification required before production.

-- One catalog item may appear only once in one sales document.
-- Quantity must be changed on the existing line instead of creating duplicate lines.
create unique index if not exists idx_sales_document_lines_document_item_uq
  on public.sales_document_lines(document_id,item_id);

-- Payment request keys provide database-level replay/idempotency protection.
alter table public.payments
  add column if not exists request_key text;

create unique index if not exists idx_payments_request_key_uq
  on public.payments(request_key)
  where request_key is not null;

-- Dealer acknowledgement is bound to an exact revision and is invalidated by any later TORVO revision.
create or replace function public.torvo_apply_sales_order_revision(
  p_sales_order uuid,
  p_lines jsonb,
  p_reason text
) returns integer
language plpgsql
security definer
set search_path=public
as $$
declare
  a app_users%rowtype;
  d sales_documents%rowtype;
  ln jsonb;
  iid uuid;
  q numeric;
  r numeric;
  rg text;
  sub numeric:=0;
  new_revision integer;
  before_snapshot jsonb;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role not in('owner','admin','salesman') then raise exception 'Not authorized'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'Revision reason required'; end if;
  if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'Order lines required'; end if;

  select * into d from sales_documents
   where id=p_sales_order and doc_type='sales_order'
   for update;
  if not found then raise exception 'Sales order not found'; end if;
  if d.estimate_created_at is not null or d.locked_at is not null then raise exception 'Estimate-locked order cannot be revised'; end if;

  select rate_group into rg from dealers where id=d.dealer_id and status='approved';
  if rg is null then raise exception 'Approved dealer rate group required'; end if;

  select jsonb_build_object(
    'revision_no',d.revision_no,
    'subtotal',d.subtotal,
    'dealer_ok_revision',d.dealer_ok_revision,
    'lines',coalesce(jsonb_agg(jsonb_build_object('item_id',l.item_id,'qty',l.qty,'rate',l.rate,'amount',l.amount) order by l.id),'[]'::jsonb)
  ) into before_snapshot
  from sales_document_lines l where l.document_id=d.id;

  -- Validate duplicate item IDs before replacing any existing lines.
  if exists(
    select 1 from (
      select x->>'item_id' item_id,count(*) c from jsonb_array_elements(p_lines) x group by x->>'item_id'
    ) s where s.item_id is null or s.c>1
  ) then raise exception 'Duplicate or missing item in order revision'; end if;

  delete from sales_document_lines where document_id=d.id;
  for ln in select * from jsonb_array_elements(p_lines) loop
    begin iid:=(ln->>'item_id')::uuid; q:=(ln->>'qty')::numeric;
    exception when others then raise exception 'Invalid order line'; end;
    if q is null or q<=0 then raise exception 'Invalid quantity'; end if;
    perform 1 from catalog_items where id=iid and active=true;
    if not found then raise exception 'Item unavailable'; end if;
    select selling_rate into r from item_rates where item_id=iid and rate_group=rg and min_qty<=q order by min_qty desc limit 1;
    if r is null then raise exception 'Rate unavailable for an item'; end if;
    insert into sales_document_lines(document_id,item_id,qty,rate,amount) values(d.id,iid,q,r,round(q*r,2));
    sub:=sub+round(q*r,2);
  end loop;

  new_revision:=d.revision_no+1;
  update sales_documents set
    revision_no=new_revision,
    subtotal=sub,
    final_payable=sub+coalesce(freight,0)+coalesce(other_charges,0),
    dealer_ok_revision=null,
    dealer_ok_at=null,
    status='revised'
  where id=d.id;

  insert into sales_order_revisions(sales_order_id,revision_no,changed_by,actor_role,change_reason,before_data,after_data)
  values(d.id,new_revision,a.id,a.role,upper(trim(p_reason)),before_snapshot,
    jsonb_build_object('revision_no',new_revision,'subtotal',sub,'dealer_ok_revision',null,'lines',p_lines));
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,'SALES_ORDER_REVISED','sales_order',d.id::text,jsonb_build_object('revision_no',new_revision,'dealer_ok_invalidated',true,'reason',upper(trim(p_reason))));
  return new_revision;
end;$$;

revoke all on function public.torvo_apply_sales_order_revision(uuid,jsonb,text) from public;
grant execute on function public.torvo_apply_sales_order_revision(uuid,jsonb,text) to authenticated;

create or replace function public.dealer_confirm_sales_order_revision(
  p_sales_order uuid,
  p_revision integer
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare a app_users%rowtype; did uuid; d sales_documents%rowtype;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true and role='dealer';
  if not found then raise exception 'Dealer login required'; end if;
  did:=a.dealer_id;
  if did is null then select dealer_id into did from app_user_dealer_links where user_id=a.id limit 1; end if;
  select * into d from sales_documents where id=p_sales_order and doc_type='sales_order' and dealer_id=did for update;
  if not found then raise exception 'Sales order not found'; end if;
  if d.estimate_created_at is not null or d.locked_at is not null then raise exception 'Order already locked'; end if;
  if p_revision is null or p_revision<>d.revision_no then raise exception 'Only latest exact revision can be confirmed'; end if;
  update sales_documents set dealer_ok_revision=d.revision_no,dealer_ok_at=now(),status='dealer_ok' where id=d.id;
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,'DEALER_OK','sales_order',d.id::text,jsonb_build_object('revision_no',d.revision_no));
end;$$;

revoke all on function public.dealer_confirm_sales_order_revision(uuid,integer) from public;
grant execute on function public.dealer_confirm_sales_order_revision(uuid,integer) to authenticated;

-- Conversion to Estimate is allowed only from the exact latest Dealer-OK revision.
create or replace function public.convert_sales_order_to_estimate(p_sales_order uuid) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare a app_users%rowtype; d sales_documents%rowtype; eid uuid;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized'; end if;
  select * into d from sales_documents where id=p_sales_order and doc_type='sales_order' for update;
  if not found then raise exception 'Sales order not found'; end if;
  if d.estimate_created_at is not null or d.locked_at is not null then raise exception 'Sales order already converted/locked'; end if;
  if d.dealer_ok_revision is null or d.dealer_ok_revision<>d.revision_no then raise exception 'Latest Dealer OK required'; end if;

  insert into sales_documents(dealer_id,doc_type,status,parent_id,root_order_id,subtotal,freight,other_charges,final_payable,created_by,revision_no,dealer_ok_revision,dealer_ok_at,estimate_created_at,locked_at,lock_reason)
  values(d.dealer_id,'estimate','created',d.id,coalesce(d.root_order_id,d.id),d.subtotal,d.freight,d.other_charges,d.final_payable,a.id,d.revision_no,d.dealer_ok_revision,d.dealer_ok_at,now(),now(),'ESTIMATE CREATED FROM EXACT DEALER-OK REVISION')
  returning id into eid;
  insert into sales_document_lines(document_id,item_id,qty,rate,amount)
    select eid,item_id,qty,rate,amount from sales_document_lines where document_id=d.id;
  update sales_documents set estimate_created_at=now(),locked_at=now(),lock_reason='CONVERTED TO ESTIMATE',status='estimate_created' where id=d.id;
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,'ESTIMATE_CREATED','sales_order',d.id::text,jsonb_build_object('estimate_id',eid,'revision_no',d.revision_no));
  return eid;
end;$$;

revoke all on function public.convert_sales_order_to_estimate(uuid) from public;
grant execute on function public.convert_sales_order_to_estimate(uuid) to authenticated;
