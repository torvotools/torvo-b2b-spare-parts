-- TORVO V2 FINAL DEALER WORKSPACE READ BOUNDARY
-- Dealer catalog used by the private ordering workspace must fail immediately for a revoked old mobile.
create or replace function dealer_workspace_catalog(p_device_id text,p_session_token text)
returns table(id uuid,item_type text,item_code text,oem_code text,name text,brand text,category text,model text,image_url text,active boolean)
language plpgsql security definer set search_path=public as $$declare did uuid;begin
did:=dealer_assert_my_device_session(p_device_id,p_session_token);
return query select c.id,c.item_type,c.item_code,c.oem_code,c.name,c.brand,c.category,c.model,c.image_url,c.active from catalog_items c where c.active=true and c.item_type in('machine','spare_part','accessory') order by c.item_type,c.name;
end$$;
revoke all on function dealer_workspace_catalog(text,text) from public,anon;
grant execute on function dealer_workspace_catalog(text,text) to authenticated;
