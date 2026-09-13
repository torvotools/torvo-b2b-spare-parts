-- TORVO V2 PUBLIC PRODUCT SHOWCASE
-- CENTRAL PRODUCT MASTER ONLY. NO DEALER RATES / COST / PRIVATE COMPATIBILITY.
-- CONTENT MUST BE ADMIN-APPROVED BEFORE PUBLIC DESCRIPTION/FEATURES ARE EXPOSED.

alter table catalog_items add column if not exists public_visible boolean not null default false;
create index if not exists idx_catalog_items_public_showcase on catalog_items(public_visible,active,content_status);

create or replace function public_product_showcase(p_limit integer default 12)
returns table(
 id uuid,
 item_code text,
 name text,
 item_type text,
 brand text,
 category text,
 model text,
 image_url text,
 short_description text,
 detailed_description text,
 feature_points jsonb
)
language sql
security definer
set search_path=public
as $$
 select
   c.id,c.item_code,c.name,c.item_type,c.brand,c.category,c.model,c.image_url,
   c.short_description,c.detailed_description,c.feature_points
 from catalog_items c
 where c.active=true
   and c.public_visible=true
   and c.content_status='approved'
 order by c.content_approved_at desc nulls last,c.created_at desc,c.name
 limit greatest(1,least(coalesce(p_limit,12),30));
$$;
revoke all on function public_product_showcase(integer) from public;
grant execute on function public_product_showcase(integer) to anon,authenticated;

create or replace function admin_set_product_public_visibility(p_item_id uuid,p_visible boolean)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare u app_users%rowtype;v catalog_items%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 select * into v from catalog_items where id=p_item_id;
 if v.id is null then raise exception 'PRODUCT NOT FOUND';end if;
 if coalesce(p_visible,false) and v.content_status<>'approved' then raise exception 'APPROVED PRODUCT CONTENT REQUIRED BEFORE PUBLICATION';end if;
 update catalog_items set public_visible=coalesce(p_visible,false) where id=p_item_id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(u.id,case when p_visible then 'PRODUCT_PUBLISHED' else 'PRODUCT_UNPUBLISHED' end,'CATALOG_ITEM',p_item_id::text,jsonb_build_object('public_visible',coalesce(p_visible,false)));
 return true;
end$$;
revoke all on function admin_set_product_public_visibility(uuid,boolean) from public;
grant execute on function admin_set_product_public_visibility(uuid,boolean) to authenticated;
