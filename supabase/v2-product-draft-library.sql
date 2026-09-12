-- TORVO V2 PRODUCT DRAFT LIBRARY
-- PRE-ENTRY INBOX FOR PHOTOS/DETAILS BEFORE AN ITEM IS CREATED IN PRODUCT MASTER.
create table if not exists product_draft_library(
 id uuid primary key default gen_random_uuid(),
 item_type text check(item_type in('machine','spare_part','accessory')),
 item_code text,oem_code text,name text,brand text,category text,model text,
 image_url text,notes text,
 ai_content_draft_id uuid references product_content_drafts(id) on delete set null,
 status text not null default 'draft' check(status in('draft','converted','archived')),
 converted_item_id uuid references catalog_items(id) on delete set null,
 created_by uuid not null references app_users(id),created_at timestamptz not null default now(),
 updated_by uuid references app_users(id),updated_at timestamptz not null default now(),converted_at timestamptz
);
create index if not exists idx_product_draft_library_status on product_draft_library(status,updated_at desc);
create index if not exists idx_product_draft_library_search on product_draft_library(item_type,brand,category,model);
alter table product_draft_library enable row level security;revoke all on product_draft_library from anon,authenticated;

create or replace function admin_save_product_draft(p_id uuid,p_item_type text,p_item_code text,p_oem_code text,p_name text,p_brand text,p_category text,p_model text,p_image_url text,p_notes text)
returns uuid language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v_id uuid;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if p_item_type is not null and p_item_type not in('machine','spare_part','accessory') then raise exception 'INVALID ITEM TYPE';end if;
 if nullif(btrim(coalesce(p_image_url,'')),'') is null and nullif(btrim(coalesce(p_name,'')),'') is null and nullif(btrim(coalesce(p_notes,'')),'') is null then raise exception 'PHOTO, NAME OR NOTE REQUIRED';end if;
 if p_id is null then insert into product_draft_library(item_type,item_code,oem_code,name,brand,category,model,image_url,notes,created_by,updated_by) values(p_item_type,upper(nullif(btrim(p_item_code),'')),upper(nullif(btrim(p_oem_code),'')),upper(nullif(btrim(p_name),'')),upper(nullif(btrim(p_brand),'')),upper(nullif(btrim(p_category),'')),upper(nullif(btrim(p_model),'')),nullif(btrim(p_image_url),''),upper(nullif(btrim(p_notes),'')),u.id,u.id) returning id into v_id;
 else update product_draft_library set item_type=p_item_type,item_code=upper(nullif(btrim(p_item_code),'')),oem_code=upper(nullif(btrim(p_oem_code),'')),name=upper(nullif(btrim(p_name),'')),brand=upper(nullif(btrim(p_brand),'')),category=upper(nullif(btrim(p_category),'')),model=upper(nullif(btrim(p_model),'')),image_url=nullif(btrim(p_image_url),''),notes=upper(nullif(btrim(p_notes),'')),updated_by=u.id,updated_at=now() where id=p_id and status='draft' returning id into v_id;if v_id is null then raise exception 'EDITABLE DRAFT NOT FOUND';end if;end if;return v_id;end$$;
revoke all on function admin_save_product_draft(uuid,text,text,text,text,text,text,text,text,text) from public;grant execute on function admin_save_product_draft(uuid,text,text,text,text,text,text,text,text,text) to authenticated;

create or replace function admin_product_drafts(p_search text default null,p_item_type text default null,p_limit integer default 100)
returns setof product_draft_library language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;s text;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;s:=lower(btrim(coalesce(p_search,'')));return query select d.* from product_draft_library d where d.status='draft' and (p_item_type is null or d.item_type=p_item_type) and (s='' or lower(concat_ws(' ',d.item_code,d.oem_code,d.name,d.brand,d.category,d.model,d.notes)) like '%'||s||'%') order by d.updated_at desc limit greatest(1,least(coalesce(p_limit,100),200));end$$;
revoke all on function admin_product_drafts(text,text,integer) from public;grant execute on function admin_product_drafts(text,text,integer) to authenticated;

create or replace function admin_mark_product_draft_converted(p_draft_id uuid,p_item_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;if not exists(select 1 from catalog_items where id=p_item_id) then raise exception 'PRODUCT NOT FOUND';end if;update product_draft_library set status='converted',converted_item_id=p_item_id,converted_at=now(),updated_by=u.id,updated_at=now() where id=p_draft_id and status='draft';if not found then raise exception 'DRAFT NOT FOUND OR ALREADY USED';end if;insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'PRODUCT_DRAFT_CONVERTED','CATALOG_ITEM',p_item_id::text,jsonb_build_object('draft_id',p_draft_id));return true;end$$;
revoke all on function admin_mark_product_draft_converted(uuid,uuid) from public;grant execute on function admin_mark_product_draft_converted(uuid,uuid) to authenticated;
