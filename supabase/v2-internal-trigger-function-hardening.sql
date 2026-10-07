-- TORVO V2 internal trigger helper privilege hardening.
-- Trigger functions are invoked by PostgreSQL triggers and are not client RPC surfaces.
-- Remove default PUBLIC execution so anon/authenticated clients cannot invoke the helper directly.
revoke all on function public.torvo_assign_estimate_number() from public, anon, authenticated;
