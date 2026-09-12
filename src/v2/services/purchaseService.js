import { supabase } from './supabase';

const ok = (r) => { if (r.error) throw r.error; return r.data || []; };

export const purchaseService = {
  async suppliers() {
    return ok(await supabase.from('suppliers').select('id,name,phone,gst_no,active').eq('active', true).order('name'));
  },
  async catalog() {
    return ok(await supabase.from('catalog_items').select('id,item_code,oem_code,name,brand,category,item_type,active').eq('active', true).order('item_code').limit(1000));
  },
  async purchases() {
    return ok(await supabase.from('purchase_headers').select('id,supplier_id,invoice_no,invoice_date,total_amount,created_at,suppliers(name)').order('created_at', { ascending:false }).limit(250));
  },
  async purchaseLines(purchaseId) {
    return ok(await supabase.from('purchase_lines').select('id,item_id,qty,purchase_rate,line_amount,catalog_items(item_code,oem_code,name,brand)').eq('purchase_id', purchaseId).order('id'));
  },
  async create({supplierId,invoiceNo,invoiceDate,lines,note}) {
    const r = await supabase.rpc('create_purchase_entry',{p_supplier:supplierId,p_invoice_no:invoiceNo,p_invoice_date:invoiceDate,p_lines:lines.map(x=>({item_id:x.item_id,qty:Number(x.qty),purchase_rate:Number(x.purchase_rate)})),p_note:note||null});
    if(r.error) throw r.error; return r.data;
  },
  async reverse(purchaseId, reason) {
    const r=await supabase.rpc('reverse_purchase_entry',{p_purchase:purchaseId,p_reason:reason});
    if(r.error) throw r.error; return r.data;
  }
};
