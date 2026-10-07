-- TORVO V2 PURCHASE BUYING INTELLIGENCE
-- Owner-only purchase-cost decision support for Purchase Entry.
-- REAL HISTORY ONLY: only actually RECEIVED and currently UNREVERSED Purchase stock qualifies.
-- Install after v2-purchase-entry-integrity.sql.
create or replace function public.get_purchase_buying_intelligence(p_item uuid,p_supplier uuid default null,p_limit integer default 8)
returns table(last_purchase_date date,last_supplier_id uuid,last_supplier_name text,last_purchase_rate numeric,last_qty numeric,selected_supplier_last_date date,selected_supplier_last_rate numeric,selected_supplier_last_qty numeric,lowest_recent_rate numeric,lowest_recent_supplier_name text,highest_recent_rate numeric,recent_purchase_count bigint,recent_history jsonb)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;lim integer:=greatest(1,least(coalesce(p_limit,8),20));
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
 if p_item is null then raise exception 'Item required';end if;if not exists(select 1 from catalog_items where id=p_item) then raise exception 'Item not found';end if;
 return query with hist as(
  select h.id,h.supplier_id,s.supplier_name,h.invoice_no,h.invoice_date,h.created_at,l.qty,l.purchase_rate
  from purchase_lines l join purchase_headers h on h.id=l.purchase_id join purchase_stock_receipts psr on psr.purchase_id=h.id and psr.reversed_at is null left join suppliers s on s.id=h.supplier_id
  where l.item_id=p_item and not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED')
 ),last_any as(select * from hist order by invoice_date desc,created_at desc limit 1),last_sel as(select * from hist where p_supplier is not null and supplier_id=p_supplier order by invoice_date desc,created_at desc limit 1),low as(select * from hist order by purchase_rate asc,invoice_date desc,created_at desc limit 1),stats as(select max(purchase_rate) hi,count(*) cnt from hist),recent as(select coalesce(jsonb_agg(jsonb_build_object('purchase_id',z.id,'invoice_no',z.invoice_no,'invoice_date',z.invoice_date,'supplier_id',z.supplier_id,'supplier_name',z.supplier_name,'qty',z.qty,'purchase_rate',z.purchase_rate) order by z.invoice_date desc,z.created_at desc),'[]'::jsonb)j from(select * from hist order by invoice_date desc,created_at desc limit lim)z)
 select la.invoice_date,la.supplier_id,la.supplier_name,la.purchase_rate,la.qty,ls.invoice_date,ls.purchase_rate,ls.qty,lo.purchase_rate,lo.supplier_name,st.hi,st.cnt,re.j from stats st cross join recent re left join last_any la on true left join last_sel ls on true left join low lo on true;
end;$$;
revoke all on function public.get_purchase_buying_intelligence(uuid,uuid,integer) from public,anon;grant execute on function public.get_purchase_buying_intelligence(uuid,uuid,integer) to authenticated;


-- TORVO PURCHASE BRAIN
-- Owner-only advisory combining stock intelligence, private aggregate Service Book usage,
-- and real received Purchase history. It never creates or approves a Purchase Order.
create or replace function public.get_torvo_purchase_brain(
  p_days integer default 90,
  p_limit integer default 100
) returns table(
  item_id uuid,item_code text,item_name text,brand text,item_type text,
  current_qty numeric,reorder_level numeric,net_outbound_qty numeric,
  service_parts_used_qty numeric,demand_signal_score numeric,stock_class text,
  suggested_reorder_qty numeric,last_purchase_date date,last_supplier_name text,
  last_purchase_rate numeric,lowest_recent_rate numeric,recommendation text
)
language plpgsql stable security definer set search_path=public as $$
declare a public.app_users%rowtype;d integer:=greatest(30,least(coalesce(p_days,90),365));
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or lower(coalesce(a.role,''))<>'owner' then raise exception 'Owner authorization required';end if;

 return query
 with stock as(
   select * from public.get_smart_stock_intelligence(d,500)
 ),svc as(
   select p.item_id,coalesce(sum(p.qty),0)::numeric used_qty
   from public.dealer_service_job_parts p
   join public.dealer_service_jobs j on j.id=p.job_id
   where p.created_at>=now()-make_interval(days=>d)
     and lower(coalesce(j.status,'')) not in('cancelled','canceled')
   group by p.item_id
 ),hist as(
   select l.item_id,h.invoice_date,h.created_at,s.supplier_name,l.purchase_rate,
     row_number() over(partition by l.item_id order by h.invoice_date desc,h.created_at desc,l.id desc) rn,
     min(l.purchase_rate) over(partition by l.item_id) low_rate
   from public.purchase_lines l
   join public.purchase_headers h on h.id=l.purchase_id
   join public.purchase_stock_receipts r on r.purchase_id=h.id and r.reversed_at is null
   left join public.suppliers s on s.id=h.supplier_id
   where h.invoice_date>=current_date-interval '180 days'
     and not exists(select 1 from public.audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED')
 ),last_hist as(
   select item_id,invoice_date,supplier_name,purchase_rate,low_rate from hist where rn=1
 )
 select st.item_id,st.item_code,st.item_name,st.brand,st.item_type,
   st.current_qty,st.reorder_level,st.net_outbound_qty,
   coalesce(sv.used_qty,0)::numeric,st.demand_signal_score,st.stock_class,
   greatest(st.suggested_reorder_qty,
     case when coalesce(sv.used_qty,0)>0
       then ceil((coalesce(sv.used_qty,0)/d)*45 + st.reorder_level - st.current_qty)
       else 0 end,0)::numeric,
   lh.invoice_date,lh.supplier_name,lh.purchase_rate,lh.low_rate,
   case
    when st.stock_class='ZERO STOCK + DEMAND' then 'URGENT BUY REVIEW'
    when st.stock_class='REORDER NOW' then 'BUY REVIEW'
    when st.stock_class='FAST MOVING' and st.days_of_stock is not null and st.days_of_stock<=45 then 'PLAN PURCHASE'
    when coalesce(sv.used_qty,0)>0 and st.current_qty<=st.reorder_level then 'SERVICE DEMAND - BUY REVIEW'
    when st.stock_class='DEAD STOCK' then 'DO NOT REORDER WITHOUT OWNER REVIEW'
    else 'MONITOR'
   end
 from stock st
 left join svc sv on sv.item_id=st.item_id
 left join last_hist lh on lh.item_id=st.item_id
 order by
   case
    when st.stock_class='ZERO STOCK + DEMAND' then 1
    when st.stock_class='REORDER NOW' then 2
    when st.stock_class='FAST MOVING' then 3
    when coalesce(sv.used_qty,0)>0 then 4
    when st.stock_class='DEAD STOCK' then 6 else 5 end,
   st.demand_signal_score desc,st.net_outbound_qty desc,st.item_name
 limit greatest(1,least(coalesce(p_limit,100),500));
end;$$;
revoke all on function public.get_torvo_purchase_brain(integer,integer) from public,anon;
grant execute on function public.get_torvo_purchase_brain(integer,integer) to authenticated;
