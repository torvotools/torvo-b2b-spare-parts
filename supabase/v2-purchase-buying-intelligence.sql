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
