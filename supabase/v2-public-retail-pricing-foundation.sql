-- TORVO V2 PUBLIC RETAIL PRICING FOUNDATION
-- PUBLIC E-COMMERCE PRICE IS A SEPARATE, HIGHER RETAIL CHANNEL.
-- AUTHORITATIVE DEALER RATES LIVE IN item_rates(item_id, rate_group, min_qty, selling_rate).
-- DEALER RATES REMAIN PRIVATE. CLIENT-SENT PRICES ARE NEVER AUTHORITATIVE.

begin;

create table if not exists public.v2_public_retail_prices (
  product_id uuid primary key references public.catalog_items(id) on delete restrict,
  retail_price numeric(14,2) not null check (retail_price >= 0),
  is_enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid null references public.app_users(id) on delete set null
);

alter table public.v2_public_retail_prices enable row level security;
revoke all on table public.v2_public_retail_prices from anon, authenticated;

create or replace function public.v2_public_retail_price(p_product_id uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_public numeric(14,2);
  v_highest_dealer numeric(14,2);
begin
  if p_product_id is null then
    raise exception 'PRODUCT IS REQUIRED';
  end if;

  if not exists(select 1 from public.catalog_items c where c.id=p_product_id and c.active=true) then
    raise exception 'ACTIVE PRODUCT NOT FOUND';
  end if;

  select p.retail_price
    into v_public
  from public.v2_public_retail_prices p
  where p.product_id=p_product_id and p.is_enabled=true;

  if v_public is null then
    raise exception 'PUBLIC RETAIL SALE IS NOT ENABLED FOR THIS PRODUCT';
  end if;

  -- Public retail must remain above EVERY configured Dealer selling rate/slab.
  -- MAX is intentional: comparing only with the cheapest Dealer rate would allow
  -- public checkout to undercut another applicable Dealer rate.
  select max(r.selling_rate)
    into v_highest_dealer
  from public.item_rates r
  where r.item_id=p_product_id;

  -- Fail closed. A product without authoritative Dealer pricing cannot be enabled
  -- for public checkout until TORVO completes its commercial configuration.
  if v_highest_dealer is null then
    raise exception 'PUBLIC RETAIL CHECKOUT BLOCKED: DEALER PRICING IS NOT CONFIGURED';
  end if;

  if v_public <= v_highest_dealer then
    raise exception 'PUBLIC RETAIL PRICE MUST BE ABOVE ALL CONFIGURED DEALER RATES';
  end if;

  return v_public;
end;
$$;

revoke all on function public.v2_public_retail_price(uuid) from public;
grant execute on function public.v2_public_retail_price(uuid) to anon, authenticated;

comment on table public.v2_public_retail_prices is
'TORVO public e-commerce retail price channel. Separate from private Dealer Rate A/B/C.';
comment on function public.v2_public_retail_price(uuid) is
'Returns only an enabled high public retail price after validating it is above every authoritative item_rates Dealer selling rate. Dealer rates are never returned.';

commit;
