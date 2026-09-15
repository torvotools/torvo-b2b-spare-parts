import fs from'node:fs';
const ui=fs.readFileSync('src/v2/components/AdminCustomerLeads.jsx','utf8');
const svc=fs.readFileSync('src/v2/services/adminCustomerLeads.js','utf8');
const found=fs.readFileSync('supabase/v2-customer-demand-found-lifecycle.sql','utf8');
const checks=[
['ADMIN LEADS RPC',/admin_customer_lead_center/.test(svc)],
['ADMIN ROUTING RPC',/admin_route_customer_demand_to_dealer/.test(svc)],
['AUDITED CLOSE RPC',/admin_close_customer_demand_lead/.test(svc)],
['LEADS CENTER UI',/CUSTOMER LEADS CENTER/.test(ui)],
['STATUS FILTERS',/submitted.*sourcing.*available.*sent.*accepted.*declined.*closed/.test(ui)],
['CUSTOMER CONTACT ACTIONS',/tel:/.test(ui)&&/wa\.me/.test(ui)],
['DEALER RESPONSE VISIBLE',/r\.dealer_name/.test(ui)&&/r\.lead_status/.test(ui)],
['FOUND DEALER VISIBLE',/FOUND DEALER:/.test(ui)&&/r\.found_dealer_name/.test(ui)],
['CUSTOMER RESULT NOTE VISIBLE',/CUSTOMER RESULT NOTE:/.test(ui)&&/r\.found_contact_note/.test(ui)],
['AVAILABLE TIMESTAMP VISIBLE',/AVAILABLE AT:/.test(ui)&&/r\.available_at/.test(ui)],
['CONVERSION TIMESTAMP VISIBLE',/CONVERTED AT:/.test(ui)&&/r\.converted_at/.test(ui)],
['MANUAL CLOSE TIMESTAMP VISIBLE',/CLOSED AT:/.test(ui)&&/r\.closed_at/.test(ui)],
['FOUND LIFECYCLE RPC RETURNS DETAIL',/found_dealer_name text,found_contact_note text,available_at timestamptz,converted_at timestamptz,closed_at timestamptz/.test(found)],
['CLOSE REASON REQUIRED',/CLOSE REASON/.test(ui)&&/closeAdminCustomerLead/.test(ui)],
['NO PUBLIC SEARCH RPC',!/public_create_product_demand|public_request_torvo_product_help/.test(svc)]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`ADMIN CUSTOMER LEADS UI FAILED: ${failed.length} GATE(S)`);process.exit(1)}console.log(`PASS ADMIN CUSTOMER LEADS UI (${checks.length} GATES)`);
