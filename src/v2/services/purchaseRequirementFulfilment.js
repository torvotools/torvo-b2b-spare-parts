import{requireBackend}from'./supabase';
const db=()=>requireBackend();
const fail=e=>{if(e)throw e};
// Requirement fulfilment is operational quantity linkage only. Purchase Rate is never returned here.
export async function purchaseRequirementPurchases(requirementId){if(!requirementId)throw new Error('Requirement is required');const{data,error}=await db().rpc('get_requirement_purchase_candidates',{p_requirement:requirementId,p_limit:100});fail(error);return data??[]}
export async function purchaseRequirementLinks(requirementId){if(!requirementId)throw new Error('Requirement is required');const{data,error}=await db().rpc('get_purchase_requirement_links',{p_requirement:requirementId});fail(error);return data??[]}
export async function linkPurchaseToRequirement(requirementId,purchaseId,qty,note=''){if(!requirementId||!purchaseId)throw new Error('Requirement and Purchase are required');if(!Number(qty)||Number(qty)<=0)throw new Error('Valid linked quantity required');const{data,error}=await db().rpc('link_purchase_to_requirement',{p_requirement:requirementId,p_purchase:purchaseId,p_qty:Number(qty),p_note:String(note||'').trim()||null});fail(error);return Number(data||0)}
export async function reversePurchaseRequirementLink(linkId,reason){if(!String(reason||'').trim())throw new Error('Reversal reason required');const{error}=await db().rpc('reverse_purchase_requirement_link',{p_link:linkId,p_reason:String(reason).trim()});fail(error)}
