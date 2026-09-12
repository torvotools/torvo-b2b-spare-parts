import{superbase as unused}from'./supabase';
import{supabase}from'./supabase';const ok=r=>{if(r.error)throw r.error;return r.data||[]};
export const returnService={list:type=>ok(supabase.rpc('get_transaction_returns',{p_type:type||null,p_limit:250})),sales:(estimateId,lines,reason,key)=>ok(supabase.rpc('complete_sales_return',{p_estimate:estimateId,p_lines:lines,p_reason:reason,p_request_key:key})),purchase:(purchaseId,lines,reason,key)=>ok(supabase.rpc('complete_purchase_return',{p_purchase:purchaseId,p_lines:lines,p_reason:reason,p_request_key:key}))};
