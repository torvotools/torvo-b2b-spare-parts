import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const schema=read('supabase/v2-schema.sql');
const staff=read('supabase/v2-admin-issued-staff-access.sql');
const master=read('supabase/v2-master-salesman-access.sql');
const dealerAuth=read('supabase/v2-dealer-pin-auth.sql');
const demand=read('supabase/v2-customer-product-demand-leads.sql');
const routing=read('supabase/v2-customer-demand-dealer-routing.sql');
const lifecycle=read('supabase/v2-customer-demand-lead-lifecycle.sql');
const found=read('supabase/v2-customer-demand-found-lifecycle.sql');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['APP USER ROLE DOMAIN',/create table if not exists app_users[\s\S]*role text not null check\(role in \('owner','admin','salesman','accountant','store_keeper','dealer'\)\)/i.test(schema)],
 ['DEALER STATUS DOMAIN',/create table if not exists dealers[\s\S]*status text not null default 'pending' check\(status in \('pending','approved','hold','rejected','inactive','suspended'\)\)/i.test(schema)],
 ['DEALER SHOP NAME CONTRACT',/create table if not exists dealers[\s\S]*shop_name text not null/i.test(schema)&&/x\.shop_name\s*,\s*l\.routing_stage/i.test(lifecycle)],
 ['CATALOG ITEM DOMAIN',/item_type text not null check\(item_type in \('machine','spare_part','accessory'\)\)/i.test(schema)],
 ['CANONICAL DEALER LINK FK',/alter table app_users add column if not exists dealer_id uuid references dealers\(id\) on delete restrict/i.test(dealerAuth)],
 ['ONE APP USER PER DEALER',/create unique index if not exists uq_app_users_dealer_identity on app_users\(dealer_id\) where dealer_id is not null/i.test(dealerAuth)],
 ['DEALER ASSERT USES DIRECT LINK',/v_user\.dealer_id is null/i.test(dealerAuth)&&/where id=v_user\.dealer_id and lower\(coalesce\(status,''\)\)='approved'/i.test(dealerAuth)],
 ['DEALER ASSERT NO MOBILE RELINK',!/v_mobile:=right\(regexp_replace\(coalesce\(v_user\.mobile/i.test(dealerAuth)&&!/where right\(regexp_replace\(coalesce\(d\.mobile/i.test(dealerAuth)],
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
 ['DEMAND BACKEND PAYLOAD BOUNDS',/length\(n\)<2 or length\(n\)>120/.test(demand)&&/length\(q\)<2 or length\(q\)>200/.test(demand)&&/length\(coalesce\(b,''\)\)>120/.test(demand)&&/length\(coalesce\(model,''\)\)>120/.test(demand)&&/length\(coalesce\(note,''\)\)>500/.test(demand)],
 ['DEMAND HELP NORMALIZED MOBILE PROOF',/public_request_torvo_product_help[\s\S]*right\(regexp_replace\(coalesce\(c\.mobile,''\),'\\D','','g'\),10\)=m/i.test(demand)],
 ['ROUTING DEMAND FK',/demand_id uuid not null references customer_product_demands\(id\) on delete cascade/i.test(routing)],
 ['ROUTING DEALER FK',/dealer_id uuid not null references dealers\(id\) on delete restrict/i.test(routing)],
 ['ROUTING DEVICE ASSERTION',/dealer_assert_my_device_session\(p_device_id,p_session_token\)/i.test(routing)],
 ['ROUTING CONTACT PRIVACY',/returns table\(lead_id uuid,demand_id uuid,search_text text,pin_code text,brand text,model_number text,requirement_note text,routing_stage text,status text,sent_at timestamptz\)/i.test(routing)],
 ['LIFECYCLE OWNER ADMIN ONLY',/u\.role not in\('owner','admin'\)/i.test(lifecycle)],
 ['FOUND OWNER ADMIN ONLY',/u\.role not in\('owner','admin'\)/i.test(found)],
 ['FOUND APPROVED DEALER CONTRACT',/x\.status='approved'/i.test(found)&&/APPROVED DEALER REQUIRED/i.test(found)],
 ['FOUND CUSTOMER MOBILE PROOF',/join customer_contacts c on c\.id=d\.customer_id[\s\S]*right\(regexp_replace\(coalesce\(c\.mobile,''\),'\\D','','g'\),10\)=m/i.test(found)],
 ['FOUND RESULT AVAILABLE PRIVACY',/case when d\.status='available' then d\.found_dealer_id else null end/i.test(found)&&/case when d\.status='available' then d\.found_contact_note else null end/i.test(found)&&/case when d\.status='available' then d\.available_at else null end/i.test(found)],
 ['CORE INSTALLED BEFORE STAFF',order.indexOf('v2-schema.sql')>=0&&order.indexOf('v2-admin-issued-staff-access.sql')>order.indexOf('v2-schema.sql')],
 ['CORE BEFORE DEALER AUTH',order.indexOf('v2-dealer-pin-auth.sql')>order.indexOf('v2-schema.sql')],
 ['CORE INSTALLED BEFORE MASTER SALESMAN',order.indexOf('v2-master-salesman-access.sql')>order.indexOf('v2-schema.sql')],
 ['CORE INSTALLED BEFORE DEMAND',order.indexOf('v2-customer-product-demand-leads.sql')>order.indexOf('v2-schema.sql')],
 ['DEMAND BEFORE ROUTING',order.indexOf('v2-customer-demand-dealer-routing.sql')>order.indexOf('v2-customer-product-demand-leads.sql')],
 ['ROUTING BEFORE LIFECYCLE',order.indexOf('v2-customer-demand-lead-lifecycle.sql')>order.indexOf('v2-customer-demand-dealer-routing.sql')],
 ['LIFECYCLE BEFORE FOUND',order.indexOf('v2-customer-demand-found-lifecycle.sql')>order.indexOf('v2-customer-demand-lead-lifecycle.sql')],
];
const failed=checks.filter(([,ok])=>!ok);
for(const [name,ok] of checks) console.log(`${ok?'PASS':'FAIL'} ${name}`);
if(failed.length){console.error(`SCHEMA COMPATIBILITY FAILED: ${failed.length} GATE(S)`);process.exit(1)}
console.log(`PASS SCHEMA COMPATIBILITY (${checks.length} GATES)`);
