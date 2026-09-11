-- TORVO V2 role-safe detailed report rows for UI/export.
create or replace function get_report_detail(p_report text,p_from timestamptz default null,p_to timestamptz default null) returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r jsonb:='[]'::jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Not authorized for reports';end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid report date range';end if;
 if p_report='sales' then
  if a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.delivered_at desc),'[]'::jsonb) into r from(select e.id,dp.delivered_at,d.dealer_code,d.shop_name,e.subtotal,e.freight,e.other_charges,e.final_payable from sales_documents e join dealers d on d.id=e.dealer_id join dispatches dp on dp.estimate_id=e.id where e.doc_type='estimate' and dp.status='delivered' and(p_from is null or dp.delivered_at>=p_from) and(p_to is null or dp.delivered_at<p_to))x;
 elsif p_report='order-estimate' then
  if a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.order_created_at desc),'[]'::jsonb) into r from(select so.id sales_order_id,so.created_at order_created_at,d.dealer_code,d.shop_name,so.subtotal order_subtotal,e.id estimate_id,e.created_at estimate_created_at,e.subtotal estimate_subtotal,e.freight,e.other_charges,e.final_payable,(coalesce(e.final_payable,0)-coalesce(so.subtotal,0)) variance from sales_documents so join dealers d on d.id=so.dealer_id left join sales_documents e on e.parent_id=so.id and e.doc_type='estimate' where so.doc_type='sales_order' and(p_from is null or so.created_at>=p_from) and(p_to is null or so.created_at<p_to))x;
 elsif p_report='outstanding' then
  if a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.age_days desc),'[]'::jsonb) into r from(select e.id estimate_id,e.created_at,d.dealer_code,d.shop_name,e.final_payable,coalesce(sum(p.amount) filter(where p.status in('cash','received')),0) received,greatest(coalesce(e.final_payable,0)-coalesce(sum(p.amount) filter(where p.status in('cash','received')),0),0) outstanding,(current_date-e.created_at::date) age_days,case when current_date-e.created_at::date<=30 then '0-30' when current_date-e.created_at::date<=60 then '31-60' else '61+' end aging_bucket from sales_documents e join dealers d on d.id=e.dealer_id left join payments p on p.estimate_id=e.id where e.doc_type='estimate' and(p_from is null or e.created_at>=p_from) and(p_to is null or e.created_at<p_to) group by e.id,e.created_at,d.dealer_code,d.shop_name,e.final_payable having greatest(coalesce(e.final_payable,0)-coalesce(sum(p.amount) filter(where p.status in('cash','received')),0),0)>0)x;
 elsif p_report='dealer' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.delivered_sales desc,x.shop_name),'[]'::jsonb) into r from(select d.id,d.dealer_code,d.shop_name,d.status,count(distinct e.id) filter(where dp.status='delivered') delivered_orders,coalesce(sum(e.final_payable) filter(where dp.status='delivered'),0) delivered_sales,max(dp.delivered_at) last_delivery from dealers d left join sales_documents e on e.dealer_id=d.id and e.doc_type='estimate' left join dispatches dp on dp.estimate_id=e.id and(p_from is null or dp.delivered_at>=p_from) and(p_to is null or dp.delivered_at<p_to) group by d.id,d.dealer_code,d.shop_name,d.status)x;
 elsif p_report='product' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.delivered_sales desc,x.item_code),'[]'::jsonb) into r from(select c.id,c.item_code,c.name,c.item_type,c.brand,c.category,c.model,coalesce(sum(l.qty) filter(where dp.status='delivered'),0) delivered_qty,coalesce(sum(l.qty*coalesce(l.rate,0)) filter(where dp.status='delivered'),0) delivered_sales,count(distinct e.id) filter(where dp.status='delivered') delivered_orders from catalog_items c left join sales_document_lines l on l.item_id=c.id left join sales_documents e on e.id=l.document_id and e.doc_type='estimate' left join dispatches dp on dp.estimate_id=e.id and(p_from is null or dp.delivered_at>=p_from) and(p_to is null or dp.delivered_at<p_to) group by c.id,c.item_code,c.name,c.item_type,c.brand,c.category,c.model)x;
 elsif p_report='inventory' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.item_code),'[]'::jsonb) into r from(select c.item_code,c.name,c.item_type,c.brand,c.category,c.model,i.current_qty,i.reorder_level,i.updated_at from inventory i join catalog_items c on c.id=i.item_id)x;
 elsif p_report='reorder' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(select q.id,q.created_at,c.item_code,c.name,c.brand,c.model,q.required_qty,q.received_qty,q.status from stock_reorder_requests q join catalog_items c on c.id=q.item_id where(p_from is null or q.created_at>=p_from) and(p_to is null or q.created_at<p_to))x;
 elsif p_report='dispatch' then
  if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(select dp.id,e.created_at,d.dealer_code,d.shop_name,dp.status,dp.tracking_code,dp.delivered_at,dp.stock_deducted_at from dispatches dp join sales_documents e on e.id=dp.estimate_id join dealers d on d.id=e.dealer_id where(p_from is null or e.created_at>=p_from) and(p_to is null or e.created_at<p_to))x;
 elsif p_report='scheme' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.progress_value desc),'[]'::jsonb) into r from(select s.name scheme,d.dealer_code,d.shop_name,s.start_date,s.end_date,p.progress_value,sl.min_value achieved_min,sl.max_value achieved_max,sl.gift_name achieved_gift,sl.points achieved_points from dealer_scheme_progress p join schemes s on s.id=p.scheme_id join dealers d on d.id=p.dealer_id left join scheme_slabs sl on sl.id=p.achieved_slab_id where(p_from is null or s.end_date::timestamptz>=p_from) and(p_to is null or s.start_date::timestamptz<p_to))x;
 elsif p_report='opportunity' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(select n.id,n.created_at,d.dealer_code,d.shop_name,n.search_text,n.item_type,n.qty,n.status from non_available_requests n left join dealers d on d.id=n.dealer_id where(p_from is null or n.created_at>=p_from) and(p_to is null or n.created_at<p_to))x;
 elsif p_report='audit' then
  if a.role not in('owner','admin') then raise exception 'Not authorized';end if;
  select coalesce(jsonb_agg(x order by x.created_at desc),'[]'::jsonb) into r from(select l.id,l.created_at,u.full_name actor,l.action,l.entity_type,l.entity_id,l.details from audit_log l left join app_users u on u.id=l.actor_id where(p_from is null or l.created_at>=p_from) and(p_to is null or l.created_at<p_to) order by l.created_at desc limit 1000)x;
 else raise exception 'Detailed report not implemented for %',p_report;end if;return r;end;$$;
revoke all on function get_report_detail(text,timestamptz,timestamptz) from public,anon;grant execute on function get_report_detail(text,timestamptz,timestamptz) to authenticated;
