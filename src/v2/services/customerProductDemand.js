import{requireBackend}from'./supabase';
const db=()=>requireBackend();
const cleanMobile=v=>String(v||'').replace(/\D/g,'').slice(-10);
const cleanPin=v=>String(v||'').replace(/\D/g,'').slice(0,6);
const cleanId=v=>String(v||'').trim();
const cleanText=(v,max,label='VALUE')=>{const x=String(v||'').trim();if(x.length>max)throw new Error(`${label} MUST BE ${max} CHARACTERS OR LESS`);return x};
const one=data=>Array.isArray(data)?data[0]:data;
export async function createCustomerProductDemand({name,mobile,pin,searchText,productId=null,brand=null,modelNumber=null,requirementNote=null,marketing=false}={}){
 const fullName=cleanText(name,120,'CUSTOMER NAME'),m=cleanMobile(mobile),p=cleanPin(pin),q=cleanText(searchText,200,'PRODUCT SEARCH'),pid=cleanId(productId)||null,b=cleanText(brand,120,'BRAND')||null,model=cleanText(modelNumber,120,'MODEL NUMBER')||null,note=cleanText(requirementNote,500,'REQUIREMENT NOTE')||null;
 if(fullName.length<2)throw new Error('CUSTOMER NAME REQUIRED');if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');if(p.length!==6)throw new Error('6-DIGIT PIN CODE REQUIRED');if(q.length<2)throw new Error('PRODUCT SEARCH REQUIRED');
 const{data,error}=await db().rpc('public_create_product_demand',{p_full_name:fullName,p_mobile:m,p_pin_code:p,p_search_text:q,p_product_id:pid,p_brand:b,p_model_number:model,p_requirement_note:note,p_marketing_opt_in:Boolean(marketing)});
 if(error)throw error;const result=one(data);if(!result?.demand_id)throw new Error('CUSTOMER REQUIREMENT CREATION FAILED');return result;
}
export async function requestTorvoProductHelp(demandId,mobile){
 const id=cleanId(demandId),m=cleanMobile(mobile);if(!id)throw new Error('CUSTOMER REQUIREMENT REQUIRED');if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');
 const{data,error}=await db().rpc('public_request_torvo_product_help',{p_demand_id:id,p_mobile:m});if(error)throw error;const result=one(data);if(!result?.demand_id)throw new Error('TORVO HELP REQUEST FAILED');return result;
}
export async function loadCustomerProductDemandResult(demandId,mobile){
 const id=cleanId(demandId),m=cleanMobile(mobile);if(!id)throw new Error('CUSTOMER REQUIREMENT REQUIRED');if(m.length!==10)throw new Error('10-DIGIT MOBILE REQUIRED');
 const{data,error}=await db().rpc('public_customer_demand_result',{p_demand_id:id,p_mobile:m});if(error)throw error;
 const result=one(data);if(!result)return null;
 const status=String(result.status||'').trim().toLowerCase();return{demand_id:result.demand_id||id,status,search_text:cleanText(result.search_text,200,'PRODUCT SEARCH'),message:cleanText(result.message,500,'MESSAGE'),found_dealer_id:status==='available'?result.found_dealer_id||null:null,found_contact_note:status==='available'?cleanText(result.found_contact_note,1000,'CONTACT NOTE')||null:null,available_at:status==='available'?result.available_at||null:null};
}
