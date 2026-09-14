import{requireBackend}from'./supabase';import{assertDealerSession}from'./dealerSession';
const rpc=async(name,args={})=>{const proof=await assertDealerSession();const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
export const confirmDealerSalesOrder=(orderId,revision)=>rpc('dealer_confirm_sales_order_revision',{p_sales_order:orderId,p_revision:revision});
export const requestDealerAdditionalOrder=(orderId,lines,reason)=>rpc('request_additional_purchase_order',{p_original_sales_order:orderId,p_lines:lines,p_reason:reason||null});
export const loadDealerOrderHistory=()=>rpc('get_dealer_order_history_30d');
