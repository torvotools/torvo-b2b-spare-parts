import fs from 'node:fs';
const ui=fs.readFileSync('src/v2/components/CustomerApp.jsx','utf8');
const svc=fs.readFileSync('src/v2/services/customerProductDemand.js','utf8');
const checks=[
 ['DEMAND SERVICE IMPORT',/createCustomerProductDemand,requestTorvoProductHelp/.test(ui)],
 ['REQUEST THIS ITEM UI',/REQUEST THIS ITEM/.test(ui)&&/SUBMIT REQUIREMENT/.test(ui)],
 ['RAW SEARCH NOT A LEAD',/RAW SEARCH TYPING DOES NOT CREATE A CUSTOMER LEAD/.test(ui)],
 ['CONFIRMED DEMAND SERVICE',/createCustomerProductDemand\(/.test(ui)&&/public_create_product_demand/.test(svc)],
 ['TORVO PAN INDIA ESCALATION',/ASK TORVO PAN-INDIA HELP/.test(ui)&&/requestTorvoProductHelp\(/.test(ui)&&/public_request_torvo_product_help/.test(svc)],
 ['PRIVATE RESULT SERVICE',/loadCustomerProductDemandResult/.test(svc)&&/public_customer_demand_result/.test(svc)],
 ['RESULT MOBILE NORMALIZED',/loadCustomerProductDemandResult[\s\S]*cleanMobile\(mobile\)/.test(svc)&&/10-DIGIT MOBILE REQUIRED/.test(svc)],
 ['RESULT AVAILABLE PRIVACY',/found_dealer_id:status==='available'/.test(svc)&&/found_contact_note:status==='available'/.test(svc)&&/available_at:status==='available'/.test(svc)],
 ['PRIVATE CONTACT MESSAGE',/CUSTOMER CONTACT IS NOT PUBLICLY BROADCAST TO DEALERS/.test(ui)],
 ['NO AVAILABILITY PROMISE',/AVAILABILITY IS NOT GUARANTEED/.test(ui)&&!/WE FOUND YOUR ITEM|ITEM IS AVAILABLE NOW/.test(ui)],
 ['PIN INPUT BOUNDED',/maxLength="6"/.test(ui)&&/replace\(\/\\D\/g,''\)\.slice\(0,6\)/.test(ui)],
 ['MOBILE INPUT BOUNDED',/MOBILE \/ WHATSAPP/.test(ui)&&/slice\(0,10\)/.test(ui)],
 ['REPAIR FLOW PRESERVED',/SEND REPAIR REQUIREMENT/.test(ui)&&/public_create_repair_request/.test(ui)],
 ['REFERRAL FLOW PRESERVED',/GET TORVO REFERRAL CODE/.test(ui)&&/public_create_customer_referral/.test(ui)],
 ['PUBLIC NO PRICE CHECKOUT',!/CHECKOUT|ADD TO CART|BUY NOW|PAY NOW/.test(ui)],
];
let failed=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed++}if(failed){console.error(`CUSTOMER DEMAND UI CONTRACT FAILED: ${failed} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER DEMAND UI CONTRACT (${checks.length} GATES)`);
