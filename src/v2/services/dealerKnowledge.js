import{requireBackend}from'./supabase';import{assertDealerSession}from'./dealerSession';
const rpc=async(name,args={})=>{const proof=await assertDealerSession();const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
export const loadDealerKnowledge=async()=>{const[challenges,history]=await Promise.all([rpc('dealer_knowledge_challenges'),rpc('dealer_knowledge_history')]);return{challenges:challenges||[],history:history||[]}};
export const submitDealerKnowledge=async v=>rpc('submit_knowledge_answer',{p_challenge:v.challenge,p_part_name:v.partName||null,p_brand:v.brand,p_machine_type:v.machineType||null,p_model:v.model,p_notes:v.notes||null});
