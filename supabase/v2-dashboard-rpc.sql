-- TORVO V2 role-safe dashboard. Returns only metrics appropriate to the authenticated role.
create or replace function get_dashboard_metrics() returns jsonb language plpgsql stable security definer set search_path=public as $$declare a app_users%rowtype;r jsonb:='{}'::jsonb;begin
select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role='dealer' then raise exception 'Internal active user required';end if;
if a.role in('owner','admin','salesman') then r:=r||jsonb_build_object('queries',(select count(*) from sales_documents where doc_type='query'),'estimates',(select count(*) from sales_documents where doc_type='estimate'));end if;
if a.role in('owner','admin','salesman') then r:=r||jsonb_build_object('active_dealers',(select count(*) from dealers where status='approved'));end if;
if a.role in('owner','admin') then r:=r||jsonb_build_object('dealer_requests',(select count(*) from dealers where status='pending'));end if;
if a.role in('owner','admin','store_keeper') then r:=r||jsonb_build_object('low_stock',(select count(*) from inventory where current_qty<=reorder_level),'dispatch_pending',(select count(*) from dispatches where status<>'delivered'));end if;
if a.role in('owner','admin','accountant') then r:=r||jsonb_build_object('payment_pending',(select count(*) from sales_documents e where e.doc_type='estimate' and coalesce((select sum(p.amount) from payments p where p.estimate_id=e.id and p.status in('cash','received')),0)<coalesce(e.final_payable,0)),'total_sales',(select coalesce(sum(e.final_payable),0) from sales_documents e where e.doc_type='estimate' and exists(select 1 from dispatches d where d.estimate_id=e.id and d.status='delivered' and d.delivered_at is not null)),'delivered_sales_count',(select count(*) from sales_documents e where e.doc_type='estimate' and exists(select 1 from dispatches d where d.estimate_id=e.id and d.status='delivered' and d.delivered_at is not null)));end if;
return r;end;$$;
revoke all on function get_dashboard_metrics() from public,anon;grant execute on function get_dashboard_metrics() to authenticated;


-- OWNER EXCEPTION CENTER
-- Read-only priority feed over existing authoritative modules. No workflow state is changed here.
create or replace function public.get_owner_exception_center(p_limit integer default 100)
returns table(priority text,exception_type text,title text,detail text,entity_type text,entity_id text,occurred_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
declare a public.app_users%rowtype;
begin
 select * into a from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or lower(coalesce(a.role,''))<>'owner' then raise exception 'Owner authorization required';end if;
 return query
 with stock as(
   select
    case when s.stock_class='ZERO STOCK + DEMAND' then 'CRITICAL' else 'HIGH' end pr,
    'STOCK' typ,
    case when s.stock_class='ZERO STOCK + DEMAND' then 'ZERO STOCK + DEMAND' else 'REORDER REQUIRED' end ttl,
    concat_ws(' | ',s.item_code,s.item_name,'STOCK '||s.current_qty::text,'SUGGESTED '||s.suggested_reorder_qty::text) det,
    'catalog_item' et,s.item_id::text eid,coalesce(s.last_sale_at,s.last_movement_at,now()) ts
   from public.get_smart_stock_intelligence(90,200) s
   where s.stock_class in('ZERO STOCK + DEMAND','REORDER NOW')
 ),approvals as(
   select 'HIGH','APPROVAL','PENDING APPROVAL',
    concat_ws(' | ',r.module,r.action_type,r.summary),'approval_request',r.id::text,r.created_at
   from public.approval_requests r where lower(coalesce(r.status,''))='pending'
 ),dispatch as(
   select case when d.status='ready_for_dispatch' and d.updated_at<now()-interval '48 hours' then 'HIGH' else 'MEDIUM' end,
    'DISPATCH','DISPATCH NEEDS ATTENTION',
    concat_ws(' | ','STATUS '||upper(coalesce(d.status,'')),nullif(d.courier_company,''),nullif(d.tracking_code,'')),
    'dispatch',d.id::text,d.updated_at
   from public.dispatches d
   where d.status<>'delivered' and d.updated_at<now()-interval '24 hours'
 ),backup as(
   select 'CRITICAL','BACKUP','BACKUP FAILED OR UNVERIFIED',
    concat_ws(' | ',upper(coalesce(b.status,'')),nullif(b.error_message,'')),
    'backup_run',b.id::text,coalesce(b.completed_at,b.started_at,b.requested_at)
   from public.backup_runs b
   where lower(coalesce(b.status,'')) in('failed','error')
      or (lower(coalesce(b.status,'')) in('completed','success') and b.verified_at is null)
 ),notes as(
   select 'MEDIUM','NOTIFICATION',upper(coalesce(n.title,'UNREAD NOTIFICATION')),
    coalesce(n.body,''),'notification',n.id::text,n.created_at
   from public.notifications n
   where n.user_id=a.id and n.read_at is null
 )
 select x.pr,x.typ,x.ttl,x.det,x.et,x.eid,x.ts
 from(
   select * from stock union all select * from approvals union all select * from dispatch union all select * from backup union all select * from notes
 )x
 order by case x.pr when 'CRITICAL' then 1 when 'HIGH' then 2 else 3 end,x.ts asc
 limit greatest(1,least(coalesce(p_limit,100),300));
end;$$;
revoke all on function public.get_owner_exception_center(integer) from public,anon;
grant execute on function public.get_owner_exception_center(integer) to authenticated;
