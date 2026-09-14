-- TORVO V2 dealer-facing machine spare-parts view bound to the single active Dealer device.
-- Internal compatibility tables/notes remain owner/admin only.
create or replace function get_dealer_machine_spares(p_device_id text,p_session_token text,p_machine uuid)
returns table(id uuid,item_code text,name text,brand text,category text,model text,image_url text,required_qty numeric)
language plpgsql security definer set search_path=public as $$
declare v_dealer_id uuid;begin
 v_dealer_id:=public.dealer_assert_my_device_session(p_device_id,p_session_token);
 if not exists(select 1 from catalog_items where id=p_machine and item_type='machine' and active=true) then raise exception 'ACTIVE MACHINE REQUIRED';end if;
 return query select distinct on(s.id) s.id,s.item_code,s.name,s.brand,s.category,s.model,s.image_url,m.required_qty from machine_spare_mapping m join catalog_items s on s.id=m.spare_part_id where m.machine_id=p_machine and m.dealer_visible=true and s.item_type='spare_part' and s.active=true order by s.id,case m.fitment_type when 'oem' then 1 when 'compatible' then 2 else 3 end;
end;$$;
drop function if exists get_dealer_machine_spares(uuid);
revoke all on function get_dealer_machine_spares(text,text,uuid) from public,anon;grant execute on function get_dealer_machine_spares(text,text,uuid) to authenticated;
