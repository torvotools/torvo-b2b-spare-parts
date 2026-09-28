import{requireBackend}from'./supabase';
const db=()=>requireBackend(),fail=e=>{if(e)throw e};
export async function approveMargBillSale(estimateNumber,billNumber){const bill=String(billNumber||'').trim().toUpperCase();if(!estimateNumber)throw new Error('ESTIMATE REQUIRED');if(!bill)throw new Error('MARG BILL NUMBER REQUIRED');const{data,error}=await db().rpc('approve_marg_bill_sale',{p_estimate_number:String(estimateNumber).trim().toUpperCase(),p_marg_bill_no:bill});fail(error);return data}
export async function loadMargBillSaleQueue(){const{data,error}=await db().rpc('get_marg_bill_sale_queue');fail(error);return data??[]}

export async function reviseEstimateBeforeSale(estimateNumber,lines,reason){if(!estimateNumber||!String(reason||'').trim())throw new Error('ESTIMATE AND REVISION REASON REQUIRED');const{data,error}=await db().rpc('revise_estimate_before_sale',{p_estimate_number:String(estimateNumber).trim().toUpperCase(),p_lines:lines,p_reason:String(reason).trim()});fail(error);return data}
export async function reverseMargBillSale(estimateNumber,reason){if(!estimateNumber||!String(reason||'').trim())throw new Error('ESTIMATE AND REVERSAL REASON REQUIRED');const{error}=await db().rpc('reverse_marg_bill_sale',{p_estimate_number:String(estimateNumber).trim().toUpperCase(),p_reason:String(reason).trim()});fail(error);return true}
