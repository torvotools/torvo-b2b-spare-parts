-- TORVO V2 DEALER AUTH / SINGLE ACTIVE DEVICE STAGING CHECKLIST
-- RUN ONLY IN DEDICATED STAGING AFTER AUTH + FINAL DEVICE-BOUND MIGRATIONS.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('dealer_login_credentials','dealer_device_sessions','dealer_pin_recovery_challenges');
select indexname,indexdef from pg_indexes where schemaname='public' and tablename='dealer_device_sessions' and indexname='uq_dealer_one_active_device';
select p.proname,pg_get_function_identity_arguments(p.oid) args,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('dealer_assert_my_device_session','get_dealer_machine_spares','dealer_knowledge_challenges','dealer_knowledge_history','submit_knowledge_answer','dealer_verify_customer_referral','dealer_confirm_referral_benefit','dealer_referral_supply_status','dealer_order_referral_item') order by p.proname,args;
select auth_user_id,count(*) active_rows from app_users where active=true and auth_user_id is not null group by auth_user_id having count(*)>1;
select right(regexp_replace(coalesce(mobile,''),'\D','','g'),10) normalized_mobile,count(*) approved_rows from dealers where lower(coalesce(status,''))='approved' group by 1 having count(*)>1;
-- Legacy no-device signatures must be absent after final migrations.
select to_regprocedure('public.get_dealer_machine_spares(uuid)') legacy_machine,to_regprocedure('public.dealer_knowledge_challenges()') legacy_challenges,to_regprocedure('public.dealer_knowledge_history()') legacy_history,to_regprocedure('public.submit_knowledge_answer(uuid,text,text,text,text,text)') legacy_knowledge,to_regprocedure('public.dealer_verify_customer_referral(text)') legacy_verify,to_regprocedure('public.dealer_confirm_referral_benefit(text)') legacy_benefit,to_regprocedure('public.dealer_referral_supply_status(text)') legacy_supply,to_regprocedure('public.dealer_order_referral_item(text,numeric)') legacy_order;
-- MANUAL STAGING GATES:
-- 1. VALID PIN + DEVICE A -> REAL SUPABASE DEALER AUTH + OPAQUE DEALER SESSION TOKEN.
-- 2. SAME DEALER + DEVICE B LOGIN -> DEVICE A REVOKED WITH NEW_DEVICE_LOGIN.
-- 3. KEEP DEVICE A APP OPEN: HEARTBEAT/FOCUS/VISIBILITY MUST SIGN IT OUT WITHOUT RELOAD.
-- 4. DEVICE A MISSING PART CREATE/HISTORY MUST FAIL AFTER REVOCATION.
-- 5. DEVICE A CATALOG SEARCH AND MACHINE-SPARE LOOKUP MUST FAIL AFTER REVOCATION.
-- 6. DEVICE A FITMENT CHALLENGE LIST, HISTORY AND SUBMISSION MUST FAIL AFTER REVOCATION EVEN IF SUPABASE AUTH TOKEN REMAINS VALID.
-- 7. DEVICE A REFERRAL VERIFY, BENEFIT, SUPPLY AND ORDER MUST FAIL AFTER REVOCATION.
-- 8. DEVICE B REMAINS VALID AND EVERY DEALER RPC DERIVES THE DEALER SERVER-SIDE.
-- 9. PIN CHANGE/RECOVERY REVOKES CURRENT DEVICE SESSION.
-- 10. WRONG PIN LOCKOUT WORKS AND PLAINTEXT PIN NEVER APPEARS IN DB/LOGS.
-- 11. DUPLICATE ACTIVE app_users OR APPROVED NORMALIZED DEALER MOBILE FAILS CLOSED; SERVER NEVER GUESSES.
-- 12. SIGN OUT REVOKES ACTIVE DEVICE SESSION AND CLEARS LOCAL DEALER TOKEN.
-- 13. REFERRAL ORDER QUANTITY IS INTEGER 1..9999 AND REPEAT SUBMISSION IS IDEMPOTENT.
