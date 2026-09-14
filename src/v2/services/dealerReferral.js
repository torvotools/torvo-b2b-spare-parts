import{assertDealerSession}from'./dealerSession';import{requireBackend}from'./supabase';
const code=v=>{const x=String(v||'').trim().toUpperCase();if(!/^TV-[A-Z0-9]{3,32}$/.test(x))throw new Error('ENTER A VALID TORVO REFERRAL CODE.');return x};
const qty=v=>{const n=Math.floor(Number(v));if(!Number.isFinite(n)||n<1||n>9999)throw new Error('ENTER A VALID QUANTITY.');return n};
async function guardedRpc(name,args){await assertDealerSession();const{data,error}=await requireBackend().rpc(name,args);if(error)throw error;return Array.isArray(data)?data[0]??null:data}
export async function verifyDealerReferral(referralCode){return guardedRpc('dealer_verify_customer_referral',{p_referral_code:code(referralCode)})}
export async function dealerReferralSupply(referralCode){return guardedRpc('dealer_referral_supply_status',{p_referral_code:code(referralCode)})}
export async function confirmDealerReferralBenefit(referralCode){return guardedRpc('dealer_confirm_referral_benefit',{p_referral_code:code(referralCode)})}
export async function orderDealerReferralItem(referralCode,quantity){return guardedRpc('dealer_order_referral_item',{p_referral_code:code(referralCode),p_qty:qty(quantity)})}
export async function loadDealerReferralItems(){const data=await guardedRpc('dealer_referral_items',{});return Array.isArray(data)?data:data?[data]:[]}
