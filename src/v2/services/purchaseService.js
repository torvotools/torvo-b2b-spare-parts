import { supabase } from './supabase';
const ok=r=>{if(r.error)throw r.error;return r.data||[]};
export const purchaseService={
 async suppliers(){return ok(await supabase.rpc('get_purchase_suppliers'))},
 async catalog(search='',type='',brand='',limit=100){return ok(await supabase.rpc('search_purchase_catalog',{p_search:search||null,p_type:type||null,p_brand:brand||null,p_limit:limit}))},
 async purchases(search=''){const rows=ok(await supabase.rpc('get_purchase_entries',{p_search:search||null,p_limit:250}));return rows.map(x=>({...x,suppliers:{name:x.supplier_name},reversal:x.reversed_at?{created_at:x.reversed_at,details:{reason:x.reversal_reason}}:null}))},
 async purchaseLines(purchaseId){const rows=ok(await supabase.rpc('get_purchase_entry_lines',{p_purchase:purchaseId}));return rows.map(x=>({...x,catalog_items:{item_code:x.item_code,oem_code:x.oem_code,name:x.item_name,brand:x.brand}}))},
 async rateHistory(itemId,limit=20){return ok(await supabase.rpc('get_item_purchase_rate_history',{p_item:itemId,p_limit:limit}))},
 async buyingIntelligence(itemId,supplierId=null,limit=8){const r=await supabase.rpc('get_purchase_buying_intelligence',{p_item:itemId,p_supplier:supplierId||null,p_limit:limit});if(r.error)throw r.error;return(r.data||[])[0]||null},
 async saveAndReceive({supplierId,invoiceNo,invoiceDate,lines,note,requestKey}){const r=await supabase.rpc('save_and_receive_purchase_entry',{p_supplier:supplierId,p_invoice_no:invoiceNo,p_invoice_date:invoiceDate,p_lines:lines.map(x=>({item_id:x.item_id,qty:Number(x.qty),purchase_rate:Number(x.purchase_rate)})),p_note:note||null,p_request_key:requestKey});if(r.error)throw r.error;return r.data},
 async submitForApproval({supplierId,invoiceNo,invoiceDate,lines,note,requestKey}){const r=await supabase.rpc('submit_purchase_for_approval',{p_supplier:supplierId,p_invoice_no:invoiceNo,p_invoice_date:invoiceDate,p_lines:lines.map(x=>({item_id:x.item_id,qty:Number(x.qty),purchase_rate:Number(x.purchase_rate)})),p_note:note||null,p_request_key:requestKey});if(r.error)throw r.error;return r.data},
 async create({supplierId,invoiceNo,invoiceDate,lines,note}){const r=await supabase.rpc('create_purchase_entry',{p_supplier:supplierId,p_invoice_no:invoiceNo,p_invoice_date:invoiceDate,p_lines:lines.map(x=>({item_id:x.item_id,qty:Number(x.qty),purchase_rate:Number(x.purchase_rate)})),p_note:note||null});if(r.error)throw r.error;return r.data},
 async receive(purchaseId,requestKey){const r=await supabase.rpc('receive_purchase_stock',{p_purchase:purchaseId,p_request_key:requestKey});if(r.error)throw r.error;return r.data},
 async reverse(purchaseId,reason){const r=await supabase.rpc('reverse_purchase_entry',{p_purchase:purchaseId,p_reason:reason});if(r.error)throw r.error;return r.data}
};
