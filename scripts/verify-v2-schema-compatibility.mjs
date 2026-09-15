import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const schema=read('supabase/v2-schema.sql');
const staff=read('supabase/v2-admin-issued-staff-access.sql');
const master=read('supabase/v2-master-salesman-access.sql');
const demand=read('supabase/v2-customer-product-demand-leads.sql');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['APP USER ROLE DOMAIN',/create table if not exists app_users[\s\S]*role text not null check\(role in \('owner','admin','salesman','accountant','store_keeper','dealer'\)\)/i.test(schema)],
 ['DEALER STATUS DOMAIN',/create table if not exists dealers[\s\S]*status text not null default 'pending' check\(status in \('pending','approved','hold','rejected','inactive','suspended'\)\)/i.test(schema)],
 ['CATALOG ITEM DOMAIN',/item_type text not null check\(item_type in \('machine','spare_part','accessory'\)\)/i.test(schema)],
 ['STAFF ROLE SUBSET MATCHES APP USERS',/staff_role text not null check\(staff_role in\('salesman','store_keeper','accountant'\)\)/i.test(staff)&&/target\.role<>p_staff_role/i.test(staff)],
 ['STAFF IDENTITY APP USER FK',/staff_access_identities[\s\S]*app_user_id uuid primary key references app_users\(id\) on delete cascade/i.test(staff)],
 ['STAFF DEVICE APP USER FK',/staff_authorized_devices[\s\S]*app_user_id uuid not null references app_users\(id\) on delete cascade/i.test(staff)],
 ['STAFF ONE ACTIVE DEVICE',/uq_staff_one_active_device[\s\S]*staff_authorized_devices\(app_user_id\) where revoked_at is null/i.test(staff)],
 ['MASTER SALESMAN APP ROLE COMPATIBLE',/target\.role not in\('owner','salesman'\)/i.test(master)&&/u\.role in\('owner','salesman'\)/i.test(master)],
 ['MASTER SALESMAN APP USER FK',/master_salesman_access[\s\S]*app_user_id uuid primary key references app_users\(id\) on delete cascade/i.test(master)],
 ['DEALER MAP ACTIVE SEMANTICS',/dealer_salesman_map/i.test(master)&&/x\.active=true/i.test(master)&&/x\.dealer_id=d\.id/i.test(master)&&/x\.salesman_user_id=u\.id/i.test(master)],
 ['DEMAND APP USER AUTH DOMAIN',/u\.role not in\('owner','admin'\)/i.test(demand)],
 ['DEMAND CUSTOMER FK PRIVATE',/customer_id uuid not null references customer_contacts\(id\) on delete restrict/i.test(demand)&&/revoke all on customer_product_demands from anon,authenticated/i.test(demand)],
 ['DEMAND PRODUCT FK RESTRICTED',/product_id uuid references catalog_items\(id\) on delete restrict/i.test(demand)],
 ['DEMAND FOUND DEALER FK SAFE',/found_dealer_id uuid references dealers\(id\) on delete set null/i.test(demand)],
 ['DEMAND DEALER STATUS COMPATIBLE',/x\.status='approved'/i.test(demand)&&/APPROVED DEALER REQUIRED/i.test(demand)],
 ['DEMAND AUDIT CONTRACT',/insert into audit_log\(actor_id,action,entity_type,entity_id,details\)/i.test(demand)&&/CUSTOMER_PRODUCT_DEMAND_UPDATED/i.test(demand)],
 ['DEMAND PUBLIC RPC RETURNS NO CONTACT',/returns table\(demand_id uuid,status text\)/i.test(demand)&&/returns table\(demand_id uuid,status text,torvo_help_requested boolean\)/i.test(demand)],
 ['CORE INSTALLED BEFORE STAFF',order.indexOf('v2-schema.sql')>=0&&order.indexOf('v2-admin-issued-staff-access.sql')>order.indexOf('v2-schema.sql')],
 ['CORE INSTALLED BEFORE MASTER SALESMAN',order.indexOf('v2-master-salesman-access.sql')>order.indexOf('v2-schema.sql')],
 ['CORE INSTALLED BEFORE DEMAND',order.indexOf('v2-customer-product-demand-leads.sql')>order.indexOf('v2-schema.sql')],
];
const failed=checks.filter(([,ok])=>!ok);
for(const [name,ok] of checks) console.log(`${ok?'PASS':'FAIL'} ${name}`);
if(failed.length){console.error(`SCHEMA COMPATIBILITY FAILED: ${failed.length} GATE(S)`);process.exit(1)}
console.log(`PASS SCHEMA COMPATIBILITY (${checks.length} GATES)`);
