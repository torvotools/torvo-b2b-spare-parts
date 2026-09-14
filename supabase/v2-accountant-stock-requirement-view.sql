-- TORVO V2 ACCOUNTANT STOCK / NO STOCK VIEW. READ-ONLY STOCK; REQUIREMENT SUBMISSION USES EXISTING CENTRAL PURCHASE REQUIREMENTS RPC.
create or replace function accountant_stock_requirement_view()
returns table(item_id uuid,item_code text,item_name text,brand text,model text,current_qty numeric,reorder_level numeric,stock_status text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('accountant','owner','admin') then raise exception 'ACCOUNTANT / OWNER / ADMIN REQUIRED'; end if;
 return query
 select i.item_id,c.item_code,c.name,c.brand,c.model,i.current_qty,i.reorder_level,
   case when coalesce(i.current_qty,0)<=0 then 'NO STOCK' when coalesce(i.current_qty,0)<=coalesce(i.reorder_level,0) then 'LOW STOCK' else 'STOCK OK' end
 from inventory i join catalog_items c on c.id=i.item_id
 where c.active=true
 order by case when coalesce(i.current_qty,0)<=0 then 0 when coalesce(i.current_qty,0)<=coalesce(i.reorder_level,0) then 1 else 2 end,c.name;
end;$$;
revoke all on function accountant_stock_requirement_view() from public,anon;
grant execute on function accountant_stock_requirement_view() to authenticated;
