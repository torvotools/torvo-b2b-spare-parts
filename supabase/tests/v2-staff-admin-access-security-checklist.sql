-- TORVO V2 ADMIN-ISSUED STAFF ACCESS STAGING CHECKLIST
-- RUN ONLY AFTER v2-admin-issued-staff-access.sql IN DEDICATED STAGING.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('staff_access_identities','staff_one_time_passwords','staff_authorized_devices');
select indexname,indexdef from pg_indexes where schemaname='public' and indexname in('uq_staff_access_username_upper','uq_staff_one_active_device');
select p.proname,has_function_privilege('public',p.oid,'EXECUTE') public_exec,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('admin_upsert_staff_access','admin_issue_staff_one_time_password','admin_approve_staff_device','admin_revoke_staff_access','staff_verify_one_time_password') order by p.proname;
-- MANUAL STAGING GATES:
-- 1. ADMIN CREATES SALESMAN USERNAME SM@01 + EMPLOYEE NAME; MOBILE NUMBER IS NOT REQUIRED BY THIS ACCESS RECORD.
-- 2. ADMIN ISSUES PASSWORD A, THEN PASSWORD B: PASSWORD A MUST BE REVOKED BEFORE B IS USED.
-- 3. APPROVE SALESMAN DEVICE A AS mobile_app; LOGIN WITH B ON DEVICE A SUCCEEDS ONCE AND B IS MARKED used_at.
-- 4. REPLAY PASSWORD B MUST FAIL.
-- 5. SAME USERNAME/PASSWORD ON UNAPPROVED DEVICE B MUST FAIL DEVICE APPROVAL REQUIRED.
-- 6. ADMIN APPROVES REPLACEMENT DEVICE B: DEVICE A MUST BECOME REVOKED; ONLY B REMAINS ACTIVE.
-- 7. STORE KEEPER MUST FOLLOW THE SAME mobile_app DEVICE RULE.
-- 8. ACCOUNTANT LOGIN ON mobile_app MUST FAIL; APPROVED desktop IS REQUIRED.
-- 9. ACCOUNTANT PASSWORD IS ONE USE; AFTER LOGOUT A FRESH ADMIN-ISSUED PASSWORD IS REQUIRED.
-- 10. ADMIN REVOKE STAFF ACCESS MUST REVOKE UNUSED PASSWORD, ACTIVE DEVICE AND ALL ACTIVE staff_auth_sessions.
-- 11. CHANGE EMPLOYEE NAME ON THE SAME STAFF ID AND CONFIRM OLD TEMPORARY PASSWORD DOES NOT BECOME READABLE OR REUSABLE.
-- 12. staff_verify_one_time_password MUST NOT BE EXECUTABLE BY public/anon/authenticated; TRUSTED SERVER ONLY.
-- 13. PASSWORD HASH MUST NEVER EQUAL THE PLAINTEXT PASSWORD AND MUST NEVER BE RETURNED TO CLIENT.
-- 14. MASTER SALESMAN ALL-DEALER ACCESS MUST BE VERIFIED SEPARATELY AS SERVER-SIDE MAPPING/PERMISSION.
