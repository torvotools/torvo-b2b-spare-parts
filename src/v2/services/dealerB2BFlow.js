import{requireBackend}from'./supabase';
const db=()=>requireBackend();
const id=v=>String(v||'').trim();
const qty=v=>{const n=Number(v);if(!Number.isInteger(n)||n<1||n>9999)throw new Error('VALID QUANTITY REQUIRED');return n};
const rpc=async(name,args)=>{const{data,error}=await db().rpc(name,args);if(error)throw error;return Array.isArray(data)?data[0]??null:data};

export async function createDealerPO({dealerId,items,note=''}){
 const dealer=id(dealerId);if(!dealer)throw new Error('DEALER REQUIRED');
 const clean=(items||[]).map(x=>({product_id:id(x.product_id),quantity:qty(x.quantity)})).filter(x=>x.product_id);
 if(!clean.length)throw new Error('AT LEAST ONE PRODUCT REQUIRED');
 return rpc('dealer_create_purchase_order',{p_dealer_id:dealer,p_items:clean,p_note:String(note||'').trim().slice(0,500)||null});
}
export async function loadDealerOrders(dealerId){const dealer=id(dealerId);if(!dealer)throw new Error('DEALER REQUIRED');return(await rpc('dealer_list_orders',{p_dealer_id:dealer}))||[]}
export async function loadDealerOrder(orderId){const order=id(orderId);if(!order)throw new Error('ORDER REQUIRED');return rpc('dealer_order_detail',{p_order_id:order})}
export async function approveLatestDealerOrder(orderId,revision){const order=id(orderId),rev=Number(revision);if(!order||!Number.isInteger(rev)||rev<1)throw new Error('ORDER REVISION REQUIRED');return rpc('dealer_approve_latest_order',{p_order_id:order,p_revision:rev})}
export async function createAdditionalPO({dealerId,parentOrderId,items,note=''}){const parent=id(parentOrderId);if(!parent)throw new Error('PARENT ORDER REQUIRED');const r=await createDealerPO({dealerId,items,note});return rpc('dealer_link_additional_po',{p_purchase_order_id:r?.purchase_order_id||r?.id,p_parent_order_id:parent})}
export async function loadDealerEstimate(orderId){const order=id(orderId);if(!order)throw new Error('ORDER REQUIRED');return rpc('dealer_order_estimate',{p_order_id:order})}
export async function loadDealerDelivery(orderId){const order=id(orderId);if(!order)throw new Error('ORDER REQUIRED');return rpc('dealer_order_delivery_status',{p_order_id:order})}
