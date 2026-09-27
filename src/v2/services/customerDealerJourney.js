import{findDealers,loadDealerProfile}from'./publicWebsite';
const cleanId=v=>String(v||'').trim();
const UUID_RE=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const validId=v=>{const id=cleanId(v);return UUID_RE.test(id)?id:null};
export const customerJourneyProductId=product=>validId(product?.id||product?.product_id||product?.item_id);
const dealerIdOf=dealer=>validId(dealer?.dealer_id||dealer?.id);
export async function findCustomerDealers(pin){const p=String(pin||'').replace(/\D/g,'').slice(0,6);if(p.length!==6)throw new Error('6-DIGIT PIN CODE REQUIRED');const dealers=await findDealers(p,false);return dealers.filter(x=>x?.product_sales_available===true&&dealerIdOf(x)&&String(x?.match_type||'').toUpperCase()==='EXACT_PIN')}
export async function openCustomerDealerProfile(dealer,product=null,enquiryId=null){const dealerId=dealerIdOf(dealer);if(!dealerId)throw new Error('VERIFIED DEALER REQUIRED');const profile=await loadDealerProfile(dealerId);if(!dealerIdOf(profile)||profile?.product_sales_available!==true)throw new Error('VERIFIED DEALER PROFILE NOT AVAILABLE');return profile}
export async function selectCustomerDealer(dealer,product=null,enquiryId=null){if(dealer?.shop_name&&dealerIdOf(dealer)&&dealer?.product_sales_available===true){return dealer}return openCustomerDealerProfile(dealer,product,enquiryId)}
export function recordCustomerDealerCall(){return Promise.resolve(true)}
export function recordCustomerDealerWhatsApp(){return Promise.resolve(true)}
export function recordCustomerDealerDirections(dealer){return Promise.resolve(/^https:\/\//i.test(String(dealer?.map_url||'').trim()))}
export function recordCustomerDealerReferral(){return Promise.resolve(true)}
