import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';
const db=()=>requireBackend();
const id=v=>String(v||'').trim();
const qty=v=>{const n=Number(v);if(!Number.isFinite(n)||n<=0||n>9999)throw new Error('VALID QUANTITY REQUIRED');return n};
const staffRpc=async(name,args={})=>{const{data,error}=await db().rpc(name,args);if(error)throw error;return data};
const dealerRpc=async(name,args={})=>{const proof=await assertDealerSession();if(!proof?.deviceId||!proof?.token)throw new Error('ACTIVE DEALER DEVICE SESSION REQUIRED');const{data,error}=await db().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
const lines=items=>{const seen=new Set();const clean=(items||[]).map(x=>{const item_id=id(x.item_id||x.product_id),q=qty(x.qty??x.quantity);if(!item_id)throw new Error('PRODUCT REQUIRED');if(seen.has(item_id))throw new Error('DUPLICATE PRODUCT NOT ALLOWED');seen.add(item_id);return{item_id,qty:q}});if(!clean.length)throw new Error('AT LEAST ONE PRODUCT REQUIRED');if(clean.length>500)throw new Error('TOO MANY PRODUCTS');return clean};

// Dealer-private reads/actions are device-bound. SQL resolves dealer identity from auth/session; no dealer id is accepted from UI.
export async function loadDealerOrders(){const data=await dealerRpc('get_dealer_order_history_30d');return Array.isArray(data)?data:[]}
export async function approveLatestDealerOrder(orderId,revision){const order=id(orderId),rev=Number(revision);if(!order||!Number.isInteger(rev)||rev<1)throw new Error('ORDER REVISION REQUIRED');await dealerRpc('dealer_confirm_sales_order_revision',{p_sales_order:order,p_revision:rev});return{order_id:order,revision_no:rev,status:'DEALER_OK'}}
export async function createAdditionalPO({parentOrderId,items,note=''}){const parent=id(parentOrderId);if(!parent)throw new Error('PARENT ORDER REQUIRED');const orderId=await dealerRpc('request_additional_purchase_order',{p_original_sales_order:parent,p_lines:lines(items),p_reason:String(note||'').trim().slice(0,500)||null});return{order_id:orderId,parent_order_id:parent,status:'PENDING_APPROVAL'}}

// Staff-only mutations rely on their SQL role checks and never receive dealer device credentials.
export async function decideAdditionalPO({orderId,approve,reason}){const order=id(orderId),why=String(reason||'').trim();if(!order)throw new Error('ORDER REQUIRED');if(!why)throw new Error('DECISION REASON REQUIRED');await staffRpc('decide_additional_purchase_order',{p_additional_sales_order:order,p_approve:approve===true,p_reason:why.slice(0,500)});return{order_id:order,status:approve===true?'APPROVED':'REJECTED'}}
export async function applySalesOrderRevision({orderId,items,reason}){const order=id(orderId),why=String(reason||'').trim();if(!order)throw new Error('ORDER REQUIRED');if(!why)throw new Error('REVISION REASON REQUIRED');const revision=await staffRpc('torvo_apply_sales_order_revision',{p_sales_order:order,p_lines:lines(items),p_reason:why.slice(0,500)});return{order_id:order,revision_no:Number(revision),status:'REVISED'}}
export async function convertOrderToEstimate(orderId){const order=id(orderId);if(!order)throw new Error('ORDER REQUIRED');const estimateId=await staffRpc('convert_sales_order_to_estimate',{p_sales_order:order});return{order_id:order,estimate_id:estimateId,status:'ESTIMATE_CREATED'}}
