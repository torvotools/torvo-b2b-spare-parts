import{requireBackend}from'./supabase';
const rpc=async(name,args={})=>{const{data,error}=await requireBackend().rpc(name,args);if(error)throw error;return data};
export async function setMasterSalesman(appUserId,enabled){return rpc('admin_set_master_salesman',{p_app_user_id:appUserId,p_enabled:Boolean(enabled)})}
export async function isMasterSalesman(){return Boolean(await rpc('is_master_salesman'))}
export async function loadSalesmanVisibleDealers(){const data=await rpc('salesman_visible_dealers');return Array.isArray(data)?data:[]}
