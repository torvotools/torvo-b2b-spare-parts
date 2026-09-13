import{requireBackend}from'./supabase';
export async function createEmergencyAccess(staffUserId,code,reason,minutes=30){const client=requireBackend();const{data,error}=await client.rpc('admin_create_staff_emergency_code',{p_staff_user_id:staffUserId,p_code:String(code||''),p_reason:String(reason||'').trim(),p_minutes:Number(minutes)});if(error)throw error;return data}
export async function revokeEmergencyAccess(staffUserId){const client=requireBackend();const{data,error}=await client.rpc('admin_revoke_staff_emergency_codes',{p_staff_user_id:staffUserId});if(error)throw error;return data}
