import{requireBackend}from'./supabase';
const rpc=async(name,args)=>{const{data,error}=await requireBackend().rpc(name,args);if(error)throw error;return data};
export async function configureStaffAccess(staffUserId,username,employeeName,role){return rpc('admin_upsert_staff_access',{p_app_user_id:staffUserId,p_username:String(username||'').trim().toUpperCase(),p_employee_name:String(employeeName||'').trim().toUpperCase(),p_staff_role:String(role||'').trim().toLowerCase()})}
export async function setStaffOtpMasterEmail(email){return rpc('admin_set_staff_otp_email',{p_email:String(email||'').trim().toLowerCase()})}
export async function approveStaffDevice(staffUserId,deviceId,deviceType){return rpc('admin_approve_staff_device',{p_app_user_id:staffUserId,p_device_id:String(deviceId||'').trim(),p_device_type:String(deviceType||'').trim().toLowerCase()})}
export async function revokeStaffAccess(staffUserId){return rpc('admin_revoke_staff_access',{p_app_user_id:staffUserId})}
export async function createEmergencyAccess(staffUserId,code,reason,minutes=30){return rpc('admin_create_staff_emergency_code',{p_staff_user_id:staffUserId,p_code:String(code||''),p_reason:String(reason||'').trim(),p_minutes:Number(minutes)})}
export async function revokeEmergencyAccess(staffUserId){return rpc('admin_revoke_staff_emergency_codes',{p_staff_user_id:staffUserId})}
