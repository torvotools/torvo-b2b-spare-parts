import{forceSignOut}from'./auth';import{requireBackend}from'./supabase';import{deviceId,isStaffRole}from'./staffAuth';
const KEY='torvo_staff_session_id';
export function rememberStaffSession(id){if(id)localStorage.setItem(KEY,id)}
export function clearStaffSession(){localStorage.removeItem(KEY)}
export async function enforceStaffSession(user){if(!user?.active||!isStaffRole(user.role))return true;const id=localStorage.getItem(KEY);if(!id){await forceSignOut();return false}const client=requireBackend();const{data:{user:authUser}}=await client.auth.getUser();if(!authUser){clearStaffSession();return false}const{data,error}=await client.rpc('staff_session_valid',{p_session_id:id,p_auth_user_id:authUser.id,p_device_id:deviceId()});if(error||!data){clearStaffSession();await forceSignOut();return false}return true}
