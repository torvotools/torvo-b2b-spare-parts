import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';
const machineId=v=>{const s=String(v??'').trim();if(!s)throw new Error('MACHINE REQUIRED');if(s.length>128)throw new Error('MACHINE IS INVALID');return s};
export async function loadDealerMachineSpares(value){
 const machine=machineId(value);
 const proof=await assertDealerSession();
 if(!proof?.deviceId||!proof?.token)throw new Error('ACTIVE DEALER DEVICE SESSION REQUIRED');
 const{data,error}=await requireBackend().rpc('get_dealer_machine_spares',{p_device_id:proof.deviceId,p_session_token:proof.token,p_machine:machine});
 if(error)throw error;
 await assertDealerSession();
 if(data==null)return[];
 if(!Array.isArray(data))throw new Error('INVALID MACHINE SPARES RESPONSE');
 return data;
}
