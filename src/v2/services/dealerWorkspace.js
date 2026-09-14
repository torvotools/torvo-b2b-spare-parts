import{requireBackend}from'./supabase';import{assertDealerSession}from'./dealerSession';
const rpc=async(name,args={})=>{if(typeof name!=='string'||!name.trim())throw new Error('DEALER RPC REQUIRED');const proof=await assertDealerSession();if(!proof?.deviceId||!proof?.token)throw new Error('ACTIVE DEALER DEVICE SESSION REQUIRED');const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
const rows=(value,label)=>{if(value==null)return[];if(!Array.isArray(value))throw new Error(`INVALID ${label} RESPONSE`);return value};
export const loadDealerWorkspaceCatalog=async()=>rows(await rpc('dealer_workspace_catalog'),'DEALER CATALOG');
export const loadDealerOrderHistory=async()=>rows(await rpc('get_dealer_order_history_30d'),'DEALER ORDER HISTORY');
export const loadDealerWorkspace=async()=>{await assertDealerSession();const[catalog,history]=await Promise.all([loadDealerWorkspaceCatalog(),loadDealerOrderHistory()]);await assertDealerSession();return{catalog,history}};
export const refreshDealerWorkspace=async()=>{const result=await loadDealerWorkspace();return{catalog:[...result.catalog],history:[...result.history]}};
