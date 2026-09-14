-- TORVO V2 ADMIN-ISSUED STAFF ACCESS STAGING CHECKLIST
-- RUN AFTER v2-staff-whatsapp-auth.sql + v2-admin-issued-staff-access.sql IN DEDICATED STAGING.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('staff_access_identities','staff_one_time_passwords','staff_authorized_devices','staff_auth_sessions');
select indexname,indexdef from pg_indexes where schemaname='public' and indexname in('uq_staff_access_username_upper','uq_staff_one_active_device');
select p.proname,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('admin_upsert_staff_access','admin_issue_staff_one_time_password','admin_approve_staff_device','admin_revoke_staff_access','staff_verify_one_time_password','staff_create_verified_session') order by p.proname;
-- MANUAL END-TO-END GATES:
-- 1. ADMIN CREATES SALESMAN USERNAME SM@01 + EMPLOYEE NAME WITHOUT STAFF MOBILE NUMBER.
-- 2. ADMIN ISSUES PASSWORD A, THEN B: A IS REVOKED BEFORE B IS USED.
-- 3. APPROVE SALESMAN DEVICE A AS mobile_app; trusted worker login with B succeeds once, consumes B and creates admin_one_time_password staff_auth_session.
-- 4. REPLAY B FAILS. UNAPPROVED DEVICE B FAILS EVEN WITH CORRECT PASSWORD.
-- 5. APPROVE REPLACEMENT DEVICE B: DEVICE A IS REVOKED; only B remains active.
-- 6. STORE KEEPER follows same mobile_app-only rule.
-- 7. ACCOUNTANT on mobile_app fails; approved desktop succeeds with one-time password.
-- 8. ACCOUNTANT logout/revoke then requires a freshly issued password for next login.
-- 9. OWNER/ADMIN must be rejected by admin_one_time_password employee login method.
-- 10. SALESMAN/STORE KEEPER/ACCOUNTANT must be rejected by emergency-code verification; emergency recovery is OWNER/ADMIN only.
-- 11. ADMIN REVOKE STAFF ACCESS revokes unused password, authorized device and all active staff_auth_sessions.
-- 12. CHANGE EMPLOYEE NAME without exposing/recovering any prior plaintext password.
-- 13. staff_verify_one_time_password and staff_create_verified_session are not executable by public/anon/authenticated; trusted server only.
-- 14. Worker response never returns password/hash/service secret and generic failure does not reveal which credential failed.
-- 15. MASTER SALESMAN all-dealer access is verified separately as explicit server-side permission/mapping.
