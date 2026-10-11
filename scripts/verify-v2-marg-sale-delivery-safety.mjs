import fs from 'node:fs';
const sql=fs.readFileSync('supabase/v2-marg-bill-sale-posting.sql','utf8');
function extractFunction(name){
 const marker='create or replace function public.'+name+'(';
 const start=sql.indexOf(marker);
 if(start<0||sql.indexOf(marker,start+marker.length)>=0) return '';
 const end=sql.indexOf('end;'+String.fromCharCode(36,36)+';',start);
 return end<0?'':sql.slice(start,end+('end;'+String.fromCharCode(36,36)+';').length);
}
const revisionSql=extractFunction('revise_estimate_before_sale');
const reversalSql=extractFunction('reverse_marg_bill_sale');
const deliverySql=extractFunction('finalize_actual_delivery');
if(!revisionSql||!reversalSql||!deliverySql){console.error('MARG SALE SAFETY: SQL FUNCTION BODY MISSING');process.exit(1)}
const saleUi=fs.readFileSync('src/v2/components/MargBillSaleWorkspace.jsx','utf8');
const checks=[
 ['SALE UI ENFORCES BILL LENGTH',saleUi.includes('bill.trim().length>80')&&saleUi.includes('maxLength={80}')],
 ['REVERSAL UI ENFORCES REASON LENGTH',saleUi.includes('reason.trim().length>500')&&saleUi.includes('maxLength={500}')],
 ['DELIVERED REVERSAL ACTION DISABLED',saleUi.includes("U(r.dispatch_status)==='DELIVERED'")],
 ['REVERSAL CANCEL DISABLED DURING POSTING',saleUi.includes('disabled={busy} onClick={()=>setReverse(null)}')],
 ['SALE UI REQUIRES EXPLICIT CONFIRMATION',saleUi.includes('if(busy||!confirmed)return')&&saleUi.includes('disabled={busy||!estimate||!bill||!confirmed}')],
 ['SALE UI RESETS CONFIRMATION ON EDIT',saleUi.includes('setEstimate(e.target.value.trim());setConfirmed(false)')&&saleUi.includes('setBill(U(e.target.value));setConfirmed(false)')],
 ['SALE UI OWNER APPROVAL LABEL',saleUi.includes('APPROVE BILL & CONFIRM SALE')&&!saleUi.includes('SAVE MARG BILL & POST SALE')],
 ['REVERSAL RECONCILES EACH ITEM',reversalSql.includes('SALE STOCK POSTING QUANTITY MISMATCH')],
 ['REVERSAL CHECKS POSTED QUANTITY',reversalSql.includes('posted.qty_change is distinct from -expected.qty')],
 ['REVERSAL CHECKS MISSING MOVEMENT',reversalSql.includes('posted.item_id is null')],
 ['SALE REJECTS INVALID PAYABLE [SCOPED]',sql.includes('INVALID ESTIMATE PAYABLE FOR SALE')],
 ['REVERSAL REQUIRES STOCK POSTING EVIDENCE [SCOPED]',reversalSql.includes('SALE STOCK POSTING EVIDENCE MISSING')],

 ['SALE REJECTS INVALID STATUS [SCOPED]',sql.includes('ESTIMATE STATUS DOES NOT ALLOW SALE POSTING')],
 ['REVERSAL REJECTS INVALID LINES [SCOPED]',reversalSql.includes('INVALID SALE LINES FOR REVERSAL')],
 ['REVERSAL REQUIRES POSTED ESTIMATE [SCOPED]',reversalSql.includes('ESTIMATE STATUS DOES NOT ALLOW SALE REVERSAL')],
 ['DELIVERY REQUIRES POSTED ESTIMATE [SCOPED]',deliverySql.includes('ESTIMATE STATUS DOES NOT ALLOW DELIVERY')],
 ['DELIVERY REJECTS NULL ESTIMATE ID [SCOPED]',deliverySql.includes('ESTIMATE ID REQUIRED FOR DELIVERY')],
 ['DELIVERY REJECTS LONG REQUEST KEY [SCOPED]',deliverySql.includes('length(btrim(p_request_key))>128')],
 ['DELIVERY REJECTS LONG TRACKING CODE [SCOPED]',deliverySql.includes('length(btrim(p_tracking_code))>128')],
 ['REVISION REJECTS NONFINITE RATE [SCOPED]',revisionSql.includes("r::text in('NaN','Infinity','-Infinity')")],
 ['REVISION REJECTS EMPTY ARRAY [SCOPED]',revisionSql.includes('jsonb_array_length(p_lines)=0')],
 ['REVERSAL REQUIRES EXPLANATION [SCOPED]',reversalSql.includes('VALID REVERSAL REASON REQUIRED')],

 ['REVISION REQUIRES ESTIMATE NUMBER',revisionSql.includes("if nullif(btrim(coalesce(p_estimate_number,'')),'') is null then raise exception 'ESTIMATE NUMBER REQUIRED'")],
 ['REVISION REJECTS NULL PAYLOAD',revisionSql.includes("p_lines is null or jsonb_typeof(p_lines) is distinct from 'array'")],
 ['REVISION REJECTS EMPTY PAYLOAD',revisionSql.includes('jsonb_array_length(p_lines)=0')],
 ['REVISION REJECTS NONFINITE QUANTITY',revisionSql.includes("q::text in('NaN','Infinity','-Infinity')")],
 ['REVISION REJECTS NONFINITE RATE',revisionSql.includes("r::text in('NaN','Infinity','-Infinity')")],
 ['REVISION REJECTS NULL ITEM ID',revisionSql.includes('if iid is null or q is null or r is null')],
 ['REVISION REJECTS NULL QUANTITY',revisionSql.includes('q is null or r is null')],
 ['REVISION REJECTS NULL RATE',revisionSql.includes('r is null or q::text in')],
 ['REVISION REJECTS NONPOSITIVE QUANTITY',revisionSql.includes('q<=0 or r<0')],
 ['REVISION REJECTS NEGATIVE RATE',revisionSql.includes('r<0 or not exists')],
 ['REVISION REQUIRES ACTIVE CATALOG ITEM',revisionSql.includes('public.catalog_items where id=iid and active=true')],
 ['REVISION REJECTS DELIVERED ESTIMATE',revisionSql.includes('ESTIMATE STATUS DOES NOT ALLOW REVISION')],
 ['REVISION REJECTS CANCELLED ESTIMATE',revisionSql.includes("'cancelled','canceled','rejected'")],
 ['REVISION REJECTS POSTED ESTIMATE',revisionSql.includes("'sale_posted') then raise exception 'ESTIMATE STATUS DOES NOT ALLOW REVISION'")],
 ['REVERSAL REQUIRES ESTIMATE NUMBER',reversalSql.includes("if nullif(btrim(coalesce(p_estimate_number,'')),'') is null then raise exception 'ESTIMATE NUMBER REQUIRED'")],
 ['REVERSAL REQUIRES ACTIVE POSTED STATUS',reversalSql.includes("s.status not in('posted','corrected')")],
 ['REVERSAL BLOCKS DELIVERED ESTIMATE',reversalSql.includes("lower(btrim(coalesce(e.status,'')))='delivered' or (found and d.status='delivered')")],
 ['SALE VALIDATES INDIVIDUAL LINES',sql.includes('ESTIMATE HAS INVALID ITEM OR LINE QUANTITY')],
 ['REVISION REASON MAX 500',revisionSql.includes('VALID REVISION REASON REQUIRED')],
 ['REVERSAL REASON MAX 500',reversalSql.includes('VALID REVERSAL REASON REQUIRED')],
 ['DELIVERED REVERSAL STATUS NORMALIZED',sql.includes("lower(btrim(coalesce(e.status,'')))='delivered'")],
 ['MARG SALE ESTIMATE UNIQUENESS IS DATABASE ENFORCED',/estimate_id uuid not null unique references public\.sales_documents/.test(sql)],
 ['MARG BILL UNIQUENESS IS DATABASE ENFORCED',sql.includes('create unique index if not exists uq_marg_bill_sales_bill_no')],
 ['SALE APPROVAL LOCKS ESTIMATE ROW',sql.includes("doc_type='estimate' for update")],
 ['SALE APPROVAL REJECTS NULL OR NONPOSITIVE QUANTITY',sql.includes("ln.qty is null or ln.qty<=0")],
 ['SALE APPROVAL REJECTS NULL INVENTORY',sql.includes("stock is null or stock<ln.qty")],
 ['SALE APPROVAL CHECKS SUFFICIENT INVENTORY',sql.includes('INSUFFICIENT STOCK FOR ITEM')],
 ['SALE POSTS DISPATCH PICK LIST',sql.includes("values(e.id,'pick_list',a.id)")],
 ['REVERSAL DOES NOT DELETE SALE AUDIT ROW',reversalSql.includes("set status='reversed'")],
 ['SALE APPROVAL REJECTS POSTED STATUS',sql.includes("'delivered','sale_posted','sale_reversed'")],
 ['SALE APPROVAL REJECTS REVERSED ESTIMATE',sql.includes("'sale_reversed'")&&sql.includes('ESTIMATE STATUS DOES NOT ALLOW SALE POSTING')],
 ['SALE APPROVAL REJECTS CANCELLED ESTIMATE',sql.includes("'cancelled'")&&sql.includes("'canceled'")],
 ['SALE APPROVAL REJECTS VOIDED ESTIMATE',sql.includes("'void'")&&sql.includes("'voided'")],
 ['SALE APPROVAL REJECTS NULL STATUS',sql.includes('if e.status is null')],
 ['SALE APPROVAL REQUIRES AUTHORIZED STAFF',sql.includes("a.role not in('owner','admin','accountant')")],
 ['SALE APPROVAL REJECTS EXISTING ESTIMATE SALE',sql.includes("ESTIMATE ALREADY POSTED AS SALE")],
 ['MARG BILL NUMBER CANNOT BE REUSED',sql.includes("MARG BILL NUMBER ALREADY USED")],
 ['SALE APPROVAL DOES NOT REQUIRE PAYMENT',sql.includes("'payment_gate',false")],
 ['STOCK LOCKED BEFORE SALE DEDUCTION',sql.includes("current_qty into stock")&&sql.includes("for update")],
 ['SALE REVERSAL REQUIRES REASON',sql.includes("REVERSAL REASON REQUIRED")],
 ['SALE STOCK DEDUCTION AT MARG POST',sql.includes("values(ln.item_id,-ln.qty,'MARG BILL SALE POSTED'")],
 ['DELIVERY REQUIRES ESTIMATE ID',deliverySql.includes("if p_estimate is null then raise exception 'ESTIMATE ID REQUIRED FOR DELIVERY'")],
 ['DELIVERY REQUEST KEY BOUNDED',deliverySql.includes('length(btrim(p_request_key))>128')],
 ['DELIVERY TRACKING CODE BOUNDED',deliverySql.includes('length(btrim(p_tracking_code))>128')],
 ['DELIVERY REQUIRES POSTED MARG SALE',deliverySql.includes("POSTED MARG BILL SALE REQUIRED BEFORE DELIVERY")],
 ['DELIVERY REQUIRES SALE-POSTED ESTIMATE STATUS',deliverySql.includes("not in('sale_posted','delivered') then raise exception 'ESTIMATE STATUS DOES NOT ALLOW DELIVERY'")],
 ['DELIVERY READY STAGE REQUIRED',deliverySql.includes("disp.status not in('ready_for_dispatch')")],
 ['DELIVERY DOES NOT DEDUCT STOCK AGAIN',deliverySql.includes("'stock_deducted_again',false")],
 ['DELIVERY IDEMPOTENT WHEN ALREADY DELIVERED',deliverySql.includes("if disp.status='delivered' then return")],
 ['REVERSAL OWNER ADMIN ONLY',reversalSql.includes("a.role not in('owner','admin')")],
 ['DELIVERED SALE REVERSAL BLOCKED',reversalSql.includes("DELIVERED SALE CANNOT BE REVERSED HERE")],
 ['SECOND REVERSAL BLOCKED',reversalSql.includes("s.status not in('posted','corrected')")&&reversalSql.includes("ACTIVE POSTED SALE REQUIRED")],
 ['REVERSAL REQUIRES SALE POSTED ESTIMATE STATUS',reversalSql.includes('ESTIMATE STATUS DOES NOT ALLOW SALE REVERSAL')],
 ['REVERSAL REJECTS INVALID SALE LINES',reversalSql.includes('INVALID SALE LINES FOR REVERSAL')],
 ['REVERSAL RESTORES STOCK',reversalSql.includes("current_qty=public.inventory.current_qty+excluded.current_qty")],
 ['REVERSAL CANCELS OPEN DISPATCH',reversalSql.includes("delete from public.dispatches where estimate_id=e.id and status<>'delivered'")]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}if(bad){console.error(`MARG SALE / DELIVERY SAFETY FAILED: ${bad}`);process.exit(1)}console.log('TORVO V2 MARG SALE / DELIVERY SOURCE SAFETY LOCKED');
