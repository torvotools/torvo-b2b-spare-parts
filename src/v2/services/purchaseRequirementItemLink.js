import{requireBackend}from'./supabase';
const db=()=>requireBackend();
export async function linkRequirementItem(requirementId,itemId,note=''){if(!requirementId||!itemId)throw new Error('Requirement and Item are required');const{error}=await db().rpc('link_new_item_requirement_to_catalog',{p_requirement:requirementId,p_item:itemId,p_note:String(note||'').trim()||null});if(error)throw error}
