import fs from 'node:fs';
const sql=fs.readFileSync('supabase/v2-marg-bill-sale-posting.sql','utf8');
const checks=[
 ['SALE STOCK DEDUCTION AT MARG POST',sql.includes("values(ln.item_id,-ln.qty,'MARG BILL SALE POSTED'")],
 ['DELIVERY REQUIRES POSTED MARG SALE',sql.includes("POSTED MARG BILL SALE REQUIRED BEFORE DELIVERY")],
 ['DELIVERY READY STAGE REQUIRED',sql.includes("disp.status not in('ready_for_dispatch')")],
 ['DELIVERY DOES NOT DEDUCT STOCK AGAIN',sql.includes("'stock_deducted_again',false")],
 ['DELIVERY IDEMPOTENT WHEN ALREADY DELIVERED',sql.includes("if disp.status='delivered' then return")],
 ['REVERSAL OWNER ADMIN ONLY',sql.includes("a.role not in('owner','admin')")],
 ['DELIVERED SALE REVERSAL BLOCKED',sql.includes("DELIVERED SALE CANNOT BE REVERSED HERE")],
 ['SECOND REVERSAL BLOCKED',sql.includes("s.status='reversed'")&&sql.includes("ACTIVE POSTED SALE REQUIRED")],
 ['REVERSAL RESTORES STOCK',sql.includes("current_qty=public.inventory.current_qty+excluded.current_qty")],
 ['REVERSAL CANCELS OPEN DISPATCH',sql.includes("delete from public.dispatches where estimate_id=e.id and status<>'delivered'")]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}if(bad){console.error(`MARG SALE / DELIVERY SAFETY FAILED: ${bad}`);process.exit(1)}console.log('TORVO V2 MARG SALE / DELIVERY SOURCE SAFETY LOCKED');
