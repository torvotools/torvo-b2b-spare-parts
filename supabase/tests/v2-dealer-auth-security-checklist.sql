-- TORVO V2 DEALER AUTH / SINGLE ACTIVE DEVICE STAGING CHECKLIST
-- RUN ONLY IN DEDICATED STAGING AFTER AUTH MIGRATIONS. THIS FILE IS A VERIFICATION CHECKLIST, NOT A PRODUCTION MIGRATION.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('dealer_login_credentials','dealer_device_sessions','dealer_pin_recovery_challenges');
select indexname,indexdef from pg_indexes where schemaname='public' and tablename='dealer_device_sessions' and indexname='uq_dealer_one_active_device';
select p.proname,pg_get_function_identity_arguments(p.oid) args,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('dealer_set_pin','dealer_verify_pin','dealer_start_device_session','dealer_validate_device_session','dealer_revoke_device_sessions','dealer_create_recovery_challenge','dealer_assert_my_device_session','dealer_verify_customer_referral','dealer_confirm_referral_benefit','dealer_referral_supply_status','dealer_order_referral_item') order by p.proname,args;
select auth_user_id,count(*) active_rows from app_users where active=true and auth_user_id is not null group by auth_user_id having count(*)>1;
select right(regexp_replace(coalesce(mobile,''),'\D','','g'),10) normalized_mobile,count(*) approved_rows from dealers where lower(coalesce(status,''))='approved' group by 1 having count(*)>1;
-- Legacy referral RPC signatures must be absent after the device-bound migrations.
select to_regprocedure('public.dealer_verify_customer_referral(text)') legacy_verify,to_regprocedure('public.dealer_confirm_referral_benefit(text)') legacy_benefit,to_regprocedure('public.dealer_referral_supply_status(text)') legacy_supply,to_regprocedure('public.dealer_order_referral_item(text,numeric)') legacy_order;
-- MANUAL STAGING GATES:
-- 1. VALID PIN + DEVICE A -> REAL SUPABASE DEALER AUTH + OPAQUE DEALER SESSION TOKEN.
-- 2. SAME DEALER + DEVICE B LOGIN -> DEVICE A REVOKED WITH NEW_DEVICE_LOGIN.
-- 3. KEEP DEVICE A APP OPEN: WITHIN THE HEARTBEAT WINDOW IT MUST FAIL VALIDATION, CLEAR LOCAL TOKEN AND SIGN OUT WITHOUT RELOAD.
-- 4. BACKGROUND DEVICE A, LOGIN ON B, THEN RETURN A TO FOREGROUND: VISIBILITY CHECK MUST SIGN A OUT IMMEDIATELY.
-- 5. FOCUS DEVICE A AFTER B LOGIN: FOCUS CHECK MUST SIGN A OUT IMMEDIATELY.
-- 6. DEVICE A MUST SHOW DEALER SESSION ENDED / ACTIVE ON ANOTHER DEVICE MESSAGE, NOT A GENERIC PROFILE FAILURE.
-- 7. DEVICE A MISSING PART CREATE/HISTORY MUST FAIL BEFORE PRIVATE RPC AFTER REVOCATION.
-- 8. DEVICE B REMAINS VALID AND CAN CREATE/READ ONLY ITS OWN DEALER REQUESTS.
-- 9. PIN CHANGE/RECOVERY REVOKES CURRENT DEVICE SESSION.
-- 10. 5 WRONG PIN ATTEMPTS CAUSE TEMPORARY LOCK; PLAINTEXT PIN NEVER APPEARS IN DB/LOGS.
-- 11. DUPLICATE ACTIVE app_users ROWS -> DEALER AUTH IDENTITY AMBIGUOUS.
-- 12. DUPLICATE APPROVED NORMALIZED DEALER MOBILE -> DEALER LINK AMBIGUOUS; SERVER MUST NOT GUESS.
-- 13. dealer_my_profile RETURNS ONLY THE AUTHENTICATED APPROVED DEALER.
-- 14. SIGN OUT REVOKES ACTIVE DEVICE SESSION AND CLEARS LOCAL DEALER TOKEN.
-- 15. AFTER DEVICE B LOGIN, DEVICE A MUST FAIL REFERRAL VERIFY, BENEFIT CONFIRM, SUPPLY STATUS AND ORDER CREATION EVEN WITH A VALID SUPABASE AUTH SESSION.
-- 16. DEVICE B MAY PERFORM THOSE REFERRAL ACTIONS ONLY FOR REFERRALS ASSIGNED TO ITS SERVER-DERIVED DEALER ID.
-- 17. REFERRAL ORDER QUANTITY MUST BE AN INTEGER FROM 1 TO 9999; REPEATED SUBMISSION MUST RETURN THE EXISTING REFERRAL ORDER.
