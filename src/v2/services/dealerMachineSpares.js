import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';

export async function loadDealerMachineSpares(machineId){
 if(!machineId)throw new Error('MACHINE REQUIRED');
 const proof=await assertDealerSession();
 const{data,error}=await requireBackend().rpc('get_dealer_machine_spares',{p_device_id:proof.deviceId,p_session_token:proof.token,p_machine:machineId});
 if(error)throw error;
 await assertDealerSession();
 return data??[];
}
