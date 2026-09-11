-- TORVO V2 role-safe detailed report rows for UI/export.
create or replace function get_report_detail(p_report text,p_from timestamptz default null,p_to timestamptz default null) returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r jsonb:='[]'::jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Not authorized for reports';end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid report date range';end if;
 if p_report='sales' then
  if a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(
   select e.id,e.created_at,d.dealer_code,d.shop_name,e.subtotal,e.freight,e.other_charges,e.final_payable,dp.delivered_at
   from sales_documents e join dealers d on d.id=e.dealer_id join dispatches dp on dp.estimate_id=e.id
   where e.doc_type='estimate' and dp.status='delivered' and(p_from is null or e.created_at>=p_from) and(p_to is null or e.created_at<p_to)
  )x;
 elsif p_report='inventory' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.item_code),'[]'::jsonb) into r from(
   select c.item_code,c.name,c.item_type,c.brand,c.category,c.model,i.current_qty,i.reorder_level,i.updated_at from inventory i join catalog_items c on c.id=i.item_id
  )x;
 elsif p_report='reorder' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(
   select q.id,q.created_at,c.item_code,c.name,c.brand,c.model,q.required_qty,q.received_qty,q.status from stock_reorder_requests q join catalog_items c on c.id=q.item_id
   where(p_from is null or q.created_at>=p_from) and(p_to is null or q.created_at<p_to)
  )x;
 elsif p_report='dispatch' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(
   select dp.id,e.created_at,d.dealer_code,d.shop_name,dp.status,dp.tracking_code,dp.delivered_at,dp.stock_deducted_at from dispatches dp join sales_documents e on e.id=dp.estimate_id join dealers d on d.id=e.dealer_id
   where(p_from is null or e.created_at>=p_from) and(p_to is null or e.created_at<p_to)
  )x;
 elsif p_report='opportunity' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(
   select n.id,n.created_at,d.dealer_code,d.shop_name,n.search_text,n.item_type,n.qty,n.status from non_available_requests n left join dealers d on d.id=n.dealer_id
   where(p_from is null or n.created_at>=p_from) and(p_to is null or n.created_at<p_to)
  )x;
 elsif p_report='audit' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(
   select l.id,l.created_at,u.full_name actor,l.action,l.entity_type,l.entity_id,l.details from audit_log l left join app_users u on u.id=l.actor_id
   where(p_from is null or l.created_at>=p_from) and(p_to is null or l.created_at<p_to) limit 1000
  )x;
 else raise exception 'Detailed report not implemented for %',p_report;
 end if;
 return r;
end;$$;
revoke all on function get_report_detail(text,timestamptz,timestamptz) from public,anon;grant execute on function get_report_detail(text,timestamptz,timestamptz) to authenticated;
