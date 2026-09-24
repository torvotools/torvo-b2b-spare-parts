-- TORVO V2 STAFF MASTER-EMAIL OTP + DEVICE ACCESS STAGING CHECKLIST
-- RUN AFTER v2-staff-whatsapp-auth.sql + v2-admin-issued-staff-access.sql + v2-staff-email-otp.sql IN DEDICATED STAGING.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in('staff_access_identities','staff_authorized_devices','staff_auth_sessions','staff_email_otp_challenges','staff_otp_settings')
order by c.relname;

select indexname,indexdef from pg_indexes
where schemaname='public' and indexname in('uq_staff_access_username_upper','uq_staff_one_active_device','idx_staff_email_otp_active')
order by indexname;

select p.proname,
 has_function_privilege('public',p.oid,'EXECUTE') public_exec,
 has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,
 has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec,
 has_function_privilege('service_role',p.oid,'EXECUTE') service_role_exec
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
 'admin_upsert_staff_access','admin_approve_staff_device','admin_revoke_staff_access',
 'admin_set_staff_otp_email','staff_email_otp_begin','staff_email_otp_verify','staff_create_verified_session'
) order by p.proname;

select
 to_regclass('public.staff_one_time_passwords') is null legacy_password_table_removed,
 to_regprocedure('public.admin_issue_staff_one_time_password(uuid,text,integer)') is null legacy_issue_rpc_removed,
 to_regprocedure('public.staff_verify_one_time_password(text,text,text,text)') is null legacy_verify_rpc_removed;

-- MANUAL END-TO-END GATES:
-- 1. OWNER/ADMIN sets ONE master OTP email using admin_set_staff_otp_email; changing it revokes unused OTP challenges.
-- 2. Configure SALESMAN staff ID + employee name and approve the exact native installation ID as mobile_app.
-- 3. SALESMAN begin sends a server-generated 6-digit OTP only to the master email and identifies role, user ID, employee name and login context.
-- 4. Correct OTP on the approved installation succeeds once; replay fails. Wrong/unapproved installation fails.
-- 5. SALESMAN native session may persist up to 30 days on the same installation; uninstall/reinstall creates a new installation ID and requires approval + new OTP.
-- 6. STORE KEEPER follows the same mobile_app installation and 30-day rule.
-- 7. ACCOUNTANT requires an approved desktop device; mobile_app is rejected. Logout/browser close requires a fresh OTP next login.
-- 8. ADMIN requires an approved desktop device; logout/browser close requires a fresh OTP next login.
-- 9. OWNER is excluded from normal staff-email OTP and retains the separate Owner secure-access path.
-- 10. Approving a replacement staff device revokes the prior active approved device.
-- 11. Admin revoke disables staff access, revokes approved device(s), active OTP challenge(s) and active staff auth sessions.
-- 12. OTP begin/verify and staff_create_verified_session are service_role-only; browser clients cannot call these RPCs directly.
-- 13. OTP plaintext/hash/service secret is never returned to browser or stored as plaintext.
-- 14. staff_one_time_passwords, admin_issue_staff_one_time_password and staff_verify_one_time_password remain absent.
-- 15. MASTER SALESMAN all-dealer access is verified separately as explicit server-side permission/mapping.
