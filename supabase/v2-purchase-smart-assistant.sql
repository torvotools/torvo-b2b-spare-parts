-- TORVO V2 SMART PURCHASE ASSISTANT
-- Purpose: while OWNER enters a Purchase item, show trusted previous buying context beside the item.
-- Purchase cost/supplier history is confidential and OWNER-ONLY.
-- This is advisory history only; it never auto-overwrites the new Purchase rate.
-- Install after Purchase Entry + Purchase stock receipt integrity.
-- STAGING RUNTIME VERIFICATION REQUIRED.

create index if not exists idx_purchase_lines_item_purchase on public.purchase_lines(item_id,purchase_id);
create index if not exists idx_purchase_headers_supplier_invoice_date on public.purchase_headers(supplier_id,invoice_date desc,created_at desc);

create or replace function public.get_purchase_item_assistant(
  p_item uuid,
  p_supplier uuid default null,
  p_history_limit integer default 5
) returns jsonb
language plpgsql stable security definer set search_path=public as $$
declare
  a public.app_users%rowtype;
  c public.catalog_items%rowtype;
  lim integer:=greatest(1,least(coalesce(p_history_limit,5),10));
  last_any jsonb;
  last_same jsonb;
  lowest_recent jsonb;
  history jsonb;
  current_stock numeric:=0;
begin
  select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
  if p_item is null then raise exception 'Item required';end if;
  select * into c from public.catalog_items where id=p_item and active=true;
  if not found then raise exception 'Active item not found';end if;
  if p_supplier is not null and not exists(select 1 from public.suppliers where id=p_supplier and active=true) then raise exception 'Active supplier required';end if;

  select coalesce(i.current_qty,0) into current_stock from public.inventory i where i.item_id=p_item;

  select jsonb_build_object(
    'purchase_id',h.id,'invoice_no',h.invoice_no,'invoice_date',h.invoice_date,
    'supplier_id',h.supplier_id,'supplier_name',s.supplier_name,
    'qty',l.qty,'purchase_rate',l.purchase_rate,'line_amount',l.line_amount
  ) into last_any
  from public.purchase_lines l
  join public.purchase_headers h on h.id=l.purchase_id
  left join public.suppliers s on s.id=h.supplier_id
  join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
  where l.item_id=p_item
  order by h.invoice_date desc,h.created_at desc,l.id desc limit 1;

  if p_supplier is not null then
    select jsonb_build_object(
      'purchase_id',h.id,'invoice_no',h.invoice_no,'invoice_date',h.invoice_date,
      'supplier_id',h.supplier_id,'supplier_name',s.supplier_name,
      'qty',l.qty,'purchase_rate',l.purchase_rate,'line_amount',l.line_amount
    ) into last_same
    from public.purchase_lines l
    join public.purchase_headers h on h.id=l.purchase_id
    left join public.suppliers s on s.id=h.supplier_id
    join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
    where l.item_id=p_item and h.supplier_id=p_supplier
    order by h.invoice_date desc,h.created_at desc,l.id desc limit 1;
  end if;

  select jsonb_build_object(
    'purchase_id',h.id,'invoice_no',h.invoice_no,'invoice_date',h.invoice_date,
    'supplier_id',h.supplier_id,'supplier_name',s.supplier_name,
    'qty',l.qty,'purchase_rate',l.purchase_rate
  ) into lowest_recent
  from public.purchase_lines l
  join public.purchase_headers h on h.id=l.purchase_id
  left join public.suppliers s on s.id=h.supplier_id
  join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
  where l.item_id=p_item and h.invoice_date>=current_date-interval '180 days'
  order by l.purchase_rate asc,h.invoice_date desc,h.created_at desc limit 1;

  select coalesce(jsonb_agg(x.row_data order by x.invoice_date desc,x.created_at desc),'[]'::jsonb) into history
  from(
    select h.invoice_date,h.created_at,jsonb_build_object(
      'purchase_id',h.id,'invoice_no',h.invoice_no,'invoice_date',h.invoice_date,
      'supplier_id',h.supplier_id,'supplier_name',s.supplier_name,
      'qty',l.qty,'purchase_rate',l.purchase_rate,'line_amount',l.line_amount
    ) row_data
    from public.purchase_lines l
    join public.purchase_headers h on h.id=l.purchase_id
    left join public.suppliers s on s.id=h.supplier_id
    join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
    where l.item_id=p_item
    order by h.invoice_date desc,h.created_at desc
    limit lim
  ) x;

  return jsonb_build_object(
    'item',jsonb_build_object('id',c.id,'item_code',c.item_code,'oem_code',c.oem_code,'name',c.name,'brand',c.brand,'category',c.category,'item_type',c.item_type),
    'current_stock',current_stock,
    'last_purchase',last_any,
    'last_from_selected_supplier',last_same,
    'lowest_received_rate_last_180_days',lowest_recent,
    'recent_history',history,
    'history_limit',lim,
    'advisory_only',true,
    'rate_must_be_confirmed_by_owner',true
  );
end;$$;
revoke all on function public.get_purchase_item_assistant(uuid,uuid,integer) from public,anon;
grant execute on function public.get_purchase_item_assistant(uuid,uuid,integer) to authenticated;

-- Rate comparison helper for the Purchase Entry UI. It returns a warning, not a forced decision.
create or replace function public.check_purchase_rate_against_history(
  p_item uuid,
  p_supplier uuid,
  p_new_rate numeric
) returns jsonb
language plpgsql stable security definer set search_path=public as $$
declare a public.app_users%rowtype;last_rate numeric;last_supplier text;last_date date;same_rate numeric;same_date date;delta numeric;delta_pct numeric;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
 if p_item is null or p_new_rate is null or p_new_rate<0 then raise exception 'Valid item and rate required';end if;
 select l.purchase_rate,s.supplier_name,h.invoice_date into last_rate,last_supplier,last_date
 from public.purchase_lines l join public.purchase_headers h on h.id=l.purchase_id
 left join public.suppliers s on s.id=h.supplier_id
 join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
 where l.item_id=p_item order by h.invoice_date desc,h.created_at desc limit 1;
 if p_supplier is not null then
   select l.purchase_rate,h.invoice_date into same_rate,same_date
   from public.purchase_lines l join public.purchase_headers h on h.id=l.purchase_id
   join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
   where l.item_id=p_item and h.supplier_id=p_supplier order by h.invoice_date desc,h.created_at desc limit 1;
 end if;
 delta:=case when last_rate is null then null else p_new_rate-last_rate end;
 delta_pct:=case when last_rate is null or last_rate=0 then null else round((delta*100/last_rate)::numeric,2) end;
 return jsonb_build_object(
   'new_rate',p_new_rate,
   'last_received_rate',last_rate,
   'last_supplier_name',last_supplier,
   'last_invoice_date',last_date,
   'selected_supplier_last_rate',same_rate,
   'selected_supplier_last_date',same_date,
   'difference_amount',delta,
   'difference_percent',delta_pct,
   'direction',case when delta is null then 'NO HISTORY' when delta>0 then 'HIGHER' when delta<0 then 'LOWER' else 'SAME' end,
   'warning',case when delta_pct is not null and delta_pct>=10 then 'NEW RATE IS 10% OR MORE ABOVE LAST RECEIVED RATE' else null end,
   'advisory_only',true
 );
end;$$;
revoke all on function public.check_purchase_rate_against_history(uuid,uuid,numeric) from public,anon;
grant execute on function public.check_purchase_rate_against_history(uuid,uuid,numeric) to authenticated;
