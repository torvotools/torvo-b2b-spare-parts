-- TORVO V2 Item Movement Center + Low Stock source drilldown.
-- Canonical inventory_movements fields: qty_change, reason, reference_type, reference_id, created_at.
-- Real purchase/sales/inventory records only; no duplicated Purchase or Sale history.
-- Purchase rates and supplier details are Owner-only. Store Keeper never receives Purchase source/financial fields.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

create or replace function get_item_movement_center(p_item uuid,p_from timestamptz default null,p_to timestamptz default null,p_kind text default 'all',p_limit integer default 250)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;c catalog_items%rowtype;i inventory%rowtype;lim integer:=greatest(1,least(coalesce(p_limit,250),1000));result jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Owner/Admin/Store Keeper required'; end if;
 if p_item is null then raise exception 'Item required'; end if;
 if p_kind not in('all','purchase','sale','movement') then raise exception 'Invalid movement filter'; end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid date range'; end if;
 select * into c from catalog_items where id=p_item;if not found then raise exception 'Item not found';end if;
 select * into i from inventory where item_id=p_item;
 with events as(
   select h.created_at event_at,'purchase'::text kind,'PURCHASE'::text movement_type,l.qty qty_change,h.invoice_no::text reference_no,
     case when a.role='owner' then s.supplier_name else null end party,case when a.role='owner' then l.purchase_rate else null end rate,case when a.role='owner' then l.line_amount else null end amount,h.id reference_id
   from purchase_lines l join purchase_headers h on h.id=l.purchase_id left join suppliers s on s.id=h.supplier_id
   where l.item_id=p_item and not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED')
   union all
   select coalesce(dp.delivered_at,e.created_at),'sale','SALE',-sl.qty,coalesce(e.final_sale_serial::text,e.id::text),case when a.role in('owner','admin') then d.shop_name else null end,case when a.role in('owner','admin') then sl.rate else null end,case when a.role in('owner','admin') then sl.amount else null end,e.id
   from sales_document_lines sl join sales_documents e on e.id=sl.document_id join dispatches dp on dp.estimate_id=e.id and dp.status='delivered' left join dealers d on d.id=e.dealer_id where sl.item_id=p_item and e.doc_type='estimate'
   union all
   select m.created_at,'movement',upper(replace(coalesce(m.reference_type,'movement'),'_',' ')),m.qty_change,case when m.reference_id is null then null else m.reference_id::text end,m.reason,null::numeric,null::numeric,m.reference_id
   from inventory_movements m where m.item_id=p_item and coalesce(m.reference_type,'') not in('purchase','estimate','delivery','dispatch')
 ),filtered as(select * from events where(p_from is null or event_at>=p_from) and(p_to is null or event_at<p_to) and(p_kind='all' or kind=p_kind) order by event_at desc limit lim),summary as(select coalesce(sum(case when kind='purchase' and qty_change>0 then qty_change else 0 end),0) purchased_qty,coalesce(sum(case when kind='sale' and qty_change<0 then -qty_change else 0 end),0) sold_qty,max(event_at) last_movement_at from events)
 select jsonb_build_object('item',jsonb_build_object('id',c.id,'item_code',c.item_code,'oem_code',c.oem_code,'name',c.name,'item_type',c.item_type,'brand',c.brand,'category',c.category,'model',c.model,'active',c.active),'stock',jsonb_build_object('current_qty',coalesce(i.current_qty,0),'reorder_level',coalesce(i.reorder_level,0),'updated_at',i.updated_at),'summary',(select to_jsonb(summary) from summary),'events',coalesce((select jsonb_agg(to_jsonb(filtered) order by event_at desc) from filtered),'[]'::jsonb),'financial_visibility',case when a.role='owner' then 'owner_purchase_and_sales' when a.role='admin' then 'sales_only' else 'none' end) into result;
 return result;
end;$$;
revoke all on function get_item_movement_center(uuid,timestamptz,timestamptz,text,integer) from public,anon;
grant execute on function get_item_movement_center(uuid,timestamptz,timestamptz,text,integer) to authenticated;

-- p_supplier is Owner-only. Admin may see invoice/date source, but not supplier/rate. Store Keeper receives stock fields only.
create or replace function get_low_stock_drilldown(p_search text default null,p_state text default 'low',p_brand text default null,p_category text default null,p_supplier uuid default null,p_limit integer default 250)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;s text:=lower(trim(coalesce(p_search,'')));lim integer:=greatest(1,least(coalesce(p_limit,250),1000));r jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Owner/Admin/Store Keeper required'; end if;
 if p_state not in('all','low','out') then raise exception 'Invalid stock state'; end if;
 if p_supplier is not null and a.role<>'owner' then raise exception 'Supplier filter is Owner-only'; end if;
 with base as(
  select c.id,c.item_code,c.oem_code,c.name,c.item_type,c.brand,c.category,c.model,i.current_qty,i.reorder_level,i.updated_at,case when i.current_qty<=0 then 'out' when i.current_qty<=i.reorder_level then 'low' else 'ok' end stock_state
  from inventory i join catalog_items c on c.id=i.item_id
  where c.active=true and (p_state='all' or (p_state='out' and i.current_qty<=0) or (p_state='low' and i.current_qty>0 and i.current_qty<=i.reorder_level))
   and(nullif(trim(coalesce(p_brand,'')),'') is null or lower(coalesce(c.brand,''))=lower(trim(p_brand))) and(nullif(trim(coalesce(p_category,'')),'') is null or lower(coalesce(c.category,''))=lower(trim(p_category)))
   and(s='' or lower(coalesce(c.item_code,'')) like '%'||s||'%' or lower(coalesce(c.oem_code,'')) like '%'||s||'%' or lower(coalesce(c.name,'')) like '%'||s||'%' or lower(coalesce(c.brand,'')) like '%'||s||'%' or lower(coalesce(c.model,'')) like '%'||s||'%')
 ),enriched as(
  select b.*,
   case when a.role in('owner','admin') then lp.invoice_no else null end last_purchase_invoice,
   case when a.role in('owner','admin') then lp.invoice_date else null end last_purchase_date,
   case when a.role='owner' then lp.supplier_name else null end last_supplier,
   case when a.role='owner' then lp.supplier_id else null end last_supplier_id,
   case when a.role='owner' then lp.purchase_rate else null end last_purchase_rate,
   case when a.role in('owner','admin') then lp.invoice_no else null end source_reference
  from base b left join lateral(
   select h.invoice_no,h.invoice_date,h.supplier_id,sup.supplier_name,l.purchase_rate
   from purchase_lines l join purchase_headers h on h.id=l.purchase_id left join suppliers sup on sup.id=h.supplier_id
   where l.item_id=b.id and not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED')
   order by h.invoice_date desc,h.created_at desc limit 1
  )lp on true
  where p_supplier is null or lp.supplier_id=p_supplier
  order by case b.stock_state when 'out' then 0 else 1 end,b.current_qty asc,b.item_code limit lim
 )
 select jsonb_build_object('rows',coalesce(jsonb_agg(to_jsonb(enriched)),'[]'::jsonb),'financial_visibility',case when a.role='owner' then 'owner_purchase_source_and_rate' when a.role='admin' then 'source_without_rate' else 'stock_only' end) into r from enriched;
 return coalesce(r,jsonb_build_object('rows','[]'::jsonb,'financial_visibility',case when a.role='owner' then 'owner_purchase_source_and_rate' when a.role='admin' then 'source_without_rate' else 'stock_only' end));
end;$$;
revoke all on function get_low_stock_drilldown(text,text,text,text,uuid,integer) from public,anon;
grant execute on function get_low_stock_drilldown(text,text,text,text,uuid,integer) to authenticated;

-- Owner-only supplier facet for Low Stock. This keeps supplier identity out of Admin/Store Keeper clients.
create or replace function get_low_stock_supplier_options()
returns table(id uuid,supplier_name text) language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner required'; end if;
 return query select s.id,s.supplier_name from suppliers s where coalesce(s.active,true)=true order by s.supplier_name;
end;$$;
revoke all on function get_low_stock_supplier_options() from public,anon;
grant execute on function get_low_stock_supplier_options() to authenticated;
