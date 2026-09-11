-- TORVO V2 dealer-facing machine spare-parts shopping view.
-- Internal compatibility tables/notes remain owner/admin only.
-- Dealer receives only active sellable spare-part identity fields required to send a query.
create or replace function get_dealer_machine_spares(p_machine uuid)
returns table(
  id uuid,
  item_code text,
  name text,
  brand text,
  category text,
  model text,
  image_url text,
  required_qty numeric
)
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role<>'dealer' or a.dealer_id is null then raise exception 'Approved dealer login required';end if;
  if not exists(select 1 from dealers where id=a.dealer_id and status='approved') then raise exception 'Approved dealer required';end if;
  if not exists(select 1 from catalog_items where id=p_machine and item_type='machine' and active=true) then raise exception 'Active machine required';end if;
  return query
    select distinct on(s.id) s.id,s.item_code,s.name,s.brand,s.category,s.model,s.image_url,m.required_qty
    from machine_spare_mapping m
    join catalog_items s on s.id=m.spare_part_id
    where m.machine_id=p_machine and s.item_type='spare_part' and s.active=true
    order by s.id,case m.fitment_type when 'oem' then 1 when 'compatible' then 2 else 3 end;
end;$$;
revoke all on function get_dealer_machine_spares(uuid) from public,anon;
grant execute on function get_dealer_machine_spares(uuid) to authenticated;
