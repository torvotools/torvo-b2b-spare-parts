-- TORVO V2 RLS: store-safe operational access patch.
create or replace function get_store_fulfilment_queue()
returns table(dispatch_id uuid,estimate_id uuid,dispatch_status text,tracking_code text,stock_deducted_at timestamptz,dealer_id uuid,item_id uuid,qty numeric,item_code text,item_name text,item_type text,brand text,model text)
language plpgsql stable security definer set search_path=public as $$
declare v_role text;
begin
 select role into v_role from app_users where auth_user_id=auth.uid() and active=true;
 if v_role not in ('owner','admin','store_keeper') then raise exception 'Not authorized'; end if;
 return query select d.id,d.estimate_id,d.status,d.tracking_code,d.stock_deducted_at,s.dealer_id,dl.item_id,dl.qty,c.item_code,c.name,c.item_type,c.brand,c.model from dispatches d join sales_documents s on s.id=d.estimate_id join sales_document_lines dl on dl.document_id=s.id join catalog_items c on c.id=dl.item_id order by d.status,s.created_at;
end;$$;
revoke all on function get_store_fulfilment_queue() from public,anon;
grant execute on function get_store_fulfilment_queue() to authenticated;
