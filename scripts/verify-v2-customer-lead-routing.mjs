import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const sql=read('supabase/v2-customer-demand-dealer-routing.sql');
const qtySql=read('supabase/v2-customer-demand-quantity-integrity.sql');
const service=read('src/v2/services/dealerCustomerLeads.js');
const ui=read('src/v2/components/DealerCustomerLeads.jsx');
const mount=read('src/v2/components/DealerPortalMounted.jsx');
const order=read('supabase/V2_INSTALL_ORDER.md');
const checks=[
 ['PRIVATE LEAD TABLE',/enable row level security/i.test(sql)&&/revoke all on customer_demand_dealer_leads from anon,authenticated/i.test(sql)],
 ['APPROVED DEALER ROUTING',/target_dealer\.status<>'approved'/i.test(sql)&&/APPROVED DEALER REQUIRED/i.test(sql)],
 ['ADMIN ROUTING ONLY',/u\.role not in\('owner','admin'\)/i.test(sql)],
 ['ADMIN ROUTE LOCKS DEMAND',/admin_route_customer_demand_to_dealer[\s\S]*select \* into d from customer_product_demands where id=p_demand_id for update[\s\S]*ACTIVE CUSTOMER REQUIREMENT REQUIRED/i.test(sql)],
 ['ADMIN ROUTE ACTIVE BEFORE INSERT',sql.indexOf("select * into d from customer_product_demands where id=p_demand_id for update")<sql.indexOf('insert into customer_demand_dealer_leads')&&sql.indexOf("d.status in('closed','cancelled')")<sql.indexOf('insert into customer_demand_dealer_leads')],
 ['ADMIN ROUTE LOCKS DEALER',/select \* into target_dealer from dealers where id=p_dealer_id for update/i.test(sql)],
 ['APPROVED DEALER CHECK BEFORE INSERT',sql.indexOf("target_dealer.status<>'approved'")<sql.indexOf('insert into customer_demand_dealer_leads')],
 ['DEVICE VERIFIED INBOX',/dealer_assert_my_device_session\(p_device_id,p_session_token\)/i.test(sql)],
 ['INBOX HIDES CONTACT',/returns table\(lead_id uuid,demand_id uuid,search_text text,pin_code text,brand text,model_number text,requirement_note text,routing_stage text,status text,sent_at timestamptz\)/i.test(sql)],
 ['INBOX HIDES CLOSED DEMANDS',/l\.status in\('sent','accepted'\) and d\.status not in\('closed','cancelled'\)/i.test(sql)],
 ['ACCEPT UNLOCKS CONTACT',/dealer_accept_customer_demand_lead/i.test(sql)&&/customer_name text,mobile text,whatsapp text/i.test(sql)],
 ['ASSIGNED DEALER ONLY',/where id=p_lead_id and dealer_id=did for update/i.test(sql)],
 ['ACCEPT IDEMPOTENT AFTER REFRESH',/l\.status not in\('sent','accepted'\)/i.test(sql)&&/accepted_at=coalesce\(accepted_at,now\(\)\)/i.test(sql)&&/already_accepted/.test(sql)],
 ['ACTIVE DEMAND LOCK BEFORE ACCEPT',/select \* into d from customer_product_demands where id=l\.demand_id for update/i.test(sql)&&/d\.status in\('closed','cancelled'\)/i.test(sql)&&/ACTIVE CUSTOMER REQUIREMENT REQUIRED/i.test(sql)],
 ['CONTACT FROM LOCKED DEMAND',/from customer_contacts c where c\.id=d\.customer_id/i.test(sql)],
 ['DEALER USER BOUND BEFORE ACCEPT',/auth_user_id=auth\.uid\(\) and active=true and lower\(coalesce\(role,''\)\)='dealer' and dealer_id=did/i.test(sql)],
 ['DEALER USER IDENTITY UNIQUE BEFORE CONTACT',/select count\(\*\) into identity_count from app_users/i.test(sql)&&/identity_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS'/i.test(sql)&&/select id into strict au from app_users/i.test(sql)],
 ['ACTIVE APP USER BEFORE AUDIT',/identity_count=0 then raise exception 'ACTIVE DEALER APP USER REQUIRED'/i.test(sql)],
 ['ACCEPT AUDITED',/CUSTOMER_DEMAND_LEAD_ACCEPTED/.test(sql)&&/CUSTOMER_DEMAND_DEALER_LEAD/.test(sql)],
 ['DECLINE DEVICE VERIFIED',/dealer_decline_customer_demand_lead/i.test(sql)&&/dealer_id=did and status='sent' for update/i.test(sql)],
 ['DECLINE ACTIVE DEMAND LOCK',/dealer_decline_customer_demand_lead[\s\S]*select \* into d from customer_product_demands where id=l\.demand_id for update[\s\S]*ACTIVE CUSTOMER REQUIREMENT REQUIRED/i.test(sql)],
 ['DECLINE UNIQUE DEALER IDENTITY',/dealer_decline_customer_demand_lead[\s\S]*identity_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS'[\s\S]*select id into strict au from app_users/i.test(sql)],
 ['DECLINE AUDITED',/CUSTOMER_DEMAND_LEAD_DECLINED/.test(sql)&&/declined_at=now\(\)/.test(sql)],
 ['NO FAKE DISTANCE CONTRACT',/actual 0-25\/25-50 KM routing must be supplied by a truthful geospatial\/service-area selector later/i.test(sql)],
 ['QUANTITY CONTRACT',/quantity integer not null default 1/i.test(qtySql)&&/check\(quantity between 1 and 9999\)/i.test(qtySql)&&/p_quantity integer/i.test(qtySql)],
 ['DEALER INBOX RETURNS QUANTITY',/dealer_customer_demand_leads[\s\S]*quantity integer/i.test(qtySql)&&/d\.quantity/i.test(qtySql)],
 ['DEALER UI SHOWS QUANTITY',/QTY:/.test(ui)&&/REQUIREMENT QTY:/.test(ui)],
 ['CLIENT DEVICE PROOF',/assertDealerSession/.test(service)&&/p_device_id:p\.deviceId,p_session_token:p\.token/.test(service)],
 ['CLIENT ACCEPT CONTACT GATE',/acceptDealerCustomerLead/.test(service)&&/CUSTOMER CONTACT UNLOCK FAILED/.test(service)],
 ['DEALER PRIVACY MESSAGE',/CONTACT STAYS PRIVATE UNTIL YOU ACCEPT YOUR ASSIGNED LEAD/.test(ui)],
 ['DEALER EXPLICIT ACCEPT',/I CAN SUPPLY — ACCEPT/.test(ui)],
 ['CONTACT ONLY AFTER ACCEPT',/CUSTOMER CONTACT UNLOCKED/.test(ui)&&/CALL CUSTOMER/.test(ui)&&/WHATSAPP CUSTOMER/.test(ui)],
 ['DEALER LEAD REFRESH STATE',/REFRESHING…/.test(ui)&&/\[\s*loading\s*,\s*setLoading\s*\]\s*=\s*useState\(true\)/.test(ui)],
 ['DEALER LEAD ACTIONS LOCK DURING REFRESH',/disabled=\{loading\|\|!!busy\}/.test(ui)&&/if\(!id\|\|loading\|\|busy\)return/.test(ui)],
 ['DEALER LEAD LOAD ERROR CLEARS STALE ROWS',/catch\(e\)\{if\(mounted\.current\)\{setRows\(\[\]\);setErr/.test(ui)],
 ['DEALER PORTAL MOUNT',/DealerCustomerLeads/.test(mount)&&/CUSTOMER LEADS/.test(mount)&&/mode==='leads'/.test(mount)],
 ['INSTALL ORDER ROUTING',order.indexOf('v2-customer-demand-dealer-routing.sql')>order.indexOf('v2-customer-product-demand-leads.sql')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[name,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${name}`);if(failed.length){console.error(`CUSTOMER LEAD ROUTING FAILED: ${failed.length} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER LEAD ROUTING (${checks.length} GATES)`);
