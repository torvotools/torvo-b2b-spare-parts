-- TORVO V2 Purchase Requirement Item Master secure finders/linkage.
-- Requires v2-purchase-requirements.sql and catalog_items.
-- This does NOT create stock. Purchase Entry remains the only supplier stock-receipt path.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

-- Owner/Admin-only Item Master finder for New Item requirement linkage.
-- Returns identity fields only; no rates/cost/stock are exposed by this RPC.
create or replace function search_requirement_catalog(p_search text default null,p_type text default null,p_brand text default null,p_limit integer default 100)
returns table(id uuid,item_code text,oem_code text,name text,brand text,category text,item_type text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;s text:=lower(trim(coalesce(p_search,'')));lim integer:=greatest(1,least(coalesce(p_limit,100),100));begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 -- Do not dump the catalog on an empty query. A type/brand filter may intentionally browse a bounded set.
 if s='' and nullif(trim(coalesce(p_type,'')),'') is null and nullif(trim(coalesce(p_brand,'')),'') is null then return; end if;
 return query select c.id,c.item_code,c.oem_code,c.name,c.brand,c.category,c.item_type from catalog_items c where c.active=true and (nullif(trim(coalesce(p_type,'')),'') is null or c.item_type=p_type) and (nullif(trim(coalesce(p_brand,'')),'') is null or lower(coalesce(c.brand,''))=lower(trim(p_brand))) and (s='' or lower(coalesce(c.item_code,'')) like '%'||s||'%' or lower(coalesce(c.oem_code,'')) like '%'||s||'%' or lower(coalesce(c.name,'')) like '%'||s||'%' or lower(coalesce(c.brand,'')) like '%'||s||'%' or lower(coalesce(c.category,'')) like '%'||s||'%') order by case when s<>'' and lower(coalesce(c.item_code,''))=s then 0 when s<>'' and lower(coalesce(c.oem_code,''))=s then 1 when s<>'' and lower(coalesce(c.item_code,'')) like s||'%' then 2 when s<>'' and lower(coalesce(c.oem_code,'')) like s||'%' then 3 else 4 end,c.item_code limit lim;
end;$$;
revoke all on function search_requirement_catalog(text,text,text,integer) from public,anon;
grant execute on function search_requirement_catalog(text,text,text,integer) to authenticated;

-- Role-safe finder used when authorized staff submit an EXISTING ITEM Purchase Requirement.
-- Salesman/Accountant/Store Keeper need item identity to report demand, but never rates, cost, supplier or stock financials.
create or replace function search_purchase_requirement_items(p_search text default null,p_type text default null,p_brand text default null,p_limit integer default 100)
returns table(id uuid,item_code text,oem_code text,name text,brand text,category text,item_type text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;s text:=lower(trim(coalesce(p_search,'')));lim integer:=greatest(1,least(coalesce(p_limit,100),100));begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','salesman','accountant','store_keeper') then raise exception 'Authorized staff required'; end if;
 -- Empty search without a narrowing filter returns no rows: this remains fast when TORVO has thousands of items.
 if s='' and nullif(trim(coalesce(p_type,'')),'') is null and nullif(trim(coalesce(p_brand,'')),'') is null then return; end if;
 return query select c.id,c.item_code,c.oem_code,c.name,c.brand,c.category,c.item_type from catalog_items c where c.active=true and (nullif(trim(coalesce(p_type,'')),'') is null or c.item_type=p_type) and (nullif(trim(coalesce(p_brand,'')),'') is null or lower(coalesce(c.brand,''))=lower(trim(p_brand))) and (s='' or lower(coalesce(c.item_code,'')) like '%'||s||'%' or lower(coalesce(c.oem_code,'')) like '%'||s||'%' or lower(coalesce(c.name,'')) like '%'||s||'%' or lower(coalesce(c.brand,'')) like '%'||s||'%' or lower(coalesce(c.category,'')) like '%'||s||'%') order by case when s<>'' and lower(coalesce(c.item_code,''))=s then 0 when s<>'' and lower(coalesce(c.oem_code,''))=s then 1 when s<>'' and lower(coalesce(c.item_code,'')) like s||'%' then 2 when s<>'' and lower(coalesce(c.oem_code,'')) like s||'%' then 3 else 4 end,c.item_code limit lim;
end;$$;
revoke all on function search_purchase_requirement_items(text,text,text,integer) from public,anon;
grant execute on function search_purchase_requirement_items(text,text,text,integer) to authenticated;

create or replace function link_new_item_requirement_to_catalog(p_requirement uuid,p_item uuid,p_note text default null) returns void
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r purchase_requirements%rowtype;n purchase_requirement_new_items%rowtype;c catalog_items%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 select * into r from purchase_requirements where id=p_requirement for update;
 if not found then raise exception 'Requirement not found'; end if;
 if r.request_type<>'new_item' then raise exception 'Only New Item requirement can use this action'; end if;
 if r.status in('rejected','completed') then raise exception 'Closed requirement cannot be linked'; end if;
 select * into n from purchase_requirement_new_items where requirement_id=r.id for update;
 if not found then raise exception 'New Item details not found'; end if;
 if n.created_item_id is not null then
   if n.created_item_id=p_item then return; end if;
   raise exception 'Requirement is already linked to another Item Master record';
 end if;
 select * into c from catalog_items where id=p_item and active=true;
 if not found then raise exception 'Active Item Master record required'; end if;
 update purchase_requirement_new_items set created_item_id=p_item where requirement_id=r.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REQUIREMENT_ITEM_LINKED','purchase_requirement',r.id::text,jsonb_build_object('item_id',p_item,'item_code',c.item_code,'item_name',c.name,'note',nullif(trim(p_note),'')));
end;$$;
revoke all on function link_new_item_requirement_to_catalog(uuid,uuid,text) from public,anon;
grant execute on function link_new_item_requirement_to_catalog(uuid,uuid,text) to authenticated;
