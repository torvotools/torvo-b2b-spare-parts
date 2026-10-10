import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8'),fail=m=>{console.error(`PUBLIC SERVICE EXPORT CONTRACT FAILED: ${m}`);process.exit(1)};
const service=read('src/v2/services/publicWebsite.js');
const publicUi=read('src/v2/components/PublicWebsitePreview.jsx');
const requirementForm=read('src/v2/components/PublicProductRequirementForm.jsx');
const leadSql=read('supabase/v2-public-lead-source.sql');
const enquirySql=read('supabase/v2-customer-demand-dealer-referral-analytics.sql');
const consentSql=read('supabase/v2-customer-marketing-consent-segmentation.sql');
const supportSql=read('supabase/v2-customer-support-opportunity-center.sql');
const consumers=['src/v2/components/PublicWebsitePreview.jsx','src/v2/components/CustomerApp.jsx','src/v2/components/PublicProductRequirementForm.jsx','src/v2/components/PublicDealerRegistrationForm.jsx'];
const exported=new Set([...service.matchAll(/export\s+async\s+function\s+([A-Za-z_$][\w$]*)/g)].map(x=>x[1]));
for(const file of consumers){const text=read(file);for(const m of text.matchAll(/import\s*\{([^}]+)\}\s*from\s*['"]\.\.\/services\/publicWebsite['"]/g)){for(const raw of m[1].split(',')){const spec=raw.trim();if(!spec)continue;const imported=spec.split(/\s+as\s+/)[0].trim();if(!exported.has(imported))fail(`${file} IMPORTS ${imported} BUT publicWebsite.js DOES NOT EXPORT IT`)}}}
for(const required of['createProductDemand','createProductEnquiry','optOutProductEnquiryMarketing','createProductRequirement','optOutProductRequirementMarketing','createReferral','createRepair','findDealers','loadDealerProfile','registerDealer','createCustomerComplaint'])if(!exported.has(required))fail(`REQUIRED PUBLIC SERVICE EXPORT MISSING: ${required}`);
for(const fn of['createProductEnquiry','createProductRequirement']){const body=service.match(new RegExp(`export\\s+async\\s+function\\s+${fn}\\b([\\s\\S]*?)(?=export\\s+(?:async\\s+)?function|$)`))?.[1]||'';if(!body.includes('createProductDemand'))fail(`${fn} MUST ROUTE THROUGH AUTHORITATIVE PRODUCT DEMAND SERVICE`)}
for(const rpc of['public_create_product_demand','public_create_customer_referral','public_create_repair_request']){if(!service.includes(`rpc('${rpc}'`))fail(`${rpc} CLIENT CALL MISSING`);if(!leadSql.includes(`function ${rpc}(`))fail(`${rpc} SOURCE-AWARE SQL OVERLOAD MISSING`)}
if(!service.includes('p_lead_source:source(leadSource)'))fail('PUBLIC SERVICE LEAD SOURCE ARGUMENT MISSING');
const dealerFind=service.match(/export\s+async\s+function\s+findDealers\b([\s\S]*?)(?=export\s+async\s+function|$)/)?.[1]||'';
for(const token of['VALID 6 DIGIT PIN CODE REQUIRED',"rpc('public_find_torvo_dealers_expanded'",'p_repair_only:repairOnly===true','p_limit:12',"slice(0,12)"])if(!dealerFind.includes(token))fail(`DEALER LOCATOR SAFETY MISSING: ${token}`);
const dealerProfile=service.match(/export\s+async\s+function\s+loadDealerProfile\b([\s\S]*?)(?=export\s+async\s+function|$)/)?.[1]||'';
for(const token of["uuid(dealerId,'DEALER ID')","rpc('public_dealer_profile'","dealer_id:uuid(row.dealer_id||id,'DEALER ID')",'shop_name:text(row.shop_name,160)','address:text(row.address,300)','pin_code:pin6(row.pin_code)','mobile:safePhone(row.mobile)','whatsapp:safePhone(row.whatsapp)','map_url:safeHttps(row.map_url)','repair_service:row.repair_service===true'])if(!dealerProfile.includes(token))fail(`PUBLIC DEALER PROFILE BOUNDARY MISSING: ${token}`);
for(const forbidden of['rate_a','rate_b','rate_c','purchase_cost','dealer_rate'])if(dealerProfile.toLowerCase().includes(forbidden))fail(`PUBLIC DEALER PROFILE MUST NOT EXPOSE PRIVATE FIELD: ${forbidden}`);
const enquiryBody=service.match(/export\s+async\s+function\s+createProductEnquiry\b([\s\S]*?)(?=export\s+(?:async\s+)?function|$)/)?.[1]||'';
for(const token of ["selected.some(x=>x.quantity>9999)",'TOTAL QUANTITY PER PRODUCT MUST BE 1-9999'])if(!enquiryBody.includes(token))fail(`PUBLIC ENQUIRY COMBINED QUANTITY GUARD MISSING: ${token}`);
if(enquiryBody.includes('Math.min(quantity,9999)'))fail('PUBLIC ENQUIRY MUST NOT SILENTLY TRUNCATE CUSTOMER QUANTITY');
for(const token of['createProductDemand','demand_ids','demand_sync_complete','marketing:false'])if(!enquiryBody.includes(token))fail(`CANONICAL PRODUCT ENQUIRY DEMAND CONTRACT MISSING: ${token}`);
for(const legacy of["rpc('public_create_product_enquiry'","rpc('public_track_dealer_referral_event'"])if(service.includes(legacy))fail(`RETIRED LEGACY CUSTOMER RPC CALLER PRESENT: ${legacy}`);
for(const fn of['optOutProductEnquiryMarketing','optOutProductRequirementMarketing']){const body=service.match(new RegExp(`export\\s+async\\s+function\\s+${fn}\\b([\\s\\S]*?)(?=export\\s+async\\s+function|$)`))?.[1]||'';if(!body.includes("rpc('public_stop_customer_marketing'"))fail(`${fn} MUST USE GLOBAL VERIFIED STOP CONTRACT`)}
if(!/create\s+or\s+replace\s+function\s+(?:public\.)?public_stop_customer_marketing\s*\(/i.test(consentSql)||!/marketing_opt_out_at\s*=\s*coalesce\s*\(marketing_opt_out_at\s*,\s*now\(\)\)/i.test(consentSql)||!/customer_marketing_consent_events/i.test(consentSql))fail('GLOBAL CUSTOMER MARKETING STOP CONTRACT MISSING');
const requirementBody=service.match(/export\s+async\s+function\s+createProductRequirement\b([\s\S]*?)(?=export\s+(?:async\s+)?function|$)/)?.[1]||'';
for(const token of['createProductDemand','requirement_id:demand.demand_id','demand_tracking_status:\'CANONICAL\'','marketing:false'])if(!requirementBody.includes(token))fail(`CANONICAL PRODUCT REQUIREMENT CONTRACT MISSING: ${token}`);
if(requirementBody.includes("rpc('public_create_product_requirement'"))fail('RETIRED PRODUCT REQUIREMENT RPC CALLER PRESENT');
for(const token of["import PublicProductRequirementForm from'./PublicProductRequirementForm'","modal==='REQUIREMENT'",'<PublicProductRequirementForm/>'])if(!publicUi.includes(token))fail(`PUBLIC WEBSITE COMMON REQUIREMENT ENTRY MISSING: ${token}`);
for(const forbidden of['createProductRequirement','submitRequirement','changeRequirement','setRequirement','emptyRequirement'])if(publicUi.includes(forbidden))fail(`PUBLIC WEBSITE MUST NOT RESTORE DUPLICATE REQUIREMENT LOGIC: ${forbidden}`);
for(const token of["import PublicCatalogDropdowns from'./PublicCatalogDropdowns'","import PublicLocationDropdowns from'./PublicLocationDropdowns'",'<PublicCatalogDropdowns value={form} onChange={setForm} disabled={busy}/>','includeContact','Number.isInteger(qty)','qty<1||qty>9999','SEND PRODUCT REQUIREMENT','createProductRequirement(payload)'])if(!requirementForm.includes(token))fail(`COMMON PRODUCT REQUIREMENT UI VALIDATION MISSING: ${token}`);
if(/<label>BRAND<input|<label>MACHINE \/ MODEL<input/.test(requirementForm))fail('COMMON PRODUCT REQUIREMENT MUST USE MASTER-BACKED BRAND/MODEL DROPDOWNS');
if(!supportSql.includes('create or replace function public.public_create_product_requirement('))fail('AUTHORITATIVE PRODUCT REQUIREMENT SQL RPC MISSING');
for(const guard of['STATE REQUIRED','DISTRICT REQUIRED','CITY REQUIRED','VALID PRODUCT TYPE REQUIRED','REQUIRED PRODUCT / ITEM REQUIRED','VALID QUANTITY REQUIRED'])if(!supportSql.includes(guard))fail(`PRODUCT REQUIREMENT SERVER VALIDATION MISSING: ${guard}`);
for(const token of['public_set_product_requirement_marketing_opt_out','public_create_customer_complaint','torvo_admin_update_customer_complaint'])if(!supportSql.includes(token))fail(`SUPPORT/PRIVACY CONTRACT MISSING: ${token}`);
console.log('TORVO V2 dealer locator/profile + common website requirement + enquiry/referral + privacy/support service contract OK');
