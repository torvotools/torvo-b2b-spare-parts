-- TORVO V2 PUBLIC CHECKOUT PAYMENT MODES
-- Foundation only: staging migration/runtime verification required before production use.
begin;

create table if not exists public.v2_public_checkout_settings(
  singleton boolean primary key default true check(singleton),
  full_prepaid_enabled boolean not null default true,
  logistics_advance_enabled boolean not null default false,
  default_logistics_advance numeric(14,2) not null default 0 check(default_logistics_advance>=0),
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

insert into public.v2_public_checkout_settings(singleton) values(true) on conflict(singleton) do nothing;
alter table public.v2_public_checkout_settings enable row level security;
revoke all on public.v2_public_checkout_settings from anon,authenticated;

create table if not exists public.v2_public_checkout_quotes(
  id uuid primary key default gen_random_uuid(),
  request_key text not null unique,
  customer_mobile text not null,
  payment_mode text not null check(payment_mode in('FULL_PREPAID','LOGISTICS_ADVANCE')),
  merchandise_amount numeric(14,2) not null check(merchandise_amount>=0),
  tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
  forward_logistics_charge numeric(14,2) not null default 0 check(forward_logistics_charge>=0),
  logistics_advance numeric(14,2) not null default 0 check(logistics_advance>=0),
  amount_payable_now numeric(14,2) not null check(amount_payable_now>=0),
  balance_on_delivery numeric(14,2) not null default 0 check(balance_on_delivery>=0),
  status text not null default 'AWAITING_PAYMENT' check(status in('AWAITING_PAYMENT','PAYMENT_PENDING','ADVANCE_VERIFIED','PAID','EXPIRED','CANCELLED')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default(now()+interval '30 minutes')
);
alter table public.v2_public_checkout_quotes enable row level security;
revoke all on public.v2_public_checkout_quotes from anon,authenticated;

create table if not exists public.v2_public_payment_events(
  id bigint generated always as identity primary key,
  checkout_quote_id uuid not null references public.v2_public_checkout_quotes(id),
  provider text not null,
  provider_event_id text not null,
  provider_payment_id text,
  amount numeric(14,2) not null check(amount>=0),
  verified boolean not null default false,
  received_at timestamptz not null default now(),
  unique(provider,provider_event_id)
);
alter table public.v2_public_payment_events enable row level security;
revoke all on public.v2_public_payment_events from anon,authenticated;

create table if not exists public.v2_public_order_exceptions(
  id uuid primary key default gen_random_uuid(),
  checkout_quote_id uuid references public.v2_public_checkout_quotes(id),
  exception_type text not null check(exception_type in('TORVO_CANCELLED','NON_SUPPLY','DUPLICATE_PAYMENT','WRONG_ITEM','TRANSIT_DAMAGE','VERIFIED_DEFECT','RTO_REFUSAL','LEGAL_REMEDY','OTHER_APPROVED')),
  requested_amount numeric(14,2) check(requested_amount>=0),
  approved_amount numeric(14,2) check(approved_amount>=0),
  reason text not null,
  status text not null default 'OPEN' check(status in('OPEN','APPROVED','REJECTED','COMPLETED')),
  created_at timestamptz not null default now(),
  created_by uuid null,
  decided_at timestamptz,
  decided_by uuid null
);
alter table public.v2_public_order_exceptions enable row level security;
revoke all on public.v2_public_order_exceptions from anon,authenticated;

comment on table public.v2_public_checkout_quotes is 'Server-authoritative public retail checkout snapshot. Never accept client totals as commercial truth.';
comment on column public.v2_public_checkout_quotes.logistics_advance is 'Advance collected before fulfilment for LOGISTICS_ADVANCE mode; policy/exception treatment remains Admin controlled and legally compliant.';
comment on table public.v2_public_payment_events is 'Idempotent provider event ledger. Unique provider event prevents duplicate callback credit.';
commit;
