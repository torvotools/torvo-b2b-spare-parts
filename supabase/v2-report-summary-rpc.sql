-- TORVO V2 role-safe Reports Center summary.
create or replace function get_report_summary() returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r jsonb:='{}'::jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Not authorized for reports';end if;
 if a.role in('owner','admin','accountant') then
  r:=r||jsonb_build_object(
   'sales_total',(select coalesce(sum(e.final_payable),0) from sales_documents e join dispatches d on d.estimate_id=e.id where e.doc_type='estimate' and d.status='delivered'),
   'estimate_count',(select count(*) from sales_documents where doc_type='estimate'),
   'sales_order_count',(select count(*) from sales_documents where doc_type='sales_order'),
   'payment_received',(select coalesce(sum(amount),0) from payments where status in('cash','received')),
   'payment_outstanding',(select coalesce(sum(greatest(coalesce(e.final_payable,0)-coalesce((select sum(p.amount) from payments p where p.estimate_id=e.id and p.status in('cash','received')),0),0)),0) from sales_documents e where e.doc_type='estimate')
  );
 end if;
 if a.role in('owner','admin') then
  r:=r||jsonb_build_object(
   'query_count',(select count(*) from sales_documents where doc_type='query'),
   'quotation_count',(select count(*) from sales_documents where doc_type='quotation'),
   'accepted_quotation_count',(select count(*) from sales_documents where doc_type='quotation' and status in('accepted','converted')),
   'active_dealers',(select count(*) from dealers where status='approved'),
   'inactive_dealers',(select count(*) from dealers where status in('inactive','suspended')),
   'catalog_items',(select count(*) from catalog_items where active=true),
   'delivered_qty',(select coalesce(sum(l.qty),0) from sales_document_lines l join sales_documents e on e.id=l.document_id join dispatches d on d.estimate_id=e.id where e.doc_type='estimate' and d.status='delivered'),
   'scheme_count',(select count(*) from schemes),
   'scheme_participants',(select count(*) from scheme_dealers),
   'scheme_achieved',(select count(*) from dealer_scheme_progress where achieved_slab_id is not null),
   'reward_points_available',(select coalesce(sum(remaining_points),0) from reward_point_lots where remaining_points>0 and(expires_at is null or expires_at>now())),
   'missing_open',(select count(*) from non_available_requests where status<>'closed'),
   'missing_sourced',(select count(*) from non_available_requests where status='sourced'),
   'missing_total',(select count(*) from non_available_requests),
   'audit_count',(select count(*) from audit_log),
   'audit_users',(select count(distinct actor_id) from audit_log where actor_id is not null)
  );
 end if;
 if a.role in('owner','admin','store_keeper') then
  r:=r||jsonb_build_object(
   'inventory_items',(select count(*) from inventory),
   'inventory_units',(select coalesce(sum(current_qty),0) from inventory),
   'inventory_movements',(select count(*) from inventory_movements),
   'low_stock',(select count(*) from inventory where current_qty>0 and current_qty<=reorder_level),
   'out_stock',(select count(*) from inventory where current_qty<=0),
   'reorder_open',(select count(*) from stock_reorder_requests where status in('submitted','ordered')),
   'reorder_ordered',(select count(*) from stock_reorder_requests where status='ordered'),
   'dispatch_pending',(select count(*) from dispatches where status<>'delivered'),
   'dispatch_ready',(select count(*) from dispatches where status='ready_for_dispatch'),
   'dispatch_delivered',(select count(*) from dispatches where status='delivered')
  );
 end if;
 return r;
end;$$;
revoke all on function get_report_summary() from public,anon;grant execute on function get_report_summary() to authenticated;
