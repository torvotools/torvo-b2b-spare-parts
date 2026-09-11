-- TORVO V2 role-safe Reports Center summary.
create or replace function get_report_summary() returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r jsonb:='{}'::jsonb;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Not authorized for reports'; end if;
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
   'quotation_count',(select count(*) from sales_documents where doc_type='quotation'),
   'accepted_quotation_count',(select count(*) from sales_documents where doc_type='quotation' and status in('accepted','converted')),
   'active_dealers',(select count(*) from dealers where status='approved'),
   'scheme_count',(select count(*) from schemes),
   'missing_open',(select count(*) from non_available_requests where status<>'closed'),
   'missing_total',(select count(*) from non_available_requests),
   'audit_count',(select count(*) from audit_log)
  );
 end if;
 if a.role in('owner','admin','store_keeper') then
  r:=r||jsonb_build_object(
   'inventory_items',(select count(*) from inventory),
   'low_stock',(select count(*) from inventory where current_qty>0 and current_qty<=reorder_level),
   'out_stock',(select count(*) from inventory where current_qty<=0),
   'reorder_open',(select count(*) from stock_reorder_requests where status in('submitted','ordered')),
   'dispatch_pending',(select count(*) from dispatches where status<>'delivered')
  );
 end if;
 return r;
end;$$;
revoke all on function get_report_summary() from public,anon;grant execute on function get_report_summary() to authenticated;
