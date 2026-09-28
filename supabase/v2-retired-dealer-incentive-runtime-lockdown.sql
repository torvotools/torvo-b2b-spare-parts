-- TORVO V2 RETIRED DEALER-RECRUITMENT / INCENTIVE RUNTIME LOCKDOWN
-- Dealer recruitment rewards/commission/points are retired.
-- Customer -> Dealer public referral/routing RPCs are intentionally untouched.
-- This is non-destructive: legacy empty tables remain until dependency-safe cleanup.

do $torvo$
declare r record;
begin
 for r in
  select p.oid::regprocedure as signature
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in(
      'create_dealer_referral',
      'create_referral_rule',
      'evaluate_dealer_referral',
      'salesman_my_referral_statement',
      'salesman_start_referral_otp',
      'salesman_verify_referral_otp'
    )
 loop
  execute format('revoke all on function %s from public, anon, authenticated',r.signature);
 end loop;
end
$torvo$;
