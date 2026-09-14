-- Dealer-safe catalog finder bound to the authenticated Dealer's single active device session.
create or replace function search_dealer_catalog(p_device_id text,p_session_token text,p_search text default null,p_type text default null,p_brand text default null,p_limit integer default 60)
returns table(id uuid,item_type text,item_code text,oem_code text,name text,brand text,category text,model text,image_url text,gst_mode text,current_qty numeric)
language plpgsql stable security definer set search_path=public as $$
declare v_dealer_id uuid;q text:=lower(trim(coalesce(p_search,'')));lim integer:=least(greatest(coalesce(p_limit,60),1),60);begin
 v_dealer_id:=public.dealer_assert_my_device_session(p_device_id,p_session_token);
 if coalesce(p_type,'')<>'' and p_type not in('machine','spare_part','accessory') then raise exception 'INVALID ITEM TYPE';end if;
 return query select c.id,c.item_type,c.item_code,c.oem_code,c.name,c.brand,c.category,c.model,c.image_url,c.gst_mode,coalesce(i.current_qty,0) from catalog_items c left join inventory i on i.item_id=c.id where c.active=true and (coalesce(p_type,'')='' or c.item_type=p_type) and (coalesce(trim(p_brand),'')='' or lower(coalesce(c.brand,'')) like '%'||lower(trim(p_brand))||'%') and (q='' or lower(coalesce(c.item_code,'')) like '%'||q||'%' or lower(coalesce(c.oem_code,'')) like '%'||q||'%' or lower(coalesce(c.name,'')) like '%'||q||'%' or lower(coalesce(c.brand,'')) like '%'||q||'%' or lower(coalesce(c.category,'')) like '%'||q||'%' or lower(coalesce(c.model,'')) like '%'||q||'%') order by case when q<>'' and lower(c.item_code)=q then 0 when q<>'' and lower(coalesce(c.oem_code,''))=q then 1 when q<>'' and lower(c.name) like q||'%' then 2 else 3 end,c.item_code limit lim;
end;$$;
drop function if exists search_dealer_catalog(text,text,text,integer);
revoke all on function search_dealer_catalog(text,text,text,text,text,integer) from public,anon;grant execute on function search_dealer_catalog(text,text,text,text,text,integer) to authenticated;
