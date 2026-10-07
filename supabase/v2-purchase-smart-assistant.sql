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


-- SMART STOCK / REORDER INTELLIGENCE
-- Owner-only advisory. Uses canonical inventory + movement ledger; never creates a Purchase Order.
create or replace function public.get_smart_stock_intelligence(
  p_days integer default 90,
  p_limit integer default 200
) returns table(
  item_id uuid,item_code text,item_name text,brand text,item_type text,
  current_qty numeric,reorder_level numeric,
  sold_qty numeric,sales_return_qty numeric,sale_reversal_qty numeric,net_outbound_qty numeric,
  avg_daily_outbound numeric,days_of_stock numeric,
  last_sale_at timestamptz,last_movement_at timestamptz,
  demand_signal_score numeric,stock_class text,suggested_reorder_qty numeric,reason text
)
language plpgsql stable security definer set search_path=public as $$
declare
  a public.app_users%rowtype;
  d integer:=greatest(30,least(coalesce(p_days,90),365));
begin
  select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
  if not found or lower(coalesce(a.role,''))<>'owner' then raise exception 'Owner authorization required';end if;

  return query
  with mv as(
    select m.item_id,
      coalesce(sum(-m.qty_change) filter(where m.reason='MARG BILL APPROVED SALE' and m.qty_change<0),0)::numeric sold,
      coalesce(sum(m.qty_change) filter(where m.reason='SALES RETURN' and m.qty_change>0),0)::numeric sales_ret,
      coalesce(sum(m.qty_change) filter(where m.reason='MARG BILL SALE REVERSAL' and m.qty_change>0),0)::numeric sale_rev,
      max(m.created_at) filter(where m.reason='MARG BILL APPROVED SALE' and m.qty_change<0) last_sale,
      max(m.created_at) last_move
    from public.inventory_movements m
    where m.created_at>=now()-make_interval(days=>d)
    group by m.item_id
  ), mv_history as(
    select m.item_id,
      max(m.created_at) filter(where m.reason='MARG BILL APPROVED SALE' and m.qty_change<0) last_sale,
      max(m.created_at) last_move
    from public.inventory_movements m
    group by m.item_id
  ), demand as(
    select x.matched_item_id item_id,max(x.opportunity_score)::numeric score
    from public.admin_demand_intelligence(d,500) x
    where x.matched_item_id is not null
    group by x.matched_item_id
  ), base as(
    select c.id,c.item_code,c.name,c.brand,c.item_type,
      coalesce(i.current_qty,0)::numeric stock,coalesce(i.reorder_level,0)::numeric reorder,
      coalesce(m.sold,0)::numeric sold,coalesce(m.sales_ret,0)::numeric sales_ret,coalesce(m.sale_rev,0)::numeric sale_rev,
      greatest(coalesce(m.sold,0)-coalesce(m.sales_ret,0)-coalesce(m.sale_rev,0),0)::numeric net_out,
      mh.last_sale,mh.last_move,coalesce(dm.score,0)::numeric demand_score
    from public.catalog_items c
    left join public.inventory i on i.item_id=c.id
    left join mv m on m.item_id=c.id
    left join mv_history mh on mh.item_id=c.id
    left join demand dm on dm.item_id=c.id
    where coalesce(c.active,true)=true
  )
  select b.id,b.item_code,b.name,b.brand,b.item_type,b.stock,b.reorder,b.sold,b.sales_ret,b.sale_rev,b.net_out,
    round((b.net_out/d)::numeric,4),
    case when b.net_out>0 then round((b.stock/(b.net_out/d))::numeric,1) else null end,
    b.last_sale,b.last_move,b.demand_score,
    case
      when b.stock<=0 and (b.net_out>0 or b.demand_score>0) then 'ZERO STOCK + DEMAND'
      when b.stock<=b.reorder and (b.net_out>0 or b.demand_score>0) then 'REORDER NOW'
      when b.last_sale is null and b.stock>0 and b.last_move is not null and b.last_move<now()-interval '180 days' then 'DEAD STOCK'
      when b.net_out >= greatest(b.reorder,1)*2 then 'FAST MOVING'
      when b.net_out>0 then 'SLOW MOVING'
      else 'NEW / NO HISTORY'
    end,
    greatest(
      case when b.net_out>0 then ceil((b.net_out/d)*45 + b.reorder - b.stock) else b.reorder-b.stock end,
      0
    )::numeric,
    case
      when b.stock<=0 and (b.net_out>0 or b.demand_score>0) then 'NO STOCK WITH VERIFIED SALES/DEMAND SIGNAL'
      when b.stock<=b.reorder and (b.net_out>0 or b.demand_score>0) then 'AT OR BELOW REORDER LEVEL WITH ACTIVE DEMAND'
      when b.last_sale is null and b.stock>0 and b.last_move is not null and b.last_move<now()-interval '180 days' then 'STOCK EXISTS BUT NO SALE IN OBSERVED HISTORY'
      when b.net_out >= greatest(b.reorder,1)*2 then 'HIGH NET OUTBOUND VELOCITY'
      when b.net_out>0 then 'POSITIVE NET OUTBOUND, BELOW FAST-MOVING THRESHOLD'
      else 'INSUFFICIENT REAL MOVEMENT HISTORY'
    end
  from base b
  order by
    case
      when b.stock<=0 and (b.net_out>0 or b.demand_score>0) then 1
      when b.stock<=b.reorder and (b.net_out>0 or b.demand_score>0) then 2
      when b.net_out >= greatest(b.reorder,1)*2 then 3
      when b.net_out>0 then 4
      when b.last_sale is null and b.stock>0 and b.last_move is not null and b.last_move<now()-interval '180 days' then 5
      else 6 end,
    b.demand_score desc,b.net_out desc,b.name
  limit greatest(1,least(coalesce(p_limit,200),500));
end;$$;
revoke all on function public.get_smart_stock_intelligence(integer,integer) from public,anon;
grant execute on function public.get_smart_stock_intelligence(integer,integer) to authenticated;
