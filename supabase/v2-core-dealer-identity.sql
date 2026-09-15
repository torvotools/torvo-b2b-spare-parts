-- TORVO V2 CORE CANONICAL DEALER IDENTITY
-- INSTALL IMMEDIATELY AFTER v2-schema.sql AND BEFORE ANY DEALER APPROVAL RPC.
-- This dependency intentionally lives before Step 11 final approval and Step 17 PIN/device auth.

alter table app_users
  add column if not exists dealer_id uuid references dealers(id) on delete restrict;

create unique index if not exists uq_app_users_dealer_identity
  on app_users(dealer_id)
  where dealer_id is not null;

comment on column app_users.dealer_id is
  'Canonical private Dealer identity. Required before final Dealer approval; mobile is not an authorization key.';
