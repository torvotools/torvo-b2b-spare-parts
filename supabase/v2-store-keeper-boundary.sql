alter table public.dispatches add column if not exists courier_company text;

-- TORVO V2 STORE KEEPER SERVER BOUNDARY
-- STORE KEEPER GETS ONLY RATE-FREE FULFILMENT DATA AND STAGE ACTIONS.
-- FINANCIAL VERIFICATION REMAINS SERVER-SIDE; NO RATE/PAYMENT AMOUNTS ARE RETURNED.

create or replace function get_store_fulfilment_queue()
returns table(dispatch_id uuid,estimate_id uuid,dispatch_status text,tracking_code text,courier_company text,item_id uuid,item_code text,name text,qty numeric)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin','store_keeper') then raise exception 'STORE ACCESS REQUIRED';end if;
 return query
 select d.id,d.estimate_id,d.status,d.tracking_code,d.courier_company,l.item_id,c.item_code,c.name,l.qty
 from dispatches d join sales_documents e on e.id=d.estimate_id and e.doc_type='estimate'
 join sales_document_lines l on l.document_id=e.id join catalog_items c on c.id=l.item_id
 where d.status in('pick_list','picked','packed','ready_for_dispatch','delivered')
 order by case d.status when 'pick_list' then 1 when 'picked' then 2 when 'packed' then 3 when 'ready_for_dispatch' then 4 else 5 end,d.created_at,l.id;
end$$;
revoke all on function get_store_fulfilment_queue() from public,anon;grant execute on function get_store_fulfilment_queue() to authenticated;

drop function if exists advance_dispatch(uuid,text,text);
create or replace function advance_dispatch(p_estimate uuid,p_status text,p_tracking_code text default null,p_courier_company text default null)
returns void language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;d dispatches%rowtype;v_next text;v_tracking text;v_courier text;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin','store_keeper') then raise exception 'STORE ACCESS REQUIRED';end if;
 select * into d from dispatches where estimate_id=p_estimate for update;if d.id is null then raise exception 'DISPATCH NOT FOUND';end if;
 if d.status='delivered' then raise exception 'DELIVERY ALREADY COMPLETED';end if;
 v_next:=case d.status when 'pick_list' then 'picked' when 'picked' then 'packed' when 'packed' then 'ready_for_dispatch' else null end;
 if v_next is null or p_status<>v_next then raise exception 'INVALID DISPATCH STAGE';end if;
 v_tracking:=nullif(upper(btrim(coalesce(p_tracking_code,''))), '');
 v_courier:=nullif(upper(btrim(coalesce(p_courier_company,''))), '');
 if p_status='ready_for_dispatch' and v_courier is null and nullif(btrim(coalesce(d.courier_company,'')),'') is null then raise exception 'COURIER / TRANSPORT COMPANY REQUIRED';end if;
 if p_status='ready_for_dispatch' and v_tracking is null and nullif(btrim(coalesce(d.tracking_code,'')),'') is null then raise exception 'TRACKING / DISPATCH CODE REQUIRED';end if;
 update dispatches set status=p_status,tracking_code=case when p_status='ready_for_dispatch' then coalesce(v_tracking,tracking_code) else tracking_code end,courier_company=case when p_status='ready_for_dispatch' then coalesce(v_courier,courier_company) else courier_company end,updated_by=u.id where id=d.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'DISPATCH_STAGE_CHANGED','dispatch',d.id::text,jsonb_build_object('from',d.status,'to',p_status,'estimate_id',p_estimate,'courier_company',case when p_status='ready_for_dispatch' then coalesce(v_courier,d.courier_company) else d.courier_company end));
end$$;
revoke all on function advance_dispatch(uuid,text,text,text) from public,anon;grant execute on function advance_dispatch(uuid,text,text,text) to authenticated;

-- Direct financial tables are not part of Store Keeper UI/API contract.
-- Sale/Dispatch/Delivery are payment-independent. Payment remains accounting/history only.
