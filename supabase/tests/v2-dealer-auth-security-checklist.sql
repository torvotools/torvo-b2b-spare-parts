-- TORVO V2 DEALER AUTH / SINGLE ACTIVE DEVICE STAGING CHECKLIST
-- RUN ONLY IN DEDICATED STAGING AFTER AUTH MIGRATIONS. THIS FILE IS A VERIFICATION CHECKLIST, NOT A PRODUCTION MIGRATION.

-- 1. REQUIRED PRIVATE TABLES MUST EXIST AND HAVE RLS ENABLED.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('dealer_login_credentials','dealer_device_sessions','dealer_pin_recovery_challenges');
-- 2. EXACTLY ONE PARTIAL UNIQUE INDEX MUST PREVENT TWO NON-REVOKED SESSIONS FOR ONE DEALER.
select indexname,indexdef from pg_indexes where schemaname='public' and tablename='dealer_device_sessions' and indexname='uq_dealer_one_active_device';
-- 3. TRUSTED AUTH FUNCTIONS MUST NOT BE EXECUTABLE BY PUBLIC/ANON/AUTHENTICATED.
select p.proname,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('dealer_set_pin','dealer_verify_pin','dealer_start_device_session','dealer_validate_device_session','dealer_revoke_device_sessions','dealer_create_recovery_challenge') order by p.proname;
-- 4. ACTIVE APP USER AUTH IDS MUST BE UNIQUE IN PRACTICE. THIS QUERY MUST RETURN ZERO ROWS.
select auth_user_id,count(*) active_rows from app_users where active=true and auth_user_id is not null group by auth_user_id having count(*)>1;
-- 5. APPROVED DEALER NORMALIZED MOBILES MUST BE UNIQUE. THIS QUERY MUST RETURN ZERO ROWS.
select right(regexp_replace(coalesce(mobile,''),'\D','','g'),10) normalized_mobile,count(*) approved_rows from dealers where lower(coalesce(status,''))='approved' group by 1 having count(*)>1;
-- 6. MANUAL: VALID PIN + DEVICE A -> REAL SUPABASE DEALER AUTH + OPAQUE DEALER SESSION TOKEN.
-- 7. MANUAL: SAME DEALER + DEVICE B LOGIN -> DEVICE A REVOKED WITH NEW_DEVICE_LOGIN.
-- 8. MANUAL: DEVICE A NEXT APP SESSION VALIDATION FAILS AND CLIENT SIGNS OUT.
-- 9. MANUAL: DEVICE A MISSING PART CREATE MUST FAIL BEFORE THE PRIVATE RPC IS CALLED.
-- 10. MANUAL: DEVICE A MISSING PART HISTORY REFRESH MUST FAIL BEFORE THE PRIVATE RPC IS CALLED.
-- 11. MANUAL: DEVICE B REMAINS VALID AND CAN CREATE/READ ONLY ITS OWN DEALER REQUESTS.
-- 12. MANUAL: PIN CHANGE/RECOVERY REVOKES CURRENT DEVICE SESSION.
-- 13. MANUAL: 5 WRONG PIN ATTEMPTS CAUSE TEMPORARY LOCK; PLAINTEXT PIN NEVER APPEARS IN DB/LOGS.
-- 14. MANUAL: DUPLICATE ACTIVE app_users ROWS FOR ONE auth_user_id -> DEALER AUTH IDENTITY AMBIGUOUS.
-- 15. MANUAL: DUPLICATE APPROVED NORMALIZED DEALER MOBILE -> DEALER LINK AMBIGUOUS; SERVER MUST NOT GUESS.
-- 16. MANUAL: dealer_my_profile RETURNS ONLY THE AUTHENTICATED APPROVED DEALER.
-- 17. MANUAL: SIGN OUT REVOKES THE ACTIVE DEVICE SESSION AND CLEARS LOCAL DEALER TOKEN.
