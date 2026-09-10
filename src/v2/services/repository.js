import{requireBackend}from'./supabase';
const db=()=>requireBackend(); const fail=e=>{if(e)throw e};
export const data={
 async storeQueue(){const{data,error}=await db().rpc('get_store_fulfilment_queue');fail(error);return data??[]},
 async approveDealer(dealerId,dealerCode,rateGroup){const{error}=await db().rpc('approve_dealer',{p_dealer:dealerId,p_dealer_code:dealerCode,p_rate_group:rateGroup});fail(error)},
 async setDealerStatus(dealerId,status,reason){const{error}=await db().rpc('set_dealer_request_status',{p_dealer:dealerId,p_status:status,p_reason:reason});fail(error)},
 async recordPayment(estimateId,status,amount){const{data,error}=await db().rpc('record_payment',{p_estimate:estimateId,p_status:status,p_amount:amount});fail(error);return data},
 async advanceDispatch(estimateId,status,trackingCode=null){const{error}=await db().rpc('advance_dispatch',{p_estimate:estimateId,p_status:status,p_tracking_code:trackingCode});fail(error)},
 async deliver(estimateId){const{error}=await db().rpc('deliver_estimate',{p_estimate:estimateId});fail(error)}
};
