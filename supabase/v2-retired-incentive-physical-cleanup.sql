-- TORVO V2 RETIRED INCENTIVE PHYSICAL CLEANUP
-- Safe only after runtime lockdown and zero-row verification.
-- Removes dealer schemes/points/targets and dealer-recruitment incentive objects.
-- DOES NOT touch customer_dealer_referrals, dealer_referral_events, public customer
-- referral RPCs, Customer Leads, Customer Referral workspace, or Fitment Knowledge.

do $torvo$
declare r record;
begin
 for r in
  select p.oid::regprocedure signature
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname in(
   'add_scheme_slab','admin_approve_reward_claim','admin_assign_dealer_target',
   'admin_cancel_reward_claim','admin_dealer_target_reward_data','admin_issue_reward_voucher',
   'admin_save_dealer_reward_option','admin_save_dealer_target_slab','admin_save_dealer_target_type',
   'admin_settle_dealer_target','assert_reward_lot_migration_ready','assign_scheme_dealer',
   'create_scheme','credit_achieved_scheme_rewards','dealer_claim_reward','dealer_reward_balance',
   'dealer_reward_claim_history','dealer_reward_options','dealer_reward_progress','earn_reward_points',
   'expire_reward_points','recalculate_dealer_scheme_progress','redeem_reward_points',
   'refresh_scheme_progress','reward_admin_user','reward_available_balance','reward_current_dealer',
   'reward_reconciliation_status','reward_scheme_period','reward_scheme_year','set_scheme_status',
   'unassign_scheme_dealer','create_dealer_referral','create_referral_rule','evaluate_dealer_referral',
   'salesman_my_referral_statement','salesman_start_referral_otp','salesman_verify_referral_otp'
  )
 loop execute format('drop function if exists %s',r.signature); end loop;
end
$torvo$;

drop table if exists public.reward_redemption_allocations;
drop table if exists public.reward_point_lots;
drop table if exists public.reward_ledger;
drop table if exists public.dealer_target_reward_settlements;
drop table if exists public.dealer_target_assignments;
drop table if exists public.dealer_target_slabs;
drop table if exists public.dealer_target_types;
drop table if exists public.dealer_reward_claims;
drop table if exists public.dealer_reward_catalog;
drop table if exists public.dealer_reward_points_ledger;
drop table if exists public.dealer_scheme_progress;
drop table if exists public.scheme_dealers;
drop table if exists public.scheme_slabs;
drop table if exists public.schemes;
drop table if exists public.dealer_referrals;
drop table if exists public.referral_rules;
drop table if exists public.salesman_targets;
