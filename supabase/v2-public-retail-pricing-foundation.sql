-- TORVO V2 PUBLIC RETAIL PRICING FOUNDATION
-- PUBLIC E-COMMERCE PRICE IS A SEPARATE, HIGHER RETAIL CHANNEL.
-- DEALER RATES REMAIN PRIVATE. CLIENT-SENT PRICES ARE NEVER AUTHORITATIVE.

begin;

create table if not exists public.v2_public_retail_prices (
  product_id uuid primary key,
  retail_price numeric(14,2) not null check (retail_price >= 0),
  is_enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

alter table public.v2_public_retail_prices enable row level security;

-- No direct anonymous/authenticated writes. Public reads must go through an approved
-- catalog/RPC boundary so private Dealer pricing cannot be joined/exposed accidentally.
revoke all on table public.v2_public_retail_prices from anon, authenticated;

create or replace function public.v2_public_retail_price(p_product_id uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_public numeric(14,2);
  v_dealer_floor numeric(14,2);
begin
  select retail_price into v_public
  from public.v2_public_retail_prices
  where product_id = p_product_id and is_enabled = true;

  if v_public is null then
    raise exception 'PUBLIC RETAIL SALE IS NOT ENABLED FOR THIS PRODUCT';
  end if;

  -- Existing TORVO product schemas have evolved across migrations. Resolve the protected
  -- Dealer floor only when a known Dealer-rate column set exists. Deployment must verify
  -- this branch against staging before enabling live public checkout.
  if to_regclass('public.products') is not null then
    begin
      execute 'select least(rate_a,rate_b,rate_c) from public.products where id=$1'
        into v_dealer_floor using p_product_id;
    exception when undefined_column then
      v_dealer_floor := null;
    end;
  end if;

  if v_dealer_floor is not null and v_public <= v_dealer_floor then
    raise exception 'PUBLIC RETAIL PRICE VIOLATES PROTECTED DEALER PRICE RULE';
  end if;

  return v_public;
end;
$$;

revoke all on function public.v2_public_retail_price(uuid) from public;
grant execute on function public.v2_public_retail_price(uuid) to anon, authenticated;

comment on table public.v2_public_retail_prices is
'TORVO public e-commerce retail price channel. Separate from private Dealer Rate A/B/C.';
comment on function public.v2_public_retail_price(uuid) is
'Returns enabled public retail price through a controlled boundary and rejects a detected protected Dealer-price violation.';

commit;
