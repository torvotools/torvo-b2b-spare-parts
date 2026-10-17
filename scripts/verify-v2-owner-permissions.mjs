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
console.log('PASS: Owner delegated permission static contract. Live staging/RLS tests remain required.');
