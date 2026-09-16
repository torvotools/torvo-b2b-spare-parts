import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';
import{dealerItemRate,submitDealerPurchaseOrder,confirmDealerSalesOrder,requestDealerAdditionalOrder,loadDealerOrderHistory,reviseDealerPurchaseOrder,requestDealerSalesOrderChange,loadApprovedAdditionalRequests,createApprovedAdditionalOrder}from'./dealerBusiness';
const db=()=>requireBackend();
const id=(v,label='ID')=>{const s=String(v||'').trim();if(!s)throw new Error(`${label} IS REQUIRED`);if(s.length>128)throw new Error(`${label} IS INVALID`);return s};
const qty=v=>{const n=Number(v);if(!Number.isInteger(n)||n<1||n>9999)throw new Error('QUANTITY MUST BE INTEGER 1 TO 9999');return n};
const staffRpc=async(name,args={})=>{const{data,error}=await db().rpc(name,args);if(error)throw error;return data};
const lines=items=>{if(!Array.isArray(items)||!items.length)throw new Error('AT LEAST ONE PRODUCT REQUIRED');if(items.length>500)throw new Error('TOO MANY PRODUCTS');const seen=new Set();return items.map(x=>{const item_id=id(x?.item_id||x?.product_id,'PRODUCT'),q=qty(x?.qty??x?.quantity);if(seen.has(item_id))throw new Error('DUPLICATE PRODUCT NOT ALLOWED');seen.add(item_id);return{item_id,qty:q}})};
const reason=v=>{const s=String(v||'').trim();if(s.length<3)throw new Error('REASON MUST BE AT LEAST 3 CHARACTERS');if(s.length>500)throw new Error('REASON IS TOO LONG');return s};
const rows=(v,label)=>{if(v==null)return[];if(!Array.isArray(v))throw new Error(`INVALID ${label} RESPONSE`);return v};
const resultId=(v,label)=>{if(typeof v==='string'||typeof v==='number')return id(v,label);if(v&&typeof v==='object')return id(v.order_id||v.id||v.sales_order_id||v.request_id,label);throw new Error(`INVALID ${label} RESPONSE`)};
export const verifyDealerB2BSession=()=>assertDealerSession();
export const getDealerItemRate=(itemId,quantity)=>dealerItemRate(id(itemId,'PRODUCT'),qty(quantity));
export const submitDealerPO=items=>submitDealerPurchaseOrder(lines(items));
export const loadDealerOrders=async()=>rows(await loadDealerOrderHistory(),'DEALER ORDER HISTORY');
export async function approveLatestDealerOrder(orderId,revision){const order=id(orderId,'ORDER'),rev=Number(revision);if(!Number.isInteger(rev)||rev<1)throw new Error('ORDER REVISION REQUIRED');await confirmDealerSalesOrder(order,rev);return{order_id:order,revision_no:rev,status:'DEALER_OK'}}
export async function createAdditionalPO({parentOrderId,items,note}){const parent=id(parentOrderId,'PARENT ORDER');const raw=await requestDealerAdditionalOrder(parent,lines(items),reason(note));const orderId=resultId(raw,'ADDITIONAL ORDER');return{order_id:orderId,parent_order_id:parent,status:'PENDING_APPROVAL'}}
export const reviseDealerPO=({orderId,items,reason:why})=>reviseDealerPurchaseOrder(id(orderId,'ORDER'),lines(items),reason(why));
export const requestDealerOrderChange=({orderId,type,reason:why})=>requestDealerSalesOrderChange(id(orderId,'ORDER'),type,reason(why));
export const loadApprovedAddOnRequests=async()=>rows(await loadApprovedAdditionalRequests(),'APPROVED ADD-ON REQUESTS');
export async function createApprovedAddOnOrder({requestId,items}){const request=id(requestId,'ADD-ON REQUEST'),raw=await createApprovedAdditionalOrder(request,lines(items));return{order_id:resultId(raw,'APPROVED ADD-ON ORDER'),request_id:request,status:'PENDING_APPROVAL'}}
// Staff-only mutations remain isolated from dealer-device APIs and rely on SQL role authorization.
export async function decideAdditionalPO({orderId,approve,reason:why}){const order=id(orderId,'ORDER'),r=reason(why);await staffRpc('decide_additional_purchase_order',{p_additional_sales_order:order,p_approve:approve===true,p_reason:r});return{order_id:order,status:approve===true?'APPROVED':'REJECTED'}}
export async function applySalesOrderRevision({orderId,items,reason:why}){const order=id(orderId,'ORDER'),r=reason(why);const revision=await staffRpc('torvo_apply_sales_order_revision',{p_sales_order:order,p_lines:lines(items),p_reason:r});const rev=Number(revision);if(!Number.isInteger(rev)||rev<1)throw new Error('INVALID REVISION RESPONSE');return{order_id:order,revision_no:rev,status:'REVISED'}}
export async function convertOrderToEstimate(orderId){const order=id(orderId,'ORDER');const estimateId=await staffRpc('convert_sales_order_to_estimate',{p_sales_order:order});return{order_id:order,estimate_id:id(estimateId,'ESTIMATE'),status:'ESTIMATE_CREATED'}}
