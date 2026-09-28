import{requireBackend}from'./supabase';
const db=()=>requireBackend(),fail=e=>{if(e)throw e};
export async function approveMargBillSale(estimateId,billNumber){const bill=String(billNumber||'').trim().toUpperCase();if(!estimateId)throw new Error('ESTIMATE REQUIRED');if(!bill)throw new Error('MARG BILL NUMBER REQUIRED');const{data,error}=await db().rpc('approve_marg_bill_sale',{p_estimate:estimateId,p_marg_bill_number:bill});fail(error);return data}
export async function loadMargBillSaleQueue(){const{data,error}=await db().rpc('get_marg_bill_sale_queue');fail(error);return data??[]}
