-- TORVO V2 BACKUP / DISASTER-RECOVERY STAGING SECURITY CHECKLIST
-- TEST/STAGING ONLY. Execute after the authoritative backup migration group.
-- Never treat metadata or a request as proof that an artifact exists or is restorable.

begin;

-- 1. REQUIRED OBJECTS
select to_regclass('public.backup_runs') backup_runs,
       to_regclass('public.backup_settings') backup_settings,
       to_regclass('public.project_backup_changes') project_backup_changes,
       to_regclass('public.backup_restore_manifests') backup_restore_manifests;

-- 2. RLS MUST BE ENABLED
select c.relname,c.relrowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in('backup_runs','backup_settings','project_backup_changes','backup_restore_manifests')
order by c.relname;

-- 3. BROWSER ROLES MUST NOT HAVE DIRECT BACKUP TABLE WRITES
select grantee,table_name,privilege_type
from information_schema.role_table_grants
where table_schema='public'
 and table_name in('backup_runs','backup_settings','project_backup_changes','backup_restore_manifests')
 and grantee in('anon','authenticated')
 and privilege_type in('INSERT','UPDATE','DELETE','TRUNCATE')
order by table_name,grantee,privilege_type;
-- EXPECT ZERO ROWS.

-- 4. TRUSTED WORKER FUNCTIONS MUST NOT BE EXECUTABLE BY BROWSER ROLES
select p.proname,
 has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in('worker_start_backup','worker_complete_backup','worker_fail_backup')
order by p.proname;
-- EXPECT FALSE/FALSE FOR EVERY ROW.

-- 5. OWNER/ADMIN CONTROL RPC CONTRACT
select p.proname,pg_get_function_identity_arguments(p.oid) arguments,p.prosecdef security_definer
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
 'get_backup_control_status','request_backup_run','get_backup_settings','save_backup_settings',
 'get_pending_project_backup_changes','request_channel_backup','get_backup_health'
) order by p.proname;

-- 6. VERIFIED ARTIFACT INTEGRITY
select id,status,encrypted,includes_secrets,checksum_sha256,verified_at
from backup_runs
where status='verified' and (
 encrypted is distinct from true or includes_secrets is distinct from false or
 checksum_sha256 is null or checksum_sha256 !~ '^[A-Fa-f0-9]{64}$' or verified_at is null
);
-- EXPECT ZERO ROWS.

-- 7. VERIFIED FULL RESTORE POINT MUST HAVE A RESTORE MANIFEST
select b.id,b.status,b.backup_type
from backup_runs b left join backup_restore_manifests m on m.backup_run_id=b.id
where b.status='verified' and b.backup_type='full_restore_point' and m.id is null;
-- EXPECT ZERO ROWS AFTER TRUSTED-WORKER COMPLETION TESTS.

-- 8. MANIFEST INTEGRITY
select id,backup_run_id,encrypted,includes_secrets,checksum_sha256
from backup_restore_manifests
where encrypted is distinct from true or includes_secrets is distinct from false or checksum_sha256 !~ '^[A-Fa-f0-9]{64}$';
-- EXPECT ZERO ROWS.

rollback;

-- 9. REAL AUTH SESSION TESTS (RUN SEPARATELY)
-- OWNER + ADMIN: status/settings/health/request actions allowed by policy.
-- SALESMAN / ACCOUNTANT / STORE KEEPER / DEALER / ANON: backup control actions denied.
-- get_backup_health(): HEALTHY <24H; WARNING >=24H AND <48H; CRITICAL >=48H OR NO VERIFIED BACKUP.
-- REQUESTED/RUNNING/FAILED BACKUPS MUST NEVER RESET VERIFIED BACKUP AGE.

-- 10. TRUSTED WORKER / IDEMPOTENCY TESTS (SERVER CREDENTIALS ONLY)
-- Start one real staging request with one worker_job_id and complete it using a real encrypted staging artifact/checksum.
-- Replaying identical completion must be harmless. Different worker/checksum replacement must fail.
-- Browser sessions must never call worker_* functions. Failed work remains auditable and does not count as VERIFIED.

-- 11. RESTORE DRILL RELEASE GATE
-- Restore a VERIFIED FULL RESTORE POINT into clean staging; validate SHA-256 + manifest; rerun critical role/order/payment/stock/privacy tests.
