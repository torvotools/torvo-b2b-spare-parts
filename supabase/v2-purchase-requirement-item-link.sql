-- TORVO V2 New Item Purchase Requirement → Item Master secure linkage.
-- Requires v2-purchase-requirements.sql and catalog_items.
-- This does NOT create stock. Purchase Entry remains the only supplier stock-receipt path.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

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
