import{requireBackend}from'./supabase';import{assertDealerSession}from'./dealerSession';
const rpc=async(name,args={})=>{const proof=await assertDealerSession();const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
export const loadDealerWorkspaceCatalog=async()=>{const rows=await rpc('dealer_workspace_catalog');return Array.isArray(rows)?rows:[]};
export const loadDealerOrderHistory=async()=>{const rows=await rpc('get_dealer_order_history_30d');return Array.isArray(rows)?rows:[]};
export const loadDealerWorkspace=async()=>{const[catalog,history]=await Promise.all([loadDealerWorkspaceCatalog(),loadDealerOrderHistory()]);return{catalog,history}};
