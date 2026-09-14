import{requireBackend}from'./supabase';import{assertDealerSession}from'./dealerSession';
const call=async(name,args)=>{const proof=await assertDealerSession();const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:proof.deviceId,p_session_token:proof.token});if(error)throw error;await assertDealerSession();return data};
const qty=v=>{const n=Number(v);if(!Number.isInteger(n)||n<1||n>9999)throw new Error('QUANTITY MUST BE INTEGER 1 TO 9999');return n};
export const dealerItemRate=(itemId,quantity)=>call('dealer_item_rate',{p_item:itemId,p_qty:qty(quantity)});
export const submitDealerPurchaseOrder=lines=>{const clean=(lines||[]).map(x=>({item_id:x.item_id,qty:qty(x.qty)}));if(!clean.length)throw new Error('PURCHASE ORDER REQUIRES AT LEAST ONE ITEM');if(new Set(clean.map(x=>x.item_id)).size!==clean.length)throw new Error('DUPLICATE ITEM IS NOT ALLOWED');return call('submit_purchase_order',{p_lines:clean})};
