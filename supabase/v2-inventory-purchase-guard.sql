-- TORVO V2 inventory/purchase safety cutover.
-- Prevents supplier stock from entering outside Purchase Entry.
-- Reorder remains planning. Manual adjustment is correction-only and cannot impersonate supplier receipt.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

create or replace function receive_reorder(p_reorder uuid,p_received_qty numeric) returns numeric
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r stock_reorder_requests%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found then raise exception 'Active user required'; end if;
 if a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized'; end if;
 select * into r from stock_reorder_requests where id=p_reorder;
 if not found then raise exception 'Reorder request not found'; end if;
 raise exception 'Direct reorder stock receipt is retired. Owner/Admin must receive supplier stock through Purchase Entry, then link fulfilment to the requirement/reorder.';
end;$$;
revoke all on function receive_reorder(uuid,numeric) from public,anon;
grant execute on function receive_reorder(uuid,numeric) to authenticated;

-- Supersedes the legacy operations RPC. Manual stock adjustment is now Owner/Admin only.
-- Positive correction requires explicit acknowledgement and is deliberately capped so this path cannot become a shadow Purchase Entry.
create or replace function adjust_inventory(p_item uuid,p_qty_change numeric,p_reason text) returns numeric
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v numeric;reason text;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required for manual stock correction'; end if;
 reason:=nullif(trim(p_reason),'');
 if p_qty_change is null or p_qty_change=0 or reason is null then raise exception 'Quantity change and reason required'; end if;
 if abs(p_qty_change)>100 then raise exception 'Large stock correction blocked. Verify physical stock and use the correct Purchase/transaction workflow.'; end if;
 if p_qty_change>0 and position('[NON-PURCHASE CORRECTION]' in upper(reason))=0 then raise exception 'Positive manual correction requires explicit NON-PURCHASE CORRECTION acknowledgement'; end if;
 if p_qty_change>0 and (upper(reason) like '%SUPPLIER%' or upper(reason) like '%PURCHASE%' or upper(reason) like '%INVOICE%' or upper(reason) like '%RECEIPT%' or upper(reason) like '%REORDER%') then raise exception 'Supplier/Purchase receipt cannot use manual adjustment. Use Purchase Entry.'; end if;
 perform 1 from inventory where item_id=p_item for update;
 if not found then raise exception 'Inventory item not found'; end if;
 select current_qty+p_qty_change into v from inventory where item_id=p_item;
 if v<0 then raise exception 'Stock cannot become negative'; end if;
 update inventory set current_qty=v,updated_at=now() where item_id=p_item;
 insert into inventory_movements(item_id,qty_change,reason,reference_type,created_by) values(p_item,p_qty_change,reason,'manual_correction',a.id);
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'INVENTORY_MANUAL_CORRECTION','catalog_item',p_item::text,jsonb_build_object('qty_change',p_qty_change,'reason',reason,'new_qty',v,'purchase_receipt',false));
 return v;
end;$$;
revoke all on function adjust_inventory(uuid,numeric,text) from public,anon;
grant execute on function adjust_inventory(uuid,numeric,text) to authenticated;

-- Explicit read helper for Store/Owner/Admin. No purchase rate, supplier invoice total or financial fields are returned.
create or replace function get_inventory_reorder_queue() returns table(
 id uuid,item_id uuid,item_code text,item_name text,brand text,model text,required_qty numeric,received_qty numeric,status text,created_at timestamptz
)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized'; end if;
 return query
 select r.id,r.item_id,c.item_code,c.name,c.brand,c.model,r.required_qty,coalesce(r.received_qty,0),r.status,r.created_at
 from stock_reorder_requests r join catalog_items c on c.id=r.item_id
 order by case r.status when 'submitted' then 1 when 'ordered' then 2 when 'received' then 3 else 4 end,r.created_at desc;
end;$$;
revoke all on function get_inventory_reorder_queue() from public,anon;
grant execute on function get_inventory_reorder_queue() to authenticated;
