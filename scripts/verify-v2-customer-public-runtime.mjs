import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const runtime=read('supabase/v2-customer-public-runtime-contract.sql');
const repairDevice=read('supabase/v2-customer-repair-device-bound.sql');
const managed=read('supabase/v2-admin-managed-experience.sql');
const network=read('supabase/v2-customer-dealer-referral-network.sql');
const order=read('supabase/V2_INSTALL_ORDER.md');
const safeBool=(alias,key)=>new RegExp(`case lower\\(coalesce\\(${alias}\\.setting_value->>'${key}','true'\\)\\) when 'true' then true when 'false' then false else true end`,`i`).test(runtime);
const unsafePublicBoolCast=/setting_value->>'(?:customer_active|business_active|customer_referral|repair_service|customer_catalog)'\s*\)::boolean/i.test(runtime);
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
 ['DEALER REPAIR BASE INBOX',/create or replace function dealer_repair_requirements/i.test(runtime)&&/r\.routed_dealer_id=did/.test(runtime)],
 ['DEALER REPAIR BASE ACTION',/create or replace function dealer_update_repair_requirement/i.test(runtime)&&/DEALER STATUS MUST BE ACCEPTED OR CLOSED/.test(runtime)],
 ['DEALER DEVICE SESSION FOUNDATION',/dealer_assert_my_device_session\(p_device_id,p_session_token\)/.test(network)],
 ['DEALER REPAIR LEGACY DROP',/drop function if exists public\.dealer_repair_requirements\(text,integer\)/i.test(repairDevice)&&/drop function if exists public\.dealer_update_repair_requirement\(uuid,text\)/i.test(repairDevice)],
 ['DEALER REPAIR DEVICE INBOX',/create or replace function dealer_repair_requirements\([\s\S]*p_device_id text[\s\S]*p_session_token text[\s\S]*did:=dealer_assert_my_device_session\(p_device_id,p_session_token\)/i.test(repairDevice)],
 ['DEALER REPAIR DEVICE ACTION',/create or replace function dealer_update_repair_requirement\([\s\S]*p_device_id text[\s\S]*p_session_token text[\s\S]*did:=dealer_assert_my_device_session\(p_device_id,p_session_token\)/i.test(repairDevice)],
 ['DEALER REPAIR ROUTED LOCK',/where id=p_requirement_id and routed_dealer_id=did[\s\S]*for update/i.test(repairDevice)],
 ['DEALER REPAIR APPROVED SERVICE',/d\.id=did and d\.status='approved' and d\.repair_service_available=true/.test(repairDevice)],
 ['DEALER ACCEPT BEFORE CLOSE',/ACCEPT REPAIR REQUIREMENT BEFORE CLOSING/.test(repairDevice)],
 ['DEALER REPAIR FINAL LOCK',/REPAIR REQUIREMENT ALREADY FINAL/.test(repairDevice)],
 ['DEALER REPAIR DEVICE AUDIT',/REPAIR_REQUIREMENT_ACCEPTED/.test(repairDevice)&&/REPAIR_REQUIREMENT_CLOSED/.test(repairDevice)&&/'device_bound',true/.test(repairDevice)],
 ['DEALER REPAIR DEVICE AUTH ONLY',/revoke all on function dealer_repair_requirements\(text,integer,text,text\),dealer_update_repair_requirement\(uuid,text,text,text\) from public,anon/i.test(repairDevice)&&/grant execute on function dealer_repair_requirements\(text,integer,text,text\),dealer_update_repair_requirement\(uuid,text,text,text\) to authenticated/i.test(repairDevice)],
 ['DEALER REPAIR FINAL INSTALL ORDER',order.indexOf('v2-customer-repair-device-bound.sql')>order.indexOf('v2-customer-public-runtime-contract.sql')&&order.indexOf('v2-customer-repair-device-bound.sql')>order.indexOf('v2-dealer-final-actions-device-bound.sql')],
 ['PUBLIC REFERRAL RPC',/create or replace function public_create_customer_referral/i.test(runtime)],
 ['REFERRAL CRYPTO FOUNDATION',/create extension if not exists pgcrypto/i.test(network)&&/gen_random_bytes\(6\)/i.test(runtime)],
 ['REFERRAL FOUNDATION BEFORE RUNTIME',order.indexOf('v2-customer-dealer-referral-network.sql')>=0&&order.indexOf('v2-customer-public-runtime-contract.sql')>order.indexOf('v2-customer-dealer-referral-network.sql')],
 ['REFERRAL CONSENT AUDIT',/customer_marketing_consent_events/i.test(runtime)&&/public_create_customer_referral/i.test(runtime)],
 ['PUBLIC BUSINESS SETTINGS',/create or replace function public_business_settings/i.test(runtime)],
 ['PUBLIC SETTINGS SAFE BOOLEAN PARSING',safeBool('w','customer_active')&&safeBool('w','business_active')&&safeBool('f','customer_referral')&&safeBool('f','repair_service')&&safeBool('f','customer_catalog')],
 ['PUBLIC SETTINGS NO UNSAFE BOOLEAN CAST',!unsafePublicBoolCast],
 ['EXACT PIN DEALER LOCATOR',/create or replace function public_find_torvo_dealers_expanded/i.test(runtime)&&/coalesce\(nullif\(d\.public_pin_code,''\),d\.pin_code\)=btrim\(p_pin_code\)/i.test(runtime)&&/'EXACT_PIN'::text/i.test(runtime)],
 ['VERIFIED PUBLIC DEALER ONLY',/d\.status='approved'[\s\S]*d\.customer_referral_enabled=true[\s\S]*d\.referral_profile_verified_at is not null/i.test(runtime)],
 ['REPAIR LOCATOR CAPABILITY FILTER',/not coalesce\(p_repair_only,false\) or d\.repair_service_available=true/i.test(runtime)],
 ['DUAL WHATSAPP ADMIN SETTINGS',/customer_number/.test(managed)&&/business_number/.test(managed)&&/customer_active/.test(managed)&&/business_active/.test(managed)],
 ['CUSTOMER WHATSAPP RUNTIME',/customer_active/.test(runtime)&&/(?:wv|setting_value)->>'customer_number'/.test(runtime)&&/7027751533/.test(runtime)],
 ['BUSINESS WHATSAPP RUNTIME',/business_active/.test(runtime)&&/(?:wv|setting_value)->>'business_number'/.test(runtime)&&/(?:wv|setting_value)->>'customer_number'/.test(runtime)],
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
console.log(`PASS CUSTOMER PUBLIC RUNTIME CONTRACT (${checks.length} GATES)`);
