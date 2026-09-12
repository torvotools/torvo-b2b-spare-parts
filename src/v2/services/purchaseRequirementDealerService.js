import{requireBackend}from'./supabase';
const db=()=>requireBackend();
export async function getPurchaseRequirementDealers(){const{data,error}=await db().rpc('get_purchase_requirement_dealers');if(error)throw error;return data??[]}
