import React,{useEffect,useState}from'react';
import{CheckCircle2,PlusCircle,RefreshCw}from'lucide-react';
import{data}from'../services/repository';
import DealerAddOnOrderModal from'./DealerAddOnOrderModal';

export default function DealerApprovedAddOnOrders({catalog=[],onOrderCreated}){
 const[requests,setRequests]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState('');
 const load=async()=>{setBusy(true);setErr('');try{setRequests(await data.dealerApprovedAddOnRequests())}catch(e){setErr(e.message)}finally{setBusy(false)}};
 useEffect(()=>{load()},[]);
 const created=async id=>{setActive(null);await load();onOrderCreated?.(id)};
 if(!busy&&!err&&!requests.length)return null;
 return <>
  <section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">APPROVED BY TORVO</span><h3>Additional Purchase Orders</h3><p>Approved Add More Items requests waiting for your item selection.</p></div><button className="iconBtn" disabled={busy} onClick={load}><RefreshCw size={17}/></button></header>
   {err&&<div className="inlineError">{err}</div>}
   {busy&&!requests.length?<div className="miniEmpty">Checking approved requests…</div>:<div className="requestList">{requests.map(r=><article key={r.id}><div><strong><CheckCircle2 size={14}/> ADD MORE ITEMS APPROVED</strong><span>{r.reason}</span><small>{new Date(r.reviewed_at||r.created_at).toLocaleDateString('en-GB')}{r.admin_note?` · TORVO: ${r.admin_note}`:''}</small></div><b className="status approved">APPROVED</b><button className="primary" onClick={()=>setActive(r)}><PlusCircle size={14}/>Create Additional Order</button></article>)}</div>}
  </section>
  {active&&<DealerAddOnOrderModal request={active} catalog={catalog} onClose={()=>setActive(null)} onCreated={created}/>} 
 </>;
}
