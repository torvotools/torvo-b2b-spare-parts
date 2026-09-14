import{loadPublicManagedSettings}from'./adminManagedExperience';
const DEFAULT='7027751533';
const clean=v=>{let d=String(v||'').replace(/\D/g,'');if(d.length===10)d=`91${d}`;return d.length>=10&&d.length<=12?d:`91${DEFAULT}`};
export async function loadWhatsAppChannels(){const s=await loadPublicManagedSettings(),w=s.whatsapp_channels||{};return{customer:{number:clean(w.customer_number||DEFAULT),active:w.customer_active!==false},business:{number:clean(w.business_number||DEFAULT),active:w.business_active!==false}}}
export function whatsappUrl(number,message=''){return `https://wa.me/${clean(number)}${message?`?text=${encodeURIComponent(String(message))}`:''}`}
export async function openWhatsAppChannel(kind='business',message=''){const channels=await loadWhatsAppChannels(),channel=channels[kind];if(!channel?.active)throw new Error(`${String(kind).toUpperCase()} WHATSAPP IS CURRENTLY DISABLED`);const url=whatsappUrl(channel.number,message);window.open(url,'_blank','noopener,noreferrer');return url}
