-- TORVO V2 Item Movement Center.
-- Real purchase/sales/inventory movement drilldown; no duplicated history.
-- Purchase rates and supplier details are Owner-only. Store Keeper never receives financial fields.
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
   select h.created_at event_at,'purchase'::text kind,'PURCHASE'::text movement_type,l.qty qty_change,h.invoice_no reference_no,
     case when a.role='owner' then s.supplier_name else null end party,
     case when a.role='owner' then l.purchase_rate else null end rate,
     case when a.role='owner' then l.line_amount else null end amount,h.id reference_id
   from purchase_lines l join purchase_headers h on h.id=l.purchase_id left join suppliers s on s.id=h.supplier_id
   where l.item_id=p_item and not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED')
   union all
   select coalesce(dp.delivered_at,e.created_at),'sale','SALE',-sl.qty,coalesce(e.final_sale_serial::text,e.id::text),
     case when a.role in('owner','admin') then d.shop_name else null end,
     case when a.role in('owner','admin') then sl.rate else null end,
     case when a.role in('owner','admin') then sl.amount else null end,e.id
   from sales_document_lines sl join sales_documents e on e.id=sl.document_id join dispatches dp on dp.estimate_id=e.id and dp.status='delivered' left join dealers d on d.id=e.dealer_id
   where sl.item_id=p_item and e.doc_type='estimate'
   union all
   select m.created_at,'movement',m.movement_type,m.qty,m.reference_id::text,m.note,null,null,m.reference_id
   from inventory_movements m where m.item_id=p_item and m.movement_type not in('purchase')
 ),filtered as(select * from events where(p_from is null or event_at>=p_from) and(p_to is null or event_at<p_to) and(p_kind='all' or kind=p_kind) order by event_at desc limit lim),summary as(select coalesce(sum(case when kind='purchase' and qty_change>0 then qty_change else 0 end),0) purchased_qty,coalesce(sum(case when kind='sale' and qty_change<0 then -qty_change else 0 end),0) sold_qty,max(event_at) last_movement_at from events)
 select jsonb_build_object('item',jsonb_build_object('id',c.id,'item_code',c.item_code,'oem_code',c.oem_code,'name',c.name,'item_type',c.item_type,'brand',c.brand,'category',c.category,'model',c.model,'active',c.active),'stock',jsonb_build_object('current_qty',coalesce(i.current_qty,0),'reorder_level',coalesce(i.reorder_level,0),'updated_at',i.updated_at),'summary',(select to_jsonb(summary) from summary),'events',coalesce((select jsonb_agg(to_jsonb(filtered) order by event_at desc) from filtered),'[]'::jsonb),'financial_visibility',case when a.role='owner' then 'owner_purchase_and_sales' when a.role='admin' then 'sales_only' else 'none' end) into result;
 return result;
end;$$;
revoke all on function get_item_movement_center(uuid,timestamptz,timestamptz,text,integer) from public,anon;
grant execute on function get_item_movement_center(uuid,timestamptz,timestamptz,text,integer) to authenticated;
