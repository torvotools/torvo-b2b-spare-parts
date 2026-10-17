// TORVO V2 owner-delegated permissions static contract guard.
// Run: node scripts/verify-v2-owner-permissions.mjs
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>readFileSync(new URL('../'+p,import.meta.url),'utf8');
const sql=read('supabase/v2-owner-delegated-permissions.sql');
const ui=read('src/v2/components/UsersWorkspace.jsx');
const panel=read('src/v2/components/OwnerPermissionManagement.jsx');
const service=read('src/v2/services/ownerPermissions.js');
for(const name of ['owner_delegable_permission_catalog','owner_staff_permission_grants']){
 assert.equal((sql.match(new RegExp('create table if not exists public\\.'+name,'g'))||[]).length,1,name+' must be created exactly once');
}
for(const fn of ['owner_has_staff_permission','owner_grant_staff_permission','owner_revoke_staff_permission','owner_list_staff_permissions']){
 assert.equal((sql.match(new RegExp('create or replace function public\\.'+fn+'\\(','g'))||[]).length,1,fn+' must be defined exactly once');
}
assert.match(sql,/actor\.role<>'owner'/);
const listFunction=sql.slice(sql.indexOf('create or replace function public.owner_list_staff_permissions'),sql.indexOf('create or replace function public.owner_grant_staff_permission'));
assert.match(listFunction,/set search_path=public,pg_temp as \$\$/);
assert.match(listFunction,/end\$\$;/);
assert.doesNotMatch(listFunction,/as \$(?!\$)/);
assert.match(sql,/role='owner'/);
assert.match(sql,/permission_key text not null references public\.owner_delegable_permission_catalog/);
assert.match(sql,/revoke all on public\.owner_staff_permission_grants from public,anon,authenticated/);
assert.match(ui,/role==='owner'&&<OwnerPermissionManagement users=\{rows\}\/>/);
assert.match(panel,/grantOwnerStaffPermission/);
assert.match(panel,/revokeOwnerStaffPermission/);
assert.match(service,/owner_list_staff_permissions/);

// Verify incremental migrations actually guard sensitive RPCs and preserve Owner-only changes.
const staffGuard=read('supabase/v2-owner-staff-manage-rpc-guard.sql');
const websiteGuard=read('supabase/v2-owner-website-edit-rpc-guard.sql');
const snapshotGuard=read('supabase/v2-owner-admin-control-snapshot-guard.sql');
const roleGuard=read('supabase/v2-owner-active-staff-permission-guard.sql');
const revokeAll=read('supabase/v2-owner-revoke-all-matching-grants.sql');
const duplicateGuard=read('supabase/v2-owner-prevent-duplicate-active-grants.sql');
assert.match(staffGuard,/owner_has_staff_permission\('staff\.manage'\)/);
assert.match(staffGuard,/a\.role<>'owner'/);
assert.match(websiteGuard,/owner_has_staff_permission\('website\.edit'\)/);
assert.match(snapshotGuard,/owner_has_staff_permission\('website\.edit'\)/);
assert.match(roleGuard,/u\.role in \('admin','salesman','accountant','store_keeper'\)/);
assert.match(revokeAll,/staff_user_id=selected_grant\.staff_user_id and permission_key=selected_grant\.permission_key/);
assert.match(duplicateGuard,/pg_advisory_xact_lock/);
assert.match(duplicateGuard,/PERMISSION ALREADY GRANTED/);
assert.match(panel,/new Date\(expiry\)\.toISOString\(\)/);
assert.match(panel,/let cancelled=false/);
assert.match(panel,/disabled=\{busy\|\|loading\|\|!staffId\|\|currentGrant\}/);
assert.match(panel,/ALREADY GRANTED — REVOKE FIRST/);

const staffIdentityGuards=read('supabase/v2-owner-staff-access-rpc-guards.sql');
const otpEmailGuard=read('supabase/v2-owner-only-staff-otp-email.sql');
const scopedListing=read('supabase/v2-owner-staff-permission-list-scope.sql');
assert.equal((staffIdentityGuards.match(/owner_has_staff_permission\('staff\.manage'\)/g)||[]).length,2);
assert.equal((staffIdentityGuards.match(/OWNER ROLE PROTECTED/g)||[]).length,2);
assert.match(otpEmailGuard,/actor\.role<>'owner'/);
assert.match(scopedListing,/if p_staff_user_id is null then return; end if;/);

console.log('PASS: Owner delegated permission static contract. Live staging/RLS tests remain required.');
