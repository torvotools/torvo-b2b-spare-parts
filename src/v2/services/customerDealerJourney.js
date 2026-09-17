import{findDealers,loadDealerProfile,trackDealerReferralEvent}from'./publicWebsite';
const cleanId=v=>String(v||'').trim();
const UUID_RE=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const validId=v=>{const id=cleanId(v);return UUID_RE.test(id)?id:null};
export const customerJourneyProductId=product=>validId(product?.id||product?.product_id||product?.item_id);
const dealerIdOf=dealer=>validId(dealer?.dealer_id||dealer?.id);
const EVENT_TYPES=new Set(['DEALER_VIEW','MAP_OPEN','CALL_CLICK','WHATSAPP_CLICK']);
const viewed=new Set();
const safeTrack=async({dealer,eventType,product=null,enquiryId=null})=>{const dealerId=dealerIdOf(dealer),event=String(eventType||'').trim().toUpperCase(),enquiry=cleanId(enquiryId)?validId(enquiryId):null;if(!dealerId||!EVENT_TYPES.has(event))return false;if(cleanId(enquiryId)&&!enquiry)return false;try{return await trackDealerReferralEvent({enquiryId:enquiry,dealerId,eventType:event,productId:customerJourneyProductId(product)})}catch(error){console.warn('TORVO DEALER JOURNEY EVENT NOT RECORDED',event,error);return false}};
const trackViewOnce=async(dealer,product,enquiryId)=>{const dealerId=dealerIdOf(dealer);if(!dealerId)return false;const key=[dealerId,customerJourneyProductId(product)||'',validId(enquiryId)||''].join(':');if(viewed.has(key))return true;const ok=await safeTrack({dealer,eventType:'DEALER_VIEW',product,enquiryId});if(ok)viewed.add(key);return ok};
export async function findCustomerDealers(pin){const p=String(pin||'').replace(/\D/g,'').slice(0,6);if(p.length!==6)throw new Error('6-DIGIT PIN CODE REQUIRED');const dealers=await findDealers(p,false);return dealers.filter(x=>x?.product_sales_available===true&&dealerIdOf(x)&&String(x?.match_type||'').toUpperCase()==='EXACT_PIN')}
export async function openCustomerDealerProfile(dealer,product=null,enquiryId=null){const dealerId=dealerIdOf(dealer);if(!dealerId)throw new Error('VERIFIED DEALER REQUIRED');const profile=await loadDealerProfile(dealerId);if(!dealerIdOf(profile)||profile?.product_sales_available!==true)throw new Error('VERIFIED DEALER PROFILE NOT AVAILABLE');await trackViewOnce(profile,product,enquiryId);return profile}
export async function selectCustomerDealer(dealer,product=null,enquiryId=null){if(dealer?.shop_name&&dealerIdOf(dealer)&&dealer?.product_sales_available===true){await trackViewOnce(dealer,product,enquiryId);return dealer}return openCustomerDealerProfile(dealer,product,enquiryId)}
export function recordCustomerDealerCall(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'CALL_CLICK',product,enquiryId})}
export function recordCustomerDealerWhatsApp(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'WHATSAPP_CLICK',product,enquiryId})}
export function recordCustomerDealerDirections(dealer,product=null,enquiryId=null){const map=String(dealer?.map_url||'').trim();if(!/^https:\/\//i.test(map))return Promise.resolve(false);return safeTrack({dealer,eventType:'MAP_OPEN',product,enquiryId})}
// REFERRAL_CREATED is written atomically by public_create_customer_referral with its canonical enquiry id.
export function recordCustomerDealerReferral(){return Promise.resolve(true)}
