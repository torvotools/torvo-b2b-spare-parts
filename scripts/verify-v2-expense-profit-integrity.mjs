import fs from 'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const sql=read('supabase/v2-expense-profit-integrity.sql');
const repo=read('src/v2/services/repository.js');
const reports=read('src/v2/components/ReportsWorkspace.jsx');
const checks=[
 ['EXPENSE TABLE EXISTS',sql.includes('create table if not exists public.business_expenses')],
 ['EXPENSE TABLE RLS ENABLED',sql.includes('alter table public.business_expenses enable row level security')],
 ['DIRECT EXPENSE TABLE ACCESS REVOKED',sql.includes('revoke all on public.business_expenses from public,anon,authenticated')],
 ['EXPENSE REQUEST KEY IDEMPOTENCY',sql.includes('request_key text not null unique')&&sql.includes('Expense request key already used')],
 ['EXPENSE RECORD AUDITED',sql.includes("'EXPENSE_RECORDED'")],
 ['EXPENSE REVERSAL OWNER ADMIN ONLY',sql.includes("a.role not in('owner','admin')")&&sql.includes("'EXPENSE_REVERSED'")],
 ['EXPENSE REVERSAL REASON REQUIRED',sql.includes('Reversal reason required')],
 ['PROFIT RPC EXISTS',sql.includes('public.get_profit_summary')],
 ['PROFIT OWNER ONLY',sql.includes("a.role<>'owner'")&&sql.includes('Owner only profit report')],
 ['PROFIT USES ACTUAL DELIVERED SALES',sql.includes('delivery_stock_finalizations')&&sql.includes("e.doc_type='estimate'")],
 ['PROFIT USES HISTORICAL PURCHASE COST',sql.includes('purchase_lines')&&sql.includes('purchase_rate')&&sql.includes('ph.invoice_date<=d.delivered_at::date')],
 ['PROFIT HANDLES COMPLETED SALES RETURNS',sql.includes('transaction_returns')&&sql.includes("r.return_type='sales_return'")&&sql.includes("r.status='completed'")],
 ['PROFIT INCLUDES ACTIVE BUSINESS EXPENSES',sql.includes("from business_expenses where status='active'")],
 ['MISSING COST FAILS TRUTHFULLY',sql.includes("'complete',missing=0")&&sql.includes("'missing_cost_lines',missing")],
 ['PROFIT RPC CLIENT WIRED',repo.includes("rpc('get_profit_summary'")],
 ['REPORTS UI WIRED TO PROFIT SUMMARY',reports.includes('data.profitSummary')&&reports.includes('PROFIT & MARGIN')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`EXPENSE/PROFIT INTEGRITY FAILED: ${failed.length}`);process.exit(1)}console.log(`TORVO V2 EXPENSE/PROFIT INTEGRITY VERIFIED (${checks.length} GATES)`);
