-- TORVO V2 public catalog dropdown foundation.
-- Install after v2-schema.sql / catalog_items and before public website runtime verification.
-- Public dropdown values are derived only from ACTIVE authoritative catalog rows.

create or replace function public.public_catalog_brands()
returns table(id text,name text)
language sql
security definer
set search_path=public
as $$
  select md5(upper(btrim(c.brand))) as id,
         upper(btrim(c.brand)) as name
  from public.catalog_items c
  where c.active=true
    and c.brand is not null
    and btrim(c.brand)<>''
  group by upper(btrim(c.brand))
  order by upper(btrim(c.brand));
$$;

create or replace function public.public_catalog_machine_models(p_brand text)
returns table(id text,name text)
language sql
security definer
set search_path=public
as $$
  select md5(upper(btrim(c.brand))||'|'||upper(btrim(c.model))) as id,
         upper(btrim(c.model)) as name
  from public.catalog_items c
  where c.active=true
    and c.item_type='machine'
    and c.model is not null
    and btrim(c.model)<>''
    and upper(btrim(c.brand))=upper(btrim(coalesce(p_brand,'')))
  group by upper(btrim(c.brand)),upper(btrim(c.model))
  order by upper(btrim(c.model));
$$;

revoke all on function public.public_catalog_brands() from public;
revoke all on function public.public_catalog_machine_models(text) from public;
grant execute on function public.public_catalog_brands() to anon,authenticated;
grant execute on function public.public_catalog_machine_models(text) to anon,authenticated;

comment on function public.public_catalog_brands() is 'PRICE-FREE PUBLIC BRAND DROPDOWN FROM ACTIVE TORVO CATALOG.';
comment on function public.public_catalog_machine_models(text) is 'PRICE-FREE PUBLIC MACHINE MODEL DROPDOWN LINKED TO SELECTED ACTIVE CATALOG BRAND.';
