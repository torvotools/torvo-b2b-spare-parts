import{findDealers,loadDealerProfile,trackDealerReferralEvent}from'./publicWebsite';
const cleanId=v=>String(v||'').trim();
const productIdOf=product=>cleanId(product?.id||product?.product_id||product?.item_id)||null;
const dealerIdOf=dealer=>cleanId(dealer?.dealer_id||dealer?.id)||null;
const EVENT_TYPES=new Set(['DEALER_VIEW','MAP_OPEN','CALL_CLICK','WHATSAPP_CLICK']);
const viewed=new Set();
const safeTrack=async({dealer,eventType,product=null,enquiryId=null})=>{const dealerId=dealerIdOf(dealer),event=String(eventType||'').trim().toUpperCase();if(!dealerId||!EVENT_TYPES.has(event))return false;try{return await trackDealerReferralEvent({enquiryId:cleanId(enquiryId)||null,dealerId,eventType:event,productId:productIdOf(product)})}catch(error){console.warn('TORVO DEALER JOURNEY EVENT NOT RECORDED',event,error);return false}};
const trackViewOnce=async(dealer,product,enquiryId)=>{const key=[dealerIdOf(dealer),productIdOf(product)||'',cleanId(enquiryId)||''].join(':');if(viewed.has(key))return true;const ok=await safeTrack({dealer,eventType:'DEALER_VIEW',product,enquiryId});if(ok)viewed.add(key);return ok};
export async function findCustomerDealers(pin){const dealers=await findDealers(pin,false);return dealers.filter(x=>x?.product_sales_available===true&&dealerIdOf(x))}
export async function openCustomerDealerProfile(dealer,product=null,enquiryId=null){const dealerId=dealerIdOf(dealer);if(!dealerId)throw new Error('DEALER REQUIRED');const profile=await loadDealerProfile(dealerId);if(!profile?.product_sales_available)throw new Error('VERIFIED DEALER PROFILE NOT AVAILABLE');await trackViewOnce(profile,product,enquiryId);return profile}
export async function selectCustomerDealer(dealer,product=null,enquiryId=null){return openCustomerDealerProfile(dealer,product,enquiryId)}
export function recordCustomerDealerCall(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'CALL_CLICK',product,enquiryId})}
export function recordCustomerDealerWhatsApp(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'WHATSAPP_CLICK',product,enquiryId})}
export function recordCustomerDealerDirections(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'MAP_OPEN',product,enquiryId})}
// REFERRAL_CREATED is written atomically by public_create_customer_referral with its canonical enquiry id.
export function recordCustomerDealerReferral(){return Promise.resolve(true)}
