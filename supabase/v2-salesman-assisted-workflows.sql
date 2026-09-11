-- TORVO V2 salesman-assisted workflows. Staging/runtime verification required before production.
-- Every assisted action is attributable to the logged-in salesman and dealer consent is recorded separately.

alter table sales_documents add column if not exists order_source text not null default 'dealer_self' check(order_source in ('dealer_self','salesman_assisted','admin_assisted'));
alter table sales_documents add column if not exists assisted_by uuid references app_users(id) on delete restrict;
alter table sales_documents add column if not exists dealer_consent_method text check(dealer_consent_method in ('whatsapp_confirmation','phone','written_slip','in_person','dealer_self'));
alter table sales_documents add column if not exists dealer_consent_note text;
create index if not exists idx_sales_documents_source on sales_documents(order_source,created_at desc);
create index if not exists idx_sales_documents_assisted_by on sales_documents(assisted_by,created_at desc) where assisted_by is not null;

create table if not exists salesman_assisted_registrations (
  id uuid primary key default gen_random_uuid(),
  dealer_id uuid not null unique references dealers(id) on delete restrict,
  salesman_id uuid not null references app_users(id) on delete restrict,
  whatsapp_number text not null,
  otp_verified boolean not null default false,
  otp_verified_at timestamptz,
  submitted_at timestamptz not null default now(),
  admin_status text not null default 'pending' check(admin_status in ('pending','approved','hold','rejected')),
  reviewed_by uuid references app_users(id) on delete restrict,
  reviewed_at timestamptz,
  review_note text,
  check((otp_verified=false and otp_verified_at is null) or (otp_verified=true and otp_verified_at is not null))
);
create index if not exists idx_salesman_assisted_reg_salesman on salesman_assisted_registrations(salesman_id,submitted_at desc);

-- Do not store OTP plaintext here. The approved WhatsApp OTP service will verify a challenge and only then mark consent.
create table if not exists dealer_consent_events (
  id uuid primary key default gen_random_uuid(),
  dealer_id uuid references dealers(id) on delete restrict,
  salesman_id uuid references app_users(id) on delete restrict,
  entity_type text not null check(entity_type in ('dealer_registration','purchase_order')),
  entity_id uuid not null,
  method text not null check(method in ('whatsapp_otp','whatsapp_confirmation','phone','written_slip','in_person')),
  verified boolean not null default false,
  verification_reference text,
  created_at timestamptz not null default now(),
  verified_at timestamptz
);
create index if not exists idx_dealer_consent_entity on dealer_consent_events(entity_type,entity_id,created_at desc);

-- Server-side helper: salesman can only act for a currently mapped dealer.
create or replace function salesman_can_access_dealer(p_salesman uuid,p_dealer uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from salesman_dealer_mappings m
    where m.salesman_id=p_salesman and m.dealer_id=p_dealer and m.active=true
  );
$$;
revoke all on function salesman_can_access_dealer(uuid,uuid) from public,anon;
grant execute on function salesman_can_access_dealer(uuid,uuid) to authenticated;
