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

-- 6. MANUAL STAGING TEST: VALID PIN + DEVICE A -> WORKER RETURNS REAL SUPABASE DEALER AUTH + OPAQUE DEALER SESSION TOKEN.
-- 7. MANUAL STAGING TEST: SAME DEALER + DEVICE B LOGIN -> DEVICE A SESSION ROW GETS REVOKED_AT + NEW_DEVICE_LOGIN.
-- 8. MANUAL STAGING TEST: DEVICE A NEXT PRIVATE SESSION VALIDATION FAILS AND CLIENT SIGNS OUT.
-- 9. MANUAL STAGING TEST: DEVICE B REMAINS VALID AND LAST_SEEN_AT ADVANCES.
-- 10. MANUAL STAGING TEST: PIN CHANGE/RECOVERY REVOKES THE CURRENT DEVICE SESSION.
-- 11. MANUAL STAGING TEST: 5 WRONG PIN ATTEMPTS CAUSE TEMPORARY LOCK; PLAINTEXT PIN NEVER APPEARS IN DB/LOGS.
-- 12. MANUAL STAGING TEST: DUPLICATE ACTIVE app_users ROWS FOR ONE auth_user_id CAUSE DEALER AUTH IDENTITY AMBIGUOUS; NO PRIVATE PROFILE IS RETURNED.
-- 13. MANUAL STAGING TEST: DUPLICATE APPROVED NORMALIZED DEALER MOBILE CAUSES DEALER LINK AMBIGUOUS; SERVER MUST NOT GUESS A DEALER.
-- 14. MANUAL STAGING TEST: dealer_my_profile RETURNS ONLY THE AUTHENTICATED APPROVED DEALER.
-- 15. MANUAL STAGING TEST: MISSING PART CREATE/HISTORY REMAIN SELF-SCOPED AFTER DEVICE SESSION VALIDATION.
