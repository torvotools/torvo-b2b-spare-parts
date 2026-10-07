-- TORVO V2 role-safe Reports Center summary.
create or replace function get_report_summary() returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r jsonb:='{}'::jsonb;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant','store_keeper') then raise exception 'Not authorized for reports';end if;
 if a.role in('owner','admin','accountant') then
  r:=r||jsonb_build_object(
   'sales_total',(select coalesce(sum(e.final_payable),0) from sales_documents e join marg_bill_sales s on s.estimate_id=e.id where e.doc_type='estimate' and s.status='posted'),
   'estimate_count',(select count(*) from sales_documents where doc_type='estimate'),
   'sales_order_count',(select count(*) from sales_documents where doc_type='sales_order'),
   'posted_sale_count',(select count(*) from marg_bill_sales where status='posted'),
   'payment_received',(select coalesce(sum(amount),0) from payments where status in('cash','received')),
   'payment_outstanding',(select coalesce(sum(greatest(coalesce(e.final_payable,0)-coalesce((select sum(p.amount) from payments p where p.estimate_id=e.id and p.status in('cash','received')),0),0)),0) from sales_documents e join marg_bill_sales s on s.estimate_id=e.id where e.doc_type='estimate' and s.status='posted')
  );
 end if;
 if a.role in('owner','admin') then
  r:=r||jsonb_build_object(
   'query_count',(select count(*) from sales_documents where doc_type='query'),
   'quotation_count',(select count(*) from sales_documents where doc_type='sales_order'),
   'accepted_quotation_count',(select count(*) from sales_documents where doc_type='sales_order' and status in('dealer_ok','confirmed','final','approved')),
   'dealer_ok_sales_order_count',(select count(*) from sales_documents where doc_type='sales_order' and dealer_ok_at is not null),
   'active_dealers',(select count(*) from dealers where status='approved'),
   'inactive_dealers',(select count(*) from dealers where status in('inactive','suspended')),
   'catalog_items',(select count(*) from catalog_items where active=true),
   'sold_qty',(select coalesce(sum(l.qty),0) from sales_document_lines l join sales_documents e on e.id=l.document_id join marg_bill_sales s on s.estimate_id=e.id where e.doc_type='estimate' and s.status='posted'),
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


-- DEALER 360
-- Owner/Admin consolidated business view. Dealer Service Book contributes aggregates only;
-- customer identity/contact/photo fields are intentionally excluded.
create or replace function public.get_dealer_360(p_dealer uuid)
returns jsonb
language plpgsql stable security definer set search_path=public as $$
declare a public.app_users%rowtype;d public.dealers%rowtype;r jsonb;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or lower(coalesce(a.role,'')) not in('owner','admin') then raise exception 'Owner/Admin authorization required';end if;
 select * into d from public.dealers where id=p_dealer;
 if not found then raise exception 'Dealer not found';end if;

 select jsonb_build_object(
  'dealer',jsonb_build_object(
    'id',d.id,'dealer_code',d.dealer_code,'shop_name',d.shop_name,'contact_person',d.contact_person,
    'city',d.city,'district',d.district,'state',d.state,'pin_code',d.pin_code,
    'rate_group',d.rate_group,'status',d.status,'approved_at',d.approved_at,
    'accountant_verification_status',d.accountant_verification_status,
    'inactivity_warning_at',d.inactivity_warning_at,'suspended_at',d.suspended_at
  ),
  'sales',jsonb_build_object(
    'po_count',(select count(*) from public.sales_documents x where x.dealer_id=d.id and x.doc_type='query'),
    'estimate_count',(select count(*) from public.sales_documents x where x.dealer_id=d.id and x.doc_type='estimate'),
    'posted_sales_count',(select count(distinct x.id) from public.sales_documents x join public.marg_bill_sales m on m.estimate_id=x.id and m.status in('posted','corrected') where x.dealer_id=d.id and x.doc_type='estimate'),
    'delivered_sales_count',(select count(distinct x.id) from public.sales_documents x join public.dispatches dp on dp.estimate_id=x.id and dp.status='delivered' where x.dealer_id=d.id and x.doc_type='estimate'),
    'delivered_sales_value',(select coalesce(sum(x.final_payable),0) from public.sales_documents x where x.dealer_id=d.id and x.doc_type='estimate' and exists(select 1 from public.dispatches dp where dp.estimate_id=x.id and dp.status='delivered')),
    'last_document_at',(select max(x.created_at) from public.sales_documents x where x.dealer_id=d.id)
  ),
  'demand',jsonb_build_object(
    'missing_part_requests',(select count(*) from public.missing_part_requests x where x.dealer_id=d.id),
    'open_missing_part_requests',(select count(*) from public.missing_part_requests x where x.dealer_id=d.id and lower(coalesce(x.status,'')) not in('closed','resolved','rejected','cancelled')),
    'non_available_requests',(select count(*) from public.non_available_requests x where x.dealer_id=d.id),
    'requested_qty',(select coalesce(sum(x.requested_qty),0) from public.missing_part_requests x where x.dealer_id=d.id)
      +(select coalesce(sum(x.qty),0) from public.non_available_requests x where x.dealer_id=d.id)
  ),
  'service_book',jsonb_build_object(
    'jobs_total',(select count(*) from public.dealer_service_jobs j where j.dealer_id=d.id),
    'jobs_last_90_days',(select count(*) from public.dealer_service_jobs j where j.dealer_id=d.id and j.created_at>=now()-interval '90 days'),
    'last_job_at',(select max(j.created_at) from public.dealer_service_jobs j where j.dealer_id=d.id),
    'parts_used_qty',(select coalesce(sum(p.qty),0) from public.dealer_service_job_parts p join public.dealer_service_jobs j on j.id=p.job_id where j.dealer_id=d.id)
  ),
  'activity',jsonb_build_object(
    'last_business_activity_at',nullif(greatest(
      coalesce((select max(x.created_at) from public.sales_documents x where x.dealer_id=d.id),'-infinity'::timestamptz),
      coalesce((select max(x.created_at) from public.missing_part_requests x where x.dealer_id=d.id),'-infinity'::timestamptz),
      coalesce((select max(x.created_at) from public.non_available_requests x where x.dealer_id=d.id),'-infinity'::timestamptz),
      coalesce((select max(j.created_at) from public.dealer_service_jobs j where j.dealer_id=d.id),'-infinity'::timestamptz)
    ),'-infinity'::timestamptz)
  ),
  'privacy',jsonb_build_object('service_customer_details_exposed',false,'financial_payment_rows_exposed',false)
 ) into r;
 return r;
end;$$;
revoke all on function public.get_dealer_360(uuid) from public,anon;
grant execute on function public.get_dealer_360(uuid) to authenticated;
