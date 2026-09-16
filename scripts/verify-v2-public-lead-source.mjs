import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8'),fail=m=>{console.error(`PUBLIC LEAD SOURCE CONTRACT FAILED: ${m}`);process.exit(1)};
const service=read('src/v2/services/publicWebsite.js'),demandService=read('src/v2/services/customerProductDemand.js'),customerApp=read('src/v2/components/CustomerApp.jsx'),source=read('src/v2/services/publicLeadSource.js'),sql=read('supabase/v2-public-lead-source.sql'),order=read('supabase/V2_INSTALL_ORDER.md');
for(const v of['WEBSITE','FACEBOOK','INSTAGRAM','YOUTUBE','WHATSAPP','EMAIL','OTHER']){if(!source.includes(`'${v}'`)||!sql.includes(`'${v}'`))fail(`${v} SOURCE MISSING`)}
for(const rpc of['public_create_product_demand','public_create_customer_referral','public_create_repair_request']){if(!service.includes(`rpc('${rpc}'`)||!sql.includes(`function ${rpc}(`))fail(`${rpc} SERVICE/SQL CONTRACT MISMATCH`)}
if((service.match(/p_lead_source:source\(leadSource\)/g)||[]).length<3)fail('SOURCE-AWARE PUBLIC RPC ARGUMENTS MISSING');
if(!demandService.includes("from'./publicLeadSource'")||!demandService.includes('p_lead_source:leadSource(source)'))fail('CUSTOMER PRODUCT DEMAND SOURCE ATTRIBUTION MISSING');
if(!customerApp.includes('createPublicReferral')||!customerApp.includes('createPublicRepair'))fail('CUSTOMER APP REFERRAL/REPAIR MUST USE SOURCE-AWARE PUBLIC SERVICE');
if(/db\(\)\.rpc\('public_create_customer_referral'/.test(customerApp)||/db\(\)\.rpc\('public_create_repair_request'/.test(customerApp))fail('CUSTOMER APP BYPASSES SOURCE-AWARE REFERRAL/REPAIR SERVICE');
if(!sql.includes('customer_product_demands')||!sql.includes('customer_dealer_referrals')||!sql.includes('customer_repair_requirements'))fail('LEAD SOURCE PERSISTENCE TABLES MISSING');
if(/document\.referrer/i.test(sql))fail('RAW BROWSER REFERRER MUST NOT BE STORED IN SQL');
if(!order.includes('v2-public-lead-source.sql'))fail('LEAD SOURCE MIGRATION MISSING FROM INSTALL ORDER');
console.log('TORVO V2 public + customer app lead source contract OK');
