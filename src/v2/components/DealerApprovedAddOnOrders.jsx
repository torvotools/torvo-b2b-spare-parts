import React,{useEffect,useState}from'react';
import{AlertCircle,CheckCircle2,PlusCircle,RefreshCw}from'lucide-react';
import{data}from'../services/repository';
import DealerAddOnOrderModal from'./DealerAddOnOrderModal';
const U=v=>String(v||'').toUpperCase();
export default function DealerApprovedAddOnOrders({onOrderCreated}){
 const[requests,setRequests]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState('');
 const load=async()=>{setBusy(true);setErr('');try{setRequests(await data.dealerApprovedAddOnRequests())}catch(e){setErr(U(e.message))}finally{setBusy(false)}};
 useEffect(()=>{load()},[]);
 const created=async id=>{setActive(null);await load();onOrderCreated?.(id)};
 if(!busy&&!err&&!requests.length)return null;
 return <>
  <section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">APPROVED BY TORVO</span><h3>ADDITIONAL PURCHASE ORDERS</h3><p>APPROVED ADD MORE ITEMS REQUESTS WAITING FOR YOUR ITEM SELECTION.</p></div><button className="iconBtn" disabled={busy} onClick={load} title="REFRESH APPROVALS"><RefreshCw size={17}/></button></header>
   {err&&<div className="inlineError"><AlertCircle size={16}/>{err}</div>}
   {busy&&!requests.length?<div className="miniEmpty">CHECKING APPROVED REQUESTS…</div>:<div className="requestList">{requests.map(r=><article key={r.id}><div><strong><CheckCircle2 size={14}/> ADD MORE ITEMS APPROVED</strong><span>{U(r.reason)}</span><small>{new Date(r.reviewed_at||r.created_at).toLocaleDateString('en-GB')}{r.admin_note?` · TORVO: ${U(r.admin_note)}`:''}</small></div><b className="status approved">APPROVED</b><button className="primary" onClick={()=>setActive(r)}><PlusCircle size={14}/>CREATE ADDITIONAL ORDER</button></article>)}</div>}
  </section>
  {active&&<DealerAddOnOrderModal request={active} onClose={()=>setActive(null)} onCreated={created}/>} 
 </>;
}
