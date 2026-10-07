import fs from 'node:fs';
const purchase=fs.readFileSync('supabase/v2-purchase-atomic-save-receive.sql','utf8');
const guard=fs.readFileSync('supabase/v2-inventory-purchase-guard.sql','utf8');
const returns=fs.readFileSync('supabase/v2-return-approval-checker-fix.sql','utf8');
const checks=[
 ['PURCHASE OWNER ADMIN ONLY',purchase.includes("a.role not in('owner','admin')")],
 ['PURCHASE REQUEST KEY REQUIRED',purchase.includes('Save request key required')],
 ['PURCHASE IDEMPOTENT SAME PAYLOAD',purchase.includes('old.payload_hash=ph then return old.purchase_id')],
 ['PURCHASE DUPLICATE INVOICE BLOCKED',purchase.includes('Duplicate supplier invoice')],
 ['PURCHASE STOCK RECEIVED MOVEMENT',purchase.includes("'PURCHASE STOCK RECEIVED'")],
 ['DIRECT REORDER RECEIPT RETIRED',guard.includes('Direct reorder stock receipt is retired')],
 ['MANUAL SUPPLIER RECEIPT BLOCKED',guard.includes('Supplier/Purchase receipt cannot use manual adjustment')],
 ['RETURN APPROVAL ROW LOCK',returns.includes('where id=p_approval for update')],
 ['RETURN SECOND DECISION BLOCKED',returns.includes("r.status<>'pending_approval'")],
 ['RETURN SELF APPROVAL CONTROL',returns.includes('Self approval is not permitted')],
 ['SALES RETURN QUANTITY CAP',returns.includes('Sales return quantity exceeds delivered quantity')],
 ['PURCHASE RETURN STOCK LOCK',returns.includes('from inventory where item_id=i for update')],
 ['PURCHASE RETURN STOCK CAP',returns.includes('Insufficient current stock for Purchase Return')],
 ['SALES RETURN STOCK IN',returns.includes("'SALES RETURN','sales_return'")],
 ['PURCHASE RETURN STOCK OUT',returns.includes("'PURCHASE RETURN','purchase_return'")]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}if(bad){console.error(`PURCHASE / INVENTORY / RETURN SAFETY FAILED: ${bad}`);process.exit(1)}console.log('TORVO V2 PURCHASE / INVENTORY / RETURN SOURCE SAFETY LOCKED');
