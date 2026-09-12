import { supabase } from './supabase';
const ok=r=>{if(r.error)throw r.error;return r.data||[]};
export const purchaseService={
 async suppliers(){return ok(await supabase.from('suppliers').select('id,name,phone,gst_no,active').eq('active',true).order('name'))},
 async catalog(search='',type='',brand='',limit=100){const r=await supabase.rpc('search_purchase_catalog',{p_search:search||null,p_type:type||null,p_brand:brand||null,p_limit:limit});if(r.error)throw r.error;return r.data||[]},
 async purchases(){const purchases=ok(await supabase.from('purchase_headers').select('id,supplier_id,invoice_no,invoice_date,total_amount,created_at,suppliers(name)').order('created_at',{ascending:false}).limit(250));if(!purchases.length)return purchases;const ids=purchases.map(x=>x.id);const audits=ok(await supabase.from('audit_log').select('entity_id,created_at,details').eq('entity_type','purchase').eq('action','PURCHASE_REVERSED').in('entity_id',ids));const by=new Map(audits.map(x=>[x.entity_id,x]));return purchases.map(x=>({...x,reversal:by.get(x.id)||null}))},
 async purchaseLines(purchaseId){return ok(await supabase.from('purchase_lines').select('id,item_id,qty,purchase_rate,line_amount,catalog_items(item_code,oem_code,name,brand)').eq('purchase_id',purchaseId).order('id'))},
 async rateHistory(itemId,limit=20){const r=await supabase.rpc('get_item_purchase_rate_history',{p_item:itemId,p_limit:limit});if(r.error)throw r.error;return r.data||[]},
 async create({supplierId,invoiceNo,invoiceDate,lines,note}){const r=await supabase.rpc('create_purchase_entry',{p_supplier:supplierId,p_invoice_no:invoiceNo,p_invoice_date:invoiceDate,p_lines:lines.map(x=>({item_id:x.item_id,qty:Number(x.qty),purchase_rate:Number(x.purchase_rate)})),p_note:note||null});if(r.error)throw r.error;return r.data},
 async reverse(purchaseId,reason){const r=await supabase.rpc('reverse_purchase_entry',{p_purchase:purchaseId,p_reason:reason});if(r.error)throw r.error;return r.data}
};
