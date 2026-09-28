-- TORVO V2 RETIRED REWARD / SCHEME RUNTIME LOCKDOWN
-- Owner direction: no points, reward points, dealer schemes, target schemes,
-- scheme progress, lottery or dealer-recruitment incentive.
-- This migration intentionally does NOT drop legacy tables yet: historical
-- customer-referral compatibility is audited separately before destructive cleanup.
-- Customer -> Dealer routing/referral and Fitment Knowledge are NOT retired here.

do $torvo$
declare r record;
begin
 for r in
  select p.oid::regprocedure as signature
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in(
      'add_scheme_slab','admin_approve_reward_claim','admin_assign_dealer_target',
      'admin_cancel_reward_claim','admin_dealer_target_reward_data','admin_issue_reward_voucher',
      'admin_save_dealer_reward_option','admin_save_dealer_target_slab','admin_save_dealer_target_type',
      'admin_settle_dealer_target','assert_reward_lot_migration_ready','assign_scheme_dealer',
      'create_scheme','credit_achieved_scheme_rewards','dealer_claim_reward','dealer_reward_balance',
      'dealer_reward_claim_history','dealer_reward_options','dealer_reward_progress','earn_reward_points',
      'expire_reward_points','recalculate_dealer_scheme_progress','redeem_reward_points',
      'refresh_scheme_progress','reward_admin_user','reward_available_balance','reward_current_dealer',
      'reward_reconciliation_status','reward_scheme_period','reward_scheme_year',
      'set_scheme_status','unassign_scheme_dealer'
    )
 loop
  execute format('revoke all on function %s from public, anon, authenticated',r.signature);
 end loop;
end
$torvo$;

comment on table public.marg_bill_sales is
'TORVO V2 canonical Sale posting ledger. Dealer reward/scheme/target incentive systems are retired and are not Sale gates.';
