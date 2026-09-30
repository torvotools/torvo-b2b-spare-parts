import fs from 'node:fs';
const summary=fs.readFileSync('supabase/v2-report-summary-rpc.sql','utf8');
const detail=fs.readFileSync('supabase/v2-report-detail-rpc.sql','utf8');
const reports=fs.readFileSync('src/v2/config/reports.js','utf8');
const legacy=fs.readFileSync('supabase/v2-reporting-rpc.sql','utf8');
const installOrder=fs.readFileSync('supabase/V2_INSTALL_ORDER.md','utf8');
const checks=[
 ['SALES TOTAL USES POSTED MARG BILL SALES',summary.includes("join marg_bill_sales s on s.estimate_id=e.id where e.doc_type='estimate' and s.status='posted'")],
 ['QUOTATION COUNT USES CANONICAL INTERNAL SALES_ORDER',summary.includes("'quotation_count',(select count(*) from sales_documents where doc_type='sales_order')")],
 ['ACCEPTED QUOTATION USES DEALER OK SALES_ORDER',summary.includes("'accepted_quotation_count',(select count(*) from sales_documents where doc_type='sales_order' and status in('dealer_ok','confirmed','final','approved'))")],
 ['STALE QUOTATION DOC TYPE REMOVED FROM SUMMARY',!summary.includes("doc_type='quotation'")],
 ['SALES DETAIL USES POSTED MARG BILL SALES',detail.includes("join marg_bill_sales s on s.estimate_id=e.id")&&detail.includes("s.status='posted'")],
 ['ORDER VS ESTIMATE USES SALES_ORDER',detail.includes("so.doc_type='sales_order'")],
 ['REPORT CATALOG LABELS QUOTATION CONVERSION',reports.includes("name:'Quotation Conversion'")],
 ['LEGACY REPORT SUMMARY OVERLAP REMAINS EXPLICIT',legacy.includes('create or replace function get_report_summary()')],
 ['INSTALL ORDER BLOCKS LEGACY SUMMARY AFTER AUTHORITATIVE SUMMARY',installOrder.includes('v2-reporting-rpc.sql')&&installOrder.includes('MUST NOT be installed after the authoritative summary RPC')]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}
if(bad){console.error(`REPORT CANONICAL SALES FLOW FAILED: ${bad}`);process.exit(1)}
console.log('TORVO V2 REPORTS USE CANONICAL SALES_ORDER -> DEALER OK -> ESTIMATE -> POSTED MARG BILL SALE FLOW');
