import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';

const proof=async()=>{
  const session=await assertDealerSession();
  if(!session?.deviceId||!session?.token)throw new Error('ACTIVE DEALER DEVICE SESSION REQUIRED');
  return session;
};

export const loadDealerRepairRequirements=async(status=null,limit=100)=>{
  const session=await proof();
  const{data,error}=await requireBackend().rpc('dealer_repair_requirements',{
    p_status:status||null,
    p_limit:Math.max(1,Math.min(Number(limit)||100,500)),
    p_device_id:session.deviceId,
    p_session_token:session.token
  });
  if(error)throw error;
  await assertDealerSession();
  if(data==null)return[];
  if(!Array.isArray(data))throw new Error('INVALID DEALER REPAIR RESPONSE');
  return data;
};

export const updateDealerRepairRequirement=async(requirementId,status)=>{
  if(!requirementId)throw new Error('REPAIR REQUIREMENT REQUIRED');
  const next=String(status||'').trim().toLowerCase();
  if(!['accepted','closed'].includes(next))throw new Error('REPAIR STATUS MUST BE ACCEPTED OR CLOSED');
  const session=await proof();
  const{data,error}=await requireBackend().rpc('dealer_update_repair_requirement',{
    p_requirement_id:requirementId,
    p_status:next,
    p_device_id:session.deviceId,
    p_session_token:session.token
  });
  if(error)throw error;
  await assertDealerSession();
  if(data!==true)throw new Error('REPAIR UPDATE NOT CONFIRMED');
  return true;
};
