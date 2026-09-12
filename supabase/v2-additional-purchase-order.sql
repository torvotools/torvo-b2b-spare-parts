-- TORVO V2 ADD MORE ITEMS / ADDITIONAL PURCHASE ORDER
-- Requires v2-schema.sql + v2-sales-order-integrity.sql.
-- Never mutates the original Sales Order or Estimate.
-- Staging verification required before production.

create table if not exists public.additional_purchase_order_links (
  id uuid primary key default gen_random_uuid(),
  original_sales_order_id uuid not null references public.sales_documents(id) on delete restrict,
  original_estimate_id uuid references public.sales_documents(id) on delete restrict,
  additional_sales_order_id uuid not null unique references public.sales_documents(id) on delete restrict,
  dealer_id uuid not null references public.dealers(id) on delete restrict,
  requested_by uuid not null references public.app_users(id),
  approved_by uuid references public.app_users(id),
  approved_at timestamptz,
  status text not null default 'pending_approval' check(status in('pending_approval','approved','rejected','cancelled')),
  request_reason text,
  decision_reason text,
  created_at timestamptz not null default now()
);
create index if not exists idx_additional_po_original on public.additional_purchase_order_links(original_sales_order_id,created_at desc);
create index if not exists idx_additional_po_dealer on public.additional_purchase_order_links(dealer_id,created_at desc);

alter table public.additional_purchase_order_links enable row level security;
revoke all on public.additional_purchase_order_links from anon, authenticated;

-- Dealer requests ADD MORE ITEMS. A new linked draft Sales Order is created; original remains untouched.
create or replace function public.request_additional_purchase_order(
  p_original_sales_order uuid,
  p_lines jsonb,
  p_reason text default null
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  a app_users%rowtype; did uuid; orig sales_documents%rowtype; rg text;
  add_order uuid; link_id uuid; ln jsonb; iid uuid; q numeric; r numeric; sub numeric:=0;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true and role='dealer';
  if not found then raise exception 'Dealer login required'; end if;
  did:=a.dealer_id;
  if did is null then select dealer_id into did from app_user_dealer_links where user_id=a.id limit 1; end if;
  select * into orig from sales_documents where id=p_original_sales_order and doc_type='sales_order' and dealer_id=did;
  if not found then raise exception 'Original sales order not found'; end if;
  if orig.estimate_created_at is null then raise exception 'ADD MORE ITEMS is available after original Estimate creation'; end if;
  if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'Additional order lines required'; end if;
  if exists(select 1 from (select x->>'item_id' item_id,count(*) c from jsonb_array_elements(p_lines) x group by x->>'item_id') s where s.item_id is null or s.c>1) then raise exception 'Duplicate or missing item in additional order'; end if;
  select rate_group into rg from dealers where id=did and status='approved';
  if rg is null then raise exception 'Approved dealer rate group required'; end if;

  insert into sales_documents(dealer_id,doc_type,status,parent_id,root_order_id,subtotal,final_payable,created_by,revision_no,dealer_modification_limit,dealer_modifications_used)
  values(did,'sales_order','additional_pending_approval',orig.id,coalesce(orig.root_order_id,orig.id),0,0,a.id,1,2,0) returning id into add_order;

  for ln in select * from jsonb_array_elements(p_lines) loop
    begin iid:=(ln->>'item_id')::uuid; q:=(ln->>'qty')::numeric; exception when others then raise exception 'Invalid additional order line'; end;
    if q is null or q<=0 then raise exception 'Invalid quantity'; end if;
    perform 1 from catalog_items where id=iid and active=true; if not found then raise exception 'Item unavailable'; end if;
    select selling_rate into r from item_rates where item_id=iid and rate_group=rg and min_qty<=q order by min_qty desc limit 1;
    if r is null then raise exception 'Rate unavailable for an item'; end if;
    insert into sales_document_lines(document_id,item_id,qty,rate,amount) values(add_order,iid,q,r,round(q*r,2));
    sub:=sub+round(q*r,2);
  end loop;
  update sales_documents set subtotal=sub,final_payable=sub where id=add_order;

  insert into additional_purchase_order_links(original_sales_order_id,original_estimate_id,additional_sales_order_id,dealer_id,requested_by,request_reason)
  values(orig.id,(select id from sales_documents where parent_id=orig.id and doc_type='estimate' order by created_at desc limit 1),add_order,did,a.id,nullif(upper(trim(p_reason)),'')) returning id into link_id;
  insert into sales_order_revisions(sales_order_id,revision_no,changed_by,actor_role,change_reason,after_data)
  values(add_order,1,a.id,'dealer','ADDITIONAL PURCHASE ORDER REQUESTED',jsonb_build_object('original_sales_order_id',orig.id,'subtotal',sub,'lines',p_lines));
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,'ADDITIONAL_PURCHASE_ORDER_REQUESTED','sales_order',add_order::text,jsonb_build_object('original_sales_order_id',orig.id,'link_id',link_id,'subtotal',sub));
  return add_order;
end;$$;
revoke all on function public.request_additional_purchase_order(uuid,jsonb,text) from public;
grant execute on function public.request_additional_purchase_order(uuid,jsonb,text) to authenticated;

-- TORVO approval is required before the additional order enters normal revision / Dealer OK / Estimate flow.
create or replace function public.decide_additional_purchase_order(
  p_additional_sales_order uuid,
  p_approve boolean,
  p_reason text
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare a app_users%rowtype; l additional_purchase_order_links%rowtype;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin approval required'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'Decision reason required'; end if;
  select * into l from additional_purchase_order_links where additional_sales_order_id=p_additional_sales_order for update;
  if not found or l.status<>'pending_approval' then raise exception 'Pending additional order required'; end if;
  update additional_purchase_order_links set status=case when p_approve then 'approved' else 'rejected' end,approved_by=a.id,approved_at=now(),decision_reason=upper(trim(p_reason)) where id=l.id;
  update sales_documents set status=case when p_approve then 'submitted' else 'additional_rejected' end where id=p_additional_sales_order;
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,case when p_approve then 'ADDITIONAL_PURCHASE_ORDER_APPROVED' else 'ADDITIONAL_PURCHASE_ORDER_REJECTED' end,'sales_order',p_additional_sales_order::text,jsonb_build_object('original_sales_order_id',l.original_sales_order_id,'reason',upper(trim(p_reason))));
end;$$;
revoke all on function public.decide_additional_purchase_order(uuid,boolean,text) from public;
grant execute on function public.decide_additional_purchase_order(uuid,boolean,text) to authenticated;

-- Dealer-safe 30-day order history. No payment, outstanding, purchase cost or internal accounting fields are returned.
create or replace function public.get_dealer_order_history_30d()
returns table(document_id uuid,document_type text,document_status text,revision_no integer,subtotal numeric,freight numeric,other_charges numeric,final_payable numeric,created_at timestamptz,parent_id uuid,root_order_id uuid)
language plpgsql security definer set search_path=public
as $$
declare a app_users%rowtype; did uuid;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true and role='dealer';
  if not found then raise exception 'Dealer login required'; end if;
  did:=a.dealer_id; if did is null then select dealer_id into did from app_user_dealer_links where user_id=a.id limit 1; end if;
  if did is null then raise exception 'Dealer link required'; end if;
  return query select d.id,d.doc_type,d.status,d.revision_no,d.subtotal,d.freight,d.other_charges,d.final_payable,d.created_at,d.parent_id,d.root_order_id
    from sales_documents d where d.dealer_id=did and d.doc_type in('sales_order','estimate') and d.created_at>=now()-interval '30 days' order by d.created_at desc;
end;$$;
revoke all on function public.get_dealer_order_history_30d() from public;
grant execute on function public.get_dealer_order_history_30d() to authenticated;
