import{findDealers,loadDealerProfile,trackDealerReferralEvent}from'./publicWebsite';

const cleanId=v=>String(v||'').trim();
const productIdOf=product=>cleanId(product?.id)||null;
const dealerIdOf=dealer=>cleanId(dealer?.dealer_id)||null;
const safeTrack=async({dealer,eventType,product=null,enquiryId=null})=>{
 const dealerId=dealerIdOf(dealer);
 if(!dealerId)return false;
 try{return await trackDealerReferralEvent({enquiryId:cleanId(enquiryId)||null,dealerId,eventType,productId:productIdOf(product)})}catch(error){console.warn('TORVO DEALER JOURNEY EVENT NOT RECORDED',eventType,error);return false}
};

export async function findCustomerDealers(pin){return findDealers(pin,false)}

export async function openCustomerDealerProfile(dealer,product=null,enquiryId=null){
 const dealerId=dealerIdOf(dealer);
 if(!dealerId)throw new Error('DEALER REQUIRED');
 const profile=await loadDealerProfile(dealerId);
 if(!profile)throw new Error('VERIFIED DEALER PROFILE NOT AVAILABLE');
 await safeTrack({dealer:profile,eventType:'PROFILE_VIEW',product,enquiryId});
 return profile;
}

export async function selectCustomerDealer(dealer,product=null,enquiryId=null){
 await safeTrack({dealer,eventType:'DEALER_SELECTED',product,enquiryId});
 return dealer;
}

export function recordCustomerDealerCall(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'CALL_CLICK',product,enquiryId})}
export function recordCustomerDealerWhatsApp(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'WHATSAPP_CLICK',product,enquiryId})}
export function recordCustomerDealerDirections(dealer,product=null,enquiryId=null){return safeTrack({dealer,eventType:'DIRECTIONS_CLICK',product,enquiryId})}
