-- TORVO V2 MASTER SALESMAN STAGING SECURITY GATES
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='master_salesman_access';
select p.proname,has_function_privilege('anon',p.oid,'EXECUTE') anon_exec,has_function_privilege('authenticated',p.oid,'EXECUTE') auth_exec from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('admin_set_master_salesman','is_master_salesman','salesman_visible_dealers') order by p.proname;
-- MANUAL GATES:
-- 1. NORMAL SALESMAN sees only active dealer_salesman_map dealers.
-- 2. UNMAPPED approved dealer must not appear to normal salesman.
-- 3. OWNER/ADMIN grants MASTER SALESMAN; same user now sees all approved dealers.
-- 4. MASTER grant must create audit_log MASTER_SALESMAN_GRANTED.
-- 5. OWNER/ADMIN revokes MASTER; all-dealer visibility ends immediately.
-- 6. Revocation must create audit_log MASTER_SALESMAN_REVOKED.
-- 7. Non-admin cannot grant/revoke master access.
-- 8. Dealer/Accountant/Store Keeper cannot call salesman_visible_dealers successfully.
-- 9. OWNER may be explicitly granted Master Salesman for operational use.
-- 10. Client cannot turn Master Salesman on with a local flag; server table/function is authoritative.
