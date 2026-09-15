import{requireBackend}from'./supabase';
const db=()=>requireBackend();
const cleanMobile=v=>String(v||'').replace(/\D/g,'').slice(-10);
const cleanPin=v=>String(v||'').replace(/\D/g,'').slice(0,6);
const cleanId=v=>String(v||'').trim();
const one=data=>Array.isArray(data)?data[0]:data;
export async function createCustomerProductDemand({name,mobile,pin,searchText,productId=null,brand=null,modelNumber=null,requirementNote=null,marketing=false}){
 const m=cleanMobile(mobile),p=cleanPin(pin),q=String(searchText||'').trim();
 if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');if(p.length!==6)throw new Error('6-DIGIT PIN CODE REQUIRED');if(q.length<2)throw new Error('PRODUCT SEARCH REQUIRED');
 const{data,error}=await db().rpc('public_create_product_demand',{p_full_name:String(name||'').trim(),p_mobile:m,p_pin_code:p,p_search_text:q,p_product_id:productId||null,p_brand:brand||null,p_model_number:modelNumber||null,p_requirement_note:requirementNote||null,p_marketing_opt_in:Boolean(marketing)});
 if(error)throw error;return one(data);
}
export async function requestTorvoProductHelp(demandId,mobile){
 const id=cleanId(demandId),m=cleanMobile(mobile);if(!id)throw new Error('CUSTOMER REQUIREMENT REQUIRED');if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');
 const{data,error}=await db().rpc('public_request_torvo_product_help',{p_demand_id:id,p_mobile:m});if(error)throw error;return one(data);
}
export async function loadCustomerProductDemandResult(demandId,mobile){
 const id=cleanId(demandId),m=cleanMobile(mobile);if(!id)throw new Error('CUSTOMER REQUIREMENT REQUIRED');if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');
 const{data,error}=await db().rpc('public_customer_demand_result',{p_demand_id:id,p_mobile:m});if(error)throw error;
 const result=one(data);if(!result)return null;
 const status=String(result.status||'').trim().toLowerCase();return{demand_id:result.demand_id||id,status,search_text:String(result.search_text||'').trim(),message:String(result.message||'').trim(),found_dealer_id:status==='available'?result.found_dealer_id||null:null,found_contact_note:status==='available'?String(result.found_contact_note||'').trim()||null:null,available_at:status==='available'?result.available_at||null:null};
}
