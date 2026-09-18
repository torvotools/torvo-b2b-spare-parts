import fs from 'node:fs';
const ui=fs.readFileSync('src/v2/components/CustomerApp.jsx','utf8');
const svc=fs.readFileSync('src/v2/services/customerProductDemand.js','utf8');
const pub=fs.readFileSync('src/v2/services/publicWebsite.js','utf8');
const journey=fs.readFileSync('src/v2/services/customerDealerJourney.js','utf8');
const checks=[
 ['DEMAND SERVICE IMPORT',/createCustomerProductDemand,requestTorvoProductHelp,loadCustomerProductDemandResult/.test(ui)],
 ['REQUEST THIS ITEM UI',/REQUEST THIS ITEM/.test(ui)&&/SUBMIT REQUIREMENT/.test(ui)],
 ['RAW SEARCH NOT A LEAD',/RAW SEARCH TYPING DOES NOT CREATE A CUSTOMER LEAD/.test(ui)],
 ['CONFIRMED DEMAND SERVICE',/createCustomerProductDemand\(/.test(ui)&&/public_create_product_demand/.test(svc)],
 ['CUSTOMER NAME REQUIRED',/fullName\.length<2/.test(svc)&&/CUSTOMER NAME REQUIRED/.test(svc)],
 ['DEMAND PAYLOAD BOUNDED',/cleanText\(name,120,'CUSTOMER NAME'\)/.test(svc)&&/cleanText\(searchText,200,'PRODUCT SEARCH'\)/.test(svc)&&/cleanText\(brand,120,'BRAND'\)/.test(svc)&&/cleanText\(modelNumber,120,'MODEL NUMBER'\)/.test(svc)&&/cleanText\(requirementNote,500,'REQUIREMENT NOTE'\)/.test(svc)],
 ['TORVO PAN INDIA ESCALATION',/ASK TORVO PAN-INDIA HELP/.test(ui)&&/requestTorvoProductHelp\(/.test(ui)],
 ['PRIVATE CONTACT MESSAGE',/CUSTOMER CONTACT IS NOT PUBLICLY BROADCAST TO DEALERS/.test(ui)],
 ['NO UNVERIFIED AVAILABILITY PROMISE',/AVAILABILITY IS NOT GUARANTEED/.test(ui)&&!/WE FOUND YOUR ITEM|ITEM IS AVAILABLE NOW/.test(ui)],
 ['COMMON CATALOG IMPORT',/import PublicCatalogDropdowns from'\.\/PublicCatalogDropdowns'/.test(ui)],
 ['DEMAND MASTER DROPDOWNS',/open==='demand'[\s\S]*<PublicCatalogDropdowns value=\{demand\} onChange=\{setDemand\} disabled=\{busy\}/.test(ui)],
 ['REPAIR MASTER DROPDOWNS',/open==='repair'[\s\S]*<PublicCatalogDropdowns value=\{repair\} onChange=\{setRepair\} disabled=\{busy\}/.test(ui)],
 ['NO FREE TEXT BRAND MODEL',!/<label>BRAND<input|<label>MODEL NUMBER<input/.test(ui)],
 ['BUSY DOUBLE SUBMIT GUARD',/const submitDemand=async e=>\{e\.preventDefault\(\);if\(busy\)return/.test(ui)&&/const submitRepair=async e=>\{e\.preventDefault\(\);if\(busy\)return/.test(ui)],
 ['SAFE MODAL CLOSE',/const close=\(\)=>\{if\(busy\)return;setErr\(''\);setOpen\(''\)\}/.test(ui)],
 ['INPUT LENGTH LIMITS',/NAME<input maxLength="120"/.test(ui)&&/MOBILE \/ WHATSAPP<input inputMode="numeric" maxLength="10"/.test(ui)&&/ITEM \/ SEARCH<input maxLength="200"/.test(ui)],
 ['ACCESSIBLE STATUS',/role="alert"/.test(ui)&&/role="status"/.test(ui)],
 ['RESULT RESET ON NEW FLOW',/setDemandResult\(null\)/.test(ui)&&/setRepairResult\(null\)/.test(ui)&&/setRef\(null\)/.test(ui)],
 ['VERIFIED DEALER PROFILE SERVICE',/openCustomerDealerProfile/.test(ui)&&/loadDealerProfile/.test(journey)&&/VERIFIED DEALER PROFILE NOT AVAILABLE/.test(journey)],
 ['DEALER PROFILE BEFORE DETAILS',/const profile=await openCustomerDealerProfile\(d,selected\)/.test(ui)&&/setDealerProfile\(profile\);setOpen\('details'\)/.test(ui)],
 ['CALL DEALER ACTION',/CALL DEALER/.test(ui)&&/href=\{`tel:\$\{phone\}`\}/.test(ui)&&/onClick=\{dealerCall\}/.test(ui)],
 ['WHATSAPP DEALER ACTION',/WHATSAPP DEALER/.test(ui)&&/https:\/\/wa\.me\/91\$\{wa\}/.test(ui)&&/TORVO PRODUCT ENQUIRY/.test(ui)],
 ['MAP DIRECTION ACTION',/MAP \/ DIRECTION/.test(ui)&&/href=\{map\}/.test(ui)],
 ['VERIFIED DEALER LABEL',/VERIFIED TORVO DEALER/.test(ui)],
 ['DEALER LOCATION DISPLAY',/dp\.address,dp\.city,dp\.district,dp\.state,dp\.pin_code/.test(ui)],
 ['REFERRAL LINKS SELECTED DEALER',/dealerId:dealerProfile\.dealer_id/.test(ui)&&/GET TORVO REFERRAL CODE/.test(ui)],
 ['REFERRAL SERVICE VALIDATION',/CUSTOMER NAME REQUIRED/.test(pub)&&/10-DIGIT MOBILE \/ WHATSAPP REQUIRED/.test(pub)&&/6-DIGIT PIN CODE REQUIRED/.test(pub)&&/uuid\(productId,'PRODUCT ID'\)/.test(pub)&&/REFERRAL CREATION FAILED/.test(pub)],
 ['REPAIR SERVICE VALIDATION',/PROBLEM DESCRIPTION REQUIRED/.test(pub)&&/REPAIR REQUEST CREATION FAILED/.test(pub)],
 ['PUBLIC NO PRICE CHECKOUT',!/CHECKOUT|ADD TO CART|BUY NOW|PAY NOW/.test(ui)],
];
let failed=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++}if(failed){console.error(`CUSTOMER DEMAND UI CONTRACT FAILED: ${failed} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER DEALER JOURNEY CONTRACT (${checks.length} GATES)`);
