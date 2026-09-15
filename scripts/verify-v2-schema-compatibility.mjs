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
 ['MASTER SALESMAN APP ROLE COMPATIBLE',/target\.role not in\('owner','salesman'\)/i.test(master)&&/u\.role in\('owner','salesman'\)/i.test(master)],
 ['DEALER MAP ACTIVE SEMANTICS',/dealer_salesman_map/i.test(master)&&/x\.active=true/i.test(master)&&/x\.dealer_id=d\.id/i.test(master)&&/x\.salesman_user_id=u\.id/i.test(master)],
 ['DEMAND APP USER AUTH DOMAIN',/u\.role not in\('owner','admin'\)/i.test(demand)],
 ['DEMAND DEALER STATUS COMPATIBLE',/x\.status='approved'/i.test(demand)&&/APPROVED DEALER REQUIRED/i.test(demand)],
 ['DEMAND AUDIT CONTRACT',/insert into audit_log\(actor_id,action,entity_type,entity_id,details\)/i.test(demand)&&/CUSTOMER_PRODUCT_DEMAND_UPDATED/i.test(demand)],
 ['CORE INSTALLED BEFORE STAFF',order.indexOf('v2-schema.sql')>=0&&order.indexOf('v2-admin-issued-staff-access.sql')>order.indexOf('v2-schema.sql')],
 ['CORE INSTALLED BEFORE DEMAND',order.indexOf('v2-customer-product-demand-leads.sql')>order.indexOf('v2-schema.sql')],
];
const failed=checks.filter(([,ok])=>!ok);
for(const [name,ok] of checks) console.log(`${ok?'PASS':'FAIL'} ${name}`);
if(failed.length){console.error(`SCHEMA COMPATIBILITY FAILED: ${failed.length} GATE(S)`);process.exit(1)}
console.log(`PASS SCHEMA COMPATIBILITY (${checks.length} GATES)`);
