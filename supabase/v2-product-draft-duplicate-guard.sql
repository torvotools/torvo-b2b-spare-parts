-- TORVO V2 / STAGING-FIRST PRODUCT DRAFT DUPLICATE GUARD
-- REVIEW AND APPLY IN CANONICAL INSTALL ORDER; DO NOT APPLY TO PRODUCTION WITHOUT OWNER APPROVAL.
-- No changes to live catalog item uniqueness. Guard applies only to editable drafts.
-- Fail closed if existing duplicate draft codes need manual resolution.
do $$begin
 if exists (
  select 1 from product_draft_library
  where status='draft' and nullif(btrim(item_code),'') is not null
  group by upper(btrim(item_code))
  having count(*)>1
 ) then raise exception 'DUPLICATE ACTIVE DRAFT ITEM CODES EXIST: RESOLVE BEFORE INSTALLING GUARD';
 end if;
end$$;

create unique index if not exists ux_torvo_draft_active_item_code
 on product_draft_library (upper(btrim(item_code)))
 where status='draft' and nullif(btrim(item_code),'') is not null;

create or replace function admin_save_product_draft(
 p_id uuid,p_item_type text,p_item_code text,p_oem_code text,p_name text,
 p_brand text,p_category text,p_model text,p_image_url text,p_notes text
) returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;v_id uuid;v_code text;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if p_item_type is not null and p_item_type not in('machine','spare_part','accessory') then raise exception 'INVALID ITEM TYPE';end if;
 if nullif(btrim(coalesce(p_image_url,'')),'') is null and nullif(btrim(coalesce(p_name,'')),'') is null and nullif(btrim(coalesce(p_notes,'')),'') is null then raise exception 'PHOTO, NAME OR NOTE REQUIRED';end if;
 v_code:=upper(nullif(btrim(p_item_code),''));
 if v_code is not null then
  if exists(select 1 from catalog_items where upper(btrim(item_code))=v_code) then
   raise exception 'ALREADY EXISTS: ITEM CODE IN PRODUCT MASTER';
  end if;
  if exists(select 1 from product_draft_library where status='draft' and id is distinct from p_id and upper(btrim(item_code))=v_code) then
   raise exception 'ALREADY EXISTS: ITEM CODE IN PRODUCT DRAFT LIBRARY';
  end if;
 end if;
 if p_id is null then
  insert into product_draft_library(item_type,item_code,oem_code,name,brand,category,model,image_url,notes,created_by,updated_by)
  values(p_item_type,v_code,upper(nullif(btrim(p_oem_code),'')),upper(nullif(btrim(p_name),'')),upper(nullif(btrim(p_brand),'')),upper(nullif(btrim(p_category),'')),upper(nullif(btrim(p_model),'')),nullif(btrim(p_image_url),''),upper(nullif(btrim(p_notes),'')),u.id,u.id)
  returning id into v_id;
 else
  update product_draft_library set item_type=p_item_type,item_code=v_code,oem_code=upper(nullif(btrim(p_oem_code),'')),name=upper(nullif(btrim(p_name),'')),brand=upper(nullif(btrim(p_brand),'')),category=upper(nullif(btrim(p_category),'')),model=upper(nullif(btrim(p_model),'')),image_url=nullif(btrim(p_image_url),''),notes=upper(nullif(btrim(p_notes),'')),updated_by=u.id,updated_at=now()
  where id=p_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'EDITABLE DRAFT NOT FOUND';end if;
 end if;
 return v_id;
exception when unique_violation then
 raise exception 'ALREADY EXISTS: ACTIVE PRODUCT DRAFT ITEM CODE';
end$$;
revoke all on function admin_save_product_draft(uuid,text,text,text,text,text,text,text,text,text) from public;
grant execute on function admin_save_product_draft(uuid,text,text,text,text,text,text,text,text,text) to authenticated;
