import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const runtime=read('supabase/v2-customer-public-runtime-contract.sql');
const managed=read('supabase/v2-admin-managed-experience.sql');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['REPAIR REQUIREMENTS TABLE',/create table if not exists customer_repair_requirements/i.test(runtime)],
 ['REPAIR REQUIREMENTS RLS',/alter table customer_repair_requirements enable row level security/i.test(runtime)],
 ['REPAIR REQUIREMENTS PRIVATE',/revoke all on customer_repair_requirements from anon,authenticated/i.test(runtime)],
 ['PUBLIC REPAIR RPC',/create or replace function public_create_repair_request/i.test(runtime)],
 ['PUBLIC REFERRAL RPC',/create or replace function public_create_customer_referral/i.test(runtime)],
 ['REFERRAL CONSENT AUDIT',/customer_marketing_consent_events/i.test(runtime)&&/public_create_customer_referral/i.test(runtime)],
 ['PUBLIC BUSINESS SETTINGS',/create or replace function public_business_settings/i.test(runtime)],
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
