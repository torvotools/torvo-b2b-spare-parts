-- TORVO V2 inventory/purchase safety cutover.
-- Prevents the legacy reorder receive RPC from creating stock outside Purchase Entry.
-- Reorder remains a demand/order-planning workflow. Supplier invoice receipt is authoritative.
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
