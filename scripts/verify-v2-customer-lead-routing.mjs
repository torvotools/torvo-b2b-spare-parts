import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const sql=read('supabase/v2-customer-demand-dealer-routing.sql');
const service=read('src/v2/services/dealerCustomerLeads.js');
const ui=read('src/v2/components/DealerCustomerLeads.jsx');
const mount=read('src/v2/components/DealerPortalMounted.jsx');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['PRIVATE LEAD TABLE',/enable row level security/i.test(sql)&&/revoke all on customer_demand_dealer_leads from anon,authenticated/i.test(sql)],
 ['APPROVED DEALER ROUTING',/d\.status='approved'/i.test(sql)&&/APPROVED DEALER REQUIRED/i.test(sql)],
 ['ADMIN ROUTING ONLY',/u\.role not in\('owner','admin'\)/i.test(sql)],
 ['DEVICE VERIFIED INBOX',/dealer_assert_my_device_session\(p_device_id,p_session_token\)/i.test(sql)],
 ['INBOX HIDES CONTACT',/returns table\(lead_id uuid,demand_id uuid,search_text text,pin_code text,brand text,model_number text,requirement_note text,routing_stage text,status text,sent_at timestamptz\)/i.test(sql)],
 ['ACCEPT UNLOCKS CONTACT',/dealer_accept_customer_demand_lead/i.test(sql)&&/customer_name text,mobile text,whatsapp text/i.test(sql)],
 ['ASSIGNED DEALER ONLY',/where id=p_lead_id and dealer_id=did for update/i.test(sql)],
 ['ACCEPT IDEMPOTENT AFTER REFRESH',/l\.status not in\('sent','accepted'\)/i.test(sql)&&/accepted_at=coalesce\(accepted_at,now\(\)\)/i.test(sql)&&/already_accepted/.test(sql)],
 ['ACCEPT AUDITED',/CUSTOMER_DEMAND_LEAD_ACCEPTED/.test(sql)&&/CUSTOMER_DEMAND_DEALER_LEAD/.test(sql)],
 ['DECLINE DEVICE VERIFIED',/dealer_decline_customer_demand_lead/i.test(sql)&&/dealer_id=did and status='sent' for update/i.test(sql)],
 ['DECLINE AUDITED',/CUSTOMER_DEMAND_LEAD_DECLINED/.test(sql)&&/declined_at=now\(\)/.test(sql)],
 ['NO FAKE DISTANCE CONTRACT',/actual 0-25\/25-50 KM routing must be supplied by a truthful geospatial\/service-area selector later/i.test(sql)],
 ['CLIENT DEVICE PROOF',/assertDealerSession/.test(service)&&/p_device_id:p\.deviceId,p_session_token:p\.token/.test(service)],
 ['CLIENT ACCEPT CONTACT GATE',/acceptDealerCustomerLead/.test(service)&&/CUSTOMER CONTACT UNLOCK FAILED/.test(service)],
 ['DEALER PRIVACY MESSAGE',/CONTACT STAYS PRIVATE UNTIL YOU ACCEPT YOUR ASSIGNED LEAD/.test(ui)],
 ['DEALER EXPLICIT ACCEPT',/I CAN SUPPLY — ACCEPT/.test(ui)],
 ['CONTACT ONLY AFTER ACCEPT',/CUSTOMER CONTACT UNLOCKED/.test(ui)&&/CALL CUSTOMER/.test(ui)&&/WHATSAPP CUSTOMER/.test(ui)],
 ['DEALER PORTAL MOUNT',/DealerCustomerLeads/.test(mount)&&/CUSTOMER LEADS/.test(mount)&&/mode==='leads'/.test(mount)],
 ['INSTALL ORDER ROUTING',order.indexOf('v2-customer-demand-dealer-routing.sql')>order.indexOf('v2-customer-product-demand-leads.sql')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[name,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${name}`);if(failed.length){console.error(`CUSTOMER LEAD ROUTING FAILED: ${failed.length} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER LEAD ROUTING (${checks.length} GATES)`);
