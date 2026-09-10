import{requireBackend}from'./supabase';
const db=()=>requireBackend(); const fail=e=>{if(e)throw e};
export const data={
 async list(table,{select='*',order='created_at',ascending=false}={}){const{data,error}=await db().from(table).select(select).order(order,{ascending});fail(error);return data??[]},
 async dealers(){return this.list('dealers')},
 async catalog(type){const{data,error}=await db().from('catalog_items').select('*').eq('item_type',type).order('name');fail(error);return data??[]},
 async documents(type){const{data,error}=await db().from('sales_documents').select('*,dealers(shop_name,dealer_code),sales_document_lines(*)').eq('doc_type',type).order('created_at',{ascending:false});fail(error);return data??[]},
 async inventory(){const{data,error}=await db().from('inventory').select('*,catalog_items(item_code,name,item_type,brand,model)').order('updated_at',{ascending:false});fail(error);return data??[]},
 async dispatches(){const{data,error}=await db().from('dispatches').select('id,estimate_id,status,tracking_code,delivered_at,stock_deducted_at').order('status');fail(error);return data??[]},
 async storeQueue(){const{data,error}=await db().rpc('get_store_fulfilment_queue');fail(error);return data??[]},
 async compatibility(){const{data,error}=await db().from('machine_spare_mapping').select('*,machine:catalog_items!machine_id(*),spare_part:catalog_items!spare_part_id(*)');fail(error);return data??[]},
 async approveDealer(dealerId,dealerCode,rateGroup){const{error}=await db().rpc('approve_dealer',{p_dealer:dealerId,p_dealer_code:dealerCode,p_rate_group:rateGroup});fail(error)},
 async setDealerStatus(dealerId,status,reason){const{error}=await db().rpc('set_dealer_request_status',{p_dealer:dealerId,p_status:status,p_reason:reason});fail(error)},
 async recordPayment(estimateId,status,amount){const{data,error}=await db().rpc('record_payment',{p_estimate:estimateId,p_status:status,p_amount:amount});fail(error);return data},
 async advanceDispatch(estimateId,status,trackingCode=null){const{error}=await db().rpc('advance_dispatch',{p_estimate:estimateId,p_status:status,p_tracking_code:trackingCode});fail(error)},
 async deliver(estimateId){const{error}=await db().rpc('deliver_estimate',{p_estimate:estimateId});fail(error)}
};
