import fs from'node:fs';
const sql=fs.readFileSync('supabase/v2-customer-demand-lead-lifecycle.sql','utf8');
const order=fs.readFileSync('supabase/V2_INSTALL_ORDER.md','utf8');
const checks=[
 ['ADMIN LEAD CENTER',/admin_customer_lead_center/.test(sql)],
 ['OWNER ADMIN ONLY',/u\.role not in\('owner','admin'\)/.test(sql)],
 ['PRIVATE CUSTOMER CONTACT',/customer_name text,mobile text/.test(sql)&&/revoke all on function admin_customer_lead_center\(text,integer\) from public,anon/.test(sql)],
 ['LEAD STATUS FILTER',/INVALID LEAD STATUS/.test(sql)&&/'submitted','sourcing','available','closed','cancelled','sent','accepted','declined','expired'/.test(sql)],
 ['DEALER ROUTING VISIBILITY',/dealer_name text,routing_stage text,lead_status text/.test(sql)],
 ['AUDITED CLOSE',/CUSTOMER_DEMAND_CLOSED/.test(sql)&&/jsonb_build_object\('reason',r\)/.test(sql)],
 ['CLOSE OPEN ASSIGNMENTS',/status='closed',closed_at=now\(\).*status in\('sent','accepted'\)/s.test(sql)],
 ['NO PUBLIC GRANT',!/grant execute on function admin_customer_lead_center\(text,integer\) to anon/.test(sql)],
 ['INSTALL AFTER ROUTING',order.indexOf('v2-customer-demand-lead-lifecycle.sql')>order.indexOf('v2-customer-demand-dealer-routing.sql')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[name,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${name}`);if(failed.length){console.error(`CUSTOMER LEAD LIFECYCLE FAILED: ${failed.length} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER LEAD LIFECYCLE (${checks.length} GATES)`);
