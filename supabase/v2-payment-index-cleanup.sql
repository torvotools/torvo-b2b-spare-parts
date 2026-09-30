-- TORVO V2 — PAYMENT INDEX CLEANUP
-- Canonical request-key uniqueness is owned by v2-payment-idempotency.sql as ux_payments_request_key.
-- Older staging/install histories may also contain the identical idx_payments_request_key_uq.
-- Keep exactly one unique partial index to avoid duplicate write/storage overhead.
drop index if exists public.idx_payments_request_key_uq;

do $$
begin
 if to_regclass('public.ux_payments_request_key') is null then
  raise exception 'CANONICAL PAYMENT REQUEST-KEY INDEX MISSING';
 end if;
end $$;
