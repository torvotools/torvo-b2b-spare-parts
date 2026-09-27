-- TORVO V2 STAFF MASTER-EMAIL OTP + ONE-ACTIVE-SESSION STAGING CHECKLIST
-- FINAL AUTH MODEL: no manual staff device registration/approval. Device ID is hidden session binding only.
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in('staff_access_identities','staff_auth_sessions','staff_email_otp_challenges','staff_otp_settings')
order by c.relname;

select indexname,indexdef from pg_indexes
where schemaname='public' and indexname in('uq_staff_access_username_upper','uq_staff_one_active_session','idx_staff_email_otp_active')
order by indexname;

select
 to_regclass('public.staff_authorized_devices') is null manual_device_table_removed,
 to_regprocedure('public.admin_approve_staff_device(uuid,text,text)') is null manual_device_approval_rpc_removed,
 to_regprocedure('public.bootstrap_initial_owner_staff_access(text,text,text)') is null old_device_bootstrap_removed,
 to_regprocedure('public.bootstrap_initial_owner_staff_access(text,text)') is not null identity_only_owner_bootstrap_present;

select p.proname,
 has_function_privilege('public',p.oid,'EXECUTE') public_exec,
 has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,
 has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_exec,
 has_function_privilege('service_role',p.oid,'EXECUTE') service_role_exec
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
 'admin_upsert_staff_access','admin_revoke_staff_access','admin_set_staff_otp_email',
 'staff_email_otp_begin','staff_email_otp_verify','staff_create_verified_session',
 'bootstrap_initial_owner_staff_access'
) order by p.proname;

-- MANUAL END-TO-END GATES:
-- 1. OWNER bootstrap creates OR@000 identity only; no device approval/registration exists.
-- 2. OWNER/ADMIN configures staff identity and one master OTP email.
-- 3. OWNER/ADMIN/ACCOUNTANT/SALESMAN/STORE KEEPER login uses server-generated 6-digit master-email OTP.
-- 4. OTP is bound to the initiating hidden device/session identifier, expires, is single-use and locks after five failures.
-- 5. Successful OTP login revokes every prior active session for that staff identity before creating the new one.
-- 6. A prior browser/app session becomes invalid after a successful new login.
-- 7. Device identifier remains backend/session security metadata only; user never needs manual device approval.
-- 8. Admin revoke disables staff identity and active staff sessions.
-- 9. OTP begin/verify and staff_create_verified_session remain service_role-only.
-- 10. Plain OTP/service secrets are never returned to browser or stored as plaintext.
