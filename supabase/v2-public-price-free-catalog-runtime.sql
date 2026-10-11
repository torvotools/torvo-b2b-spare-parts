-- TORVO V2 — PUBLIC PRICE-FREE CATALOG RUNTIME CONTRACT
-- Public discovery only. Never expose Dealer A/B/C rates, purchase cost, inventory,
-- GST/HSN/offer internals, or private Suitable Spare Parts intelligence.

create or replace function public.public_customer_catalog(
  p_search text default null,
  p_limit integer default 20
)
returns table(
  id uuid,item_code text,oem_no text,name text,item_type text,brand text,
  category text,model text,image_url text,short_description text
)
language sql security definer set search_path=public
as $$
  select c.id,c.item_code,c.oem_code,c.name,c.item_type,c.brand,c.category,c.model,
         c.image_url,c.short_description
  from public.catalog_items c
  where c.active=true
    and (nullif(btrim(coalesce(p_search,'')),'') is null or
      concat_ws(' ',c.name,c.item_code,c.oem_code,c.brand,c.category,c.model)
        ilike '%'||btrim(p_search)||'%')
  order by c.created_at desc,c.name
  limit least(greatest(coalesce(p_limit,20),1),120)
$$;

create or replace function public.public_customer_catalog_filtered(
  p_search text default null,p_item_type text default null,p_brand text default null,
  p_category text default null,p_model text default null,p_machine_id uuid default null,
  p_available_only boolean default false,p_sort text default 'RELEVANT',p_limit integer default 60
)
returns table(
  id uuid,item_code text,oem_no text,name text,item_type text,brand text,
  category text,model text,image_url text,short_description text
)
language sql security definer set search_path=public
as $$
  select c.id,c.item_code,c.oem_code,c.name,c.item_type,c.brand,c.category,c.model,
         c.image_url,c.short_description
  from public.catalog_items c
  where c.active=true
    and (nullif(btrim(coalesce(p_search,'')),'') is null or
      concat_ws(' ',c.name,c.item_code,c.oem_code,c.brand,c.category,c.model)
        ilike '%'||btrim(p_search)||'%')
    and (nullif(btrim(coalesce(p_item_type,'')),'') is null or lower(c.item_type)=lower(btrim(p_item_type)))
    and (nullif(btrim(coalesce(p_brand,'')),'') is null or upper(c.brand)=upper(btrim(p_brand)))
    and (nullif(btrim(coalesce(p_category,'')),'') is null or upper(c.category)=upper(btrim(p_category)))
    and (nullif(btrim(coalesce(p_model,'')),'') is null or upper(c.model)=upper(btrim(p_model)))
    and (p_machine_id is null or exists(
      select 1 from public.machine_spare_mapping m
      where m.machine_id=p_machine_id and m.spare_part_id=c.id and m.public_visible=true
    ))
  order by c.created_at desc,c.name
  limit least(greatest(coalesce(p_limit,60),1),120)
$$;

create or replace function public.public_product_showcase(p_limit integer default 60)
returns table(
  id uuid,item_code text,oem_no text,name text,item_type text,brand text,
  category text,model text,image_url text,short_description text
)
language sql security definer set search_path=public
as $$
  select c.id,c.item_code,c.oem_code,c.name,c.item_type,c.brand,c.category,c.model,
         c.image_url,c.short_description
  from public.catalog_items c
  where c.active=true
  order by c.created_at desc,c.name
  limit least(greatest(coalesce(p_limit,60),1),120)
$$;

-- Opt-in bounded pages; stable keyset order avoids skipping items with identical timestamps.
-- No public prices, stock, private compatibility or dealer-only fields.
create or replace function public.public_customer_catalog_page(
  p_search text default null,
  p_before_created_at timestamptz default null,
  p_before_id uuid default null,
  p_limit integer default 60
)
returns table(
  id uuid,item_code text,oem_no text,name text,item_type text,brand text,
  category text,model text,image_url text,short_description text,
  page_created_at timestamptz
)
language sql security definer set search_path=public
as $
  select c.id,c.item_code,c.oem_code,c.name,c.item_type,c.brand,c.category,c.model,
         c.image_url,c.short_description,c.created_at
  from public.catalog_items c
  where c.active=true
    and (nullif(btrim(coalesce(p_search,'')),'') is null or
      concat_ws(' ',c.name,c.item_code,c.oem_code,c.brand,c.category,c.model)
        ilike '%'||btrim(p_search)||'%')
    and (p_before_created_at is null or
      (p_before_id is not null and (c.created_at,c.id)<(p_before_created_at,p_before_id)))
  order by c.created_at desc,c.id desc
  limit least(greatest(coalesce(p_limit,60),1),120)
$;

revoke all on function public.public_customer_catalog_page(text,timestamptz,uuid,integer) from public;
grant execute on function public.public_customer_catalog_page(text,timestamptz,uuid,integer) to anon,authenticated;

revoke all on function public.public_customer_catalog(text,integer) from public;
revoke all on function public.public_customer_catalog_filtered(text,text,text,text,text,uuid,boolean,text,integer) from public;
revoke all on function public.public_product_showcase(integer) from public;
grant execute on function public.public_customer_catalog(text,integer) to anon,authenticated;
grant execute on function public.public_customer_catalog_filtered(text,text,text,text,text,uuid,boolean,text,integer) to anon,authenticated;
grant execute on function public.public_product_showcase(integer) to anon,authenticated;
