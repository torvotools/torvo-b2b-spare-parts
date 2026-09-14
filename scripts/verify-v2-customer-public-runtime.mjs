import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const runtime=read('supabase/v2-customer-public-runtime-contract.sql');
const managed=read('supabase/v2-admin-managed-experience.sql');
const network=read('supabase/v2-customer-dealer-referral-network.sql');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['REPAIR REQUIREMENTS TABLE',/create table if not exists customer_repair_requirements/i.test(runtime)],
 ['REPAIR REQUIREMENTS RLS',/alter table customer_repair_requirements enable row level security/i.test(runtime)],
 ['REPAIR REQUIREMENTS PRIVATE',/revoke all on customer_repair_requirements from anon,authenticated/i.test(runtime)],
 ['PUBLIC REPAIR RPC',/create or replace function public_create_repair_request/i.test(runtime)],
 ['ADMIN REPAIR INBOX',/create or replace function admin_repair_requirements/i.test(runtime)&&/OWNER OR ADMIN REQUIRED/.test(runtime)],
 ['ADMIN REPAIR ROUTING',/create or replace function admin_route_repair_requirement/i.test(runtime)&&/APPROVED REPAIR DEALER REQUIRED/.test(runtime)],
 ['REPAIR ROUTING REASON',/ROUTING REASON REQUIRED/.test(runtime)],
 ['REPAIR ROUTING AUDIT',/REPAIR_REQUIREMENT_ROUTED/.test(runtime)&&/CUSTOMER_REPAIR_REQUIREMENT/.test(runtime)],
 ['REPAIR TERMINAL LOCK',/CLOSED OR CANCELLED REQUIREMENT CANNOT BE ROUTED/.test(runtime)],
 ['REPAIR ADMIN AUTH ONLY',/revoke all on function admin_repair_requirements\(text,integer\),admin_route_repair_requirement\(uuid,uuid,text\) from public,anon/i.test(runtime)&&/grant execute on function admin_repair_requirements\(text,integer\),admin_route_repair_requirement\(uuid,uuid,text\) to authenticated/i.test(runtime)],
 ['DEALER REPAIR INBOX',/create or replace function dealer_repair_requirements/i.test(runtime)&&/r\.routed_dealer_id=did/.test(runtime)],
 ['DEALER REPAIR ACTION',/create or replace function dealer_update_repair_requirement/i.test(runtime)&&/DEALER STATUS MUST BE ACCEPTED OR CLOSED/.test(runtime)],
 ['DEALER REPAIR ACCOUNT LOCK',/u\.role<>'dealer'/.test(runtime)&&/d\.status='approved' and d\.repair_service_available=true/.test(runtime)],
 ['DEALER ROUTED REQUEST LOCK',/where id=p_requirement_id and routed_dealer_id=did for update/i.test(runtime)],
 ['DEALER ACCEPT BEFORE CLOSE',/ACCEPT REPAIR REQUIREMENT BEFORE CLOSING/.test(runtime)],
 ['DEALER REPAIR FINAL LOCK',/REPAIR REQUIREMENT ALREADY FINAL/.test(runtime)],
 ['DEALER REPAIR AUDIT',/REPAIR_REQUIREMENT_ACCEPTED/.test(runtime)&&/REPAIR_REQUIREMENT_CLOSED/.test(runtime)],
 ['DEALER REPAIR AUTH ONLY',/revoke all on function dealer_repair_requirements\(text,integer\),dealer_update_repair_requirement\(uuid,text\) from public,anon/i.test(runtime)&&/grant execute on function dealer_repair_requirements\(text,integer\),dealer_update_repair_requirement\(uuid,text\) to authenticated/i.test(runtime)],
 ['DEALER DEVICE SESSION FOUNDATION',/dealer_assert_my_device_session\(p_device_id,p_session_token\)/.test(network)],
 ['DEALER REPAIR DEVICE GAP VISIBLE',!/dealer_assert_my_device_session\(p_device_id,p_session_token\)/.test(runtime)],
 ['PUBLIC REFERRAL RPC',/create or replace function public_create_customer_referral/i.test(runtime)],
 ['REFERRAL CONSENT AUDIT',/customer_marketing_consent_events/i.test(runtime)&&/public_create_customer_referral/i.test(runtime)],
 ['PUBLIC BUSINESS SETTINGS',/create or replace function public_business_settings/i.test(runtime)],
 ['DUAL WHATSAPP ADMIN SETTINGS',/customer_number/.test(managed)&&/business_number/.test(managed)&&/customer_active/.test(managed)&&/business_active/.test(managed)],
 ['CUSTOMER WHATSAPP RUNTIME',/customer_active/.test(runtime)&&/setting_value->>'customer_number'/.test(runtime)],
 ['BUSINESS WHATSAPP RUNTIME',/business_active/.test(runtime)&&/setting_value->>'business_number'/.test(runtime)],
 ['CUSTOMER REFERRAL SWITCH',/customer_referral/.test(managed)],
 ['REPAIR SERVICE SWITCH',/repair_service/.test(managed)],
 ['CUSTOMER CATALOG SWITCH',/customer_catalog/.test(managed)],
 ['FEATURE BOOLEAN VALIDATION',/FEATURE SWITCH % MUST BE BOOLEAN/.test(managed)],
 ['RUNTIME INSTALL ORDER',order.indexOf('v2-admin-managed-experience.sql')>=0&&order.indexOf('v2-customer-public-runtime-contract.sql')>order.indexOf('v2-admin-managed-experience.sql')],
 ['NO PUBLIC CHECKOUT RPC',!/public_(checkout|payment|place_order)/i.test(runtime)],
];
let failed=0;
for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++;}
if(failed){console.error(`CUSTOMER PUBLIC RUNTIME CONTRACT FAILED: ${failed} GATE(S)`);process.exit(1)}
console.log('PASS CUSTOMER PUBLIC RUNTIME CONTRACT');
