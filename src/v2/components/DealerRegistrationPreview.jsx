import React,{useState}from'react';
import{ArrowRight,X}from'lucide-react';
import PublicDealerRegistrationForm from'./PublicDealerRegistrationForm';

export default function DealerRegistrationPreview(){
 const[open,setOpen]=useState(true);
 return <main className="registrationPreview"><section className="registrationBackdrop"><div><div className="mark">T</div><h1>BECOME A TORVO DEALER</h1><p>REGISTER YOUR BUSINESS FOR TORVO VERIFICATION. APPROVAL IS MANUAL AND DEALER LOGIN ACTIVATES ONLY AFTER APPROVAL.</p><button className="primary" type="button" onClick={()=>setOpen(true)}>REGISTER AS DEALER <ArrowRight size={16}/></button></div></section>{open&&<div className="modalLayer"><section className="dealerRegModal" role="dialog" aria-modal="true" aria-label="NEW DEALER REGISTRATION"><header><div><span className="eyebrow">NEW DEALER REGISTRATION</span><h2>BECOME A TORVO DEALER</h2><p>USE YOUR ACTIVE CALL + WHATSAPP NUMBER AND AUTHORITATIVE LOCATION DETAILS.</p></div><button className="iconBtn" type="button" onClick={()=>setOpen(false)} aria-label="CLOSE REGISTRATION"><X size={19}/></button></header><PublicDealerRegistrationForm source="WEBSITE"/><footer><button className="secondary" type="button" onClick={()=>setOpen(false)}>CLOSE</button></footer></section></div>}</main>}
