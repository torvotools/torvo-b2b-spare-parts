-- TORVO V2 DEALER EMAIL OTP / SINGLE ACTIVE DEVICE STAGING CHECKLIST
-- RUN ONLY IN DEDICATED STAGING AFTER DEALER EMAIL OTP + FINAL DEVICE-BOUND MIGRATIONS.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('dealer_email_otp_challenges','dealer_device_sessions');
select indexname,indexdef from pg_indexes where schemaname='public' and tablename='dealer_device_sessions' and indexname='uq_dealer_one_active_device';
select p.proname,pg_get_function_identity_arguments(p.oid) args,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('dealer_email_otp_begin','dealer_email_otp_verify','dealer_start_device_session','dealer_validate_device_session','dealer_assert_my_device_session','dealer_revoke_device_sessions','dealer_workspace_catalog','dealer_workspace_order_history','dealer_item_rate','submit_purchase_order','get_dealer_machine_spares','dealer_knowledge_challenges','dealer_knowledge_history','submit_knowledge_answer','dealer_verify_customer_referral','dealer_confirm_referral_benefit','dealer_referral_supply_status','dealer_order_referral_item','dealer_confirm_sales_order_revision','request_additional_purchase_order','get_dealer_order_history_30d') order by p.proname,args;
select auth_user_id,count(*) active_rows from app_users where active=true and auth_user_id is not null group by auth_user_id having count(*)>1;
select lower(btrim(coalesce(email,''))) normalized_email,count(*) approved_rows from dealers where lower(coalesce(status,''))='approved' and nullif(btrim(coalesce(email,'')),'') is not null group by 1 having count(*)>1;
select to_regprocedure('public.dealer_item_rate(uuid,numeric)') legacy_rate,to_regprocedure('public.submit_purchase_order(jsonb)') legacy_po,to_regprocedure('public.get_dealer_machine_spares(uuid)') legacy_machine,to_regprocedure('public.dealer_knowledge_challenges()') legacy_challenges,to_regprocedure('public.dealer_confirm_sales_order_revision(uuid,integer)') legacy_confirm,to_regprocedure('public.request_additional_purchase_order(uuid,jsonb,text)') legacy_addon,to_regprocedure('public.get_dealer_order_history_30d()') legacy_order_history,to_regprocedure('public.dealer_workspace_catalog()') legacy_workspace,to_regprocedure('public.dealer_workspace_order_history()') legacy_workspace_history,to_regprocedure('public.dealer_verify_customer_referral(text)') legacy_verify,to_regprocedure('public.dealer_order_referral_item(text,numeric)') legacy_referral_order;
-- MANUAL STAGING GATES:
-- 1. APPROVED DEALER REGISTERED EMAIL + VALID EMAIL OTP + DEVICE A -> REAL SUPABASE DEALER AUTH + OPAQUE DEALER SESSION TOKEN.
-- 2. SAME DEALER + DEVICE B EMAIL OTP LOGIN -> DEVICE A REVOKED WITH NEW_DEVICE_LOGIN.
-- 3. DEVICE A HEARTBEAT/FOCUS/VISIBILITY MUST SIGN IT OUT WITHOUT RELOAD.
-- 4. REVOKED DEVICE A MUST FAIL PRIVATE WORKSPACE CATALOG, 30-DAY ORDER HISTORY, DEALER RATE LOOKUP AND PURCHASE ORDER SUBMISSION EVEN IF ITS SUPABASE AUTH TOKEN REMAINS VALID.
-- 5. REVOKED DEVICE A MUST FAIL MISSING-PART, CATALOG, MACHINE-SPARES, FITMENT, REFERRAL AND PROTECTED ORDER ACTIONS.
-- 6. DEVICE B REMAINS VALID; RATE GROUP AND DEALER ID ARE ALWAYS DERIVED SERVER-SIDE.
-- 7. PURCHASE ORDER AND ADDITIONAL ORDER QUANTITY MUST BE INTEGER 1..9999; DUPLICATE ITEM LINES MUST FAIL.
-- 8. ONLY THE EXACT LATEST SALES ORDER REVISION MAY RECEIVE DEALER OK.
-- 9. DEALER EMAIL CHANGE, NEW DEVICE LOGIN AND SIGN OUT MUST REVOKE THE PREVIOUS DEVICE SESSION AS APPLICABLE.
-- 10. EMAIL OTP EXPIRY, RESEND WAIT, MAX FAILED ATTEMPTS AND SINGLE-USE CONSUMPTION MUST WORK; PLAINTEXT OTP/SESSION TOKEN MUST NOT APPEAR IN DB/LOGS.
-- 11. DUPLICATE ACTIVE app_users OR DUPLICATE APPROVED NORMALIZED DEALER EMAIL MUST FAIL CLOSED.
-- 12. PUBLIC/ANON MUST HAVE NO EXECUTE PRIVILEGE ON PRIVATE WORKSPACE/ORDER/PROCUREMENT RPCS; TRUSTED EMAIL-OTP/SESSION RPCS REMAIN SERVICE-ROLE ONLY.
-- 13. dealer_workspace_order_history MUST RETURN ONLY THE ASSERTED DEALER'S SALES_ORDER/ESTIMATE ROWS FROM THE LAST 30 DAYS.
