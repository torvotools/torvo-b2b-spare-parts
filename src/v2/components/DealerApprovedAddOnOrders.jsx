import React,{useEffect,useState}from'react';
import{AlertCircle,CheckCircle2,PlusCircle,RefreshCw}from'lucide-react';
import{data}from'../services/repository';
import DealerAddOnOrderModal from'./DealerAddOnOrderModal';

export default function DealerApprovedAddOnOrders({catalog=[],catalogLoading=false,catalogError='',onRetryCatalog,onOrderCreated}){
 const[requests,setRequests]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState('');
 const load=async()=>{setBusy(true);setErr('');try{setRequests(await data.dealerApprovedAddOnRequests())}catch(e){setErr(e.message)}finally{setBusy(false)}};
 useEffect(()=>{load()},[]);
 const created=async id=>{setActive(null);await load();onOrderCreated?.(id)};
 if(!busy&&!err&&!requests.length)return null;
 const catalogReady=!catalogLoading&&!catalogError&&catalog.length>0;
 return <>
  <section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">APPROVED BY TORVO</span><h3>Additional Purchase Orders</h3><p>Approved Add More Items requests waiting for your item selection.</p></div><button className="iconBtn" disabled={busy} onClick={load} title="Refresh approvals"><RefreshCw size={17}/></button></header>
   {err&&<div className="inlineError"><AlertCircle size={16}/>{err}</div>}
   {catalogError&&requests.length>0&&<div className="inlineError"><AlertCircle size={16}/><span>Product catalog is temporarily unavailable. Your approval is safe.</span>{onRetryCatalog&&<button className="secondary" onClick={onRetryCatalog}><RefreshCw size={14}/>Retry Catalog</button>}</div>}
   {busy&&!requests.length?<div className="miniEmpty">Checking approved requests…</div>:<div className="requestList">{requests.map(r=><article key={r.id}><div><strong><CheckCircle2 size={14}/> ADD MORE ITEMS APPROVED</strong><span>{r.reason}</span><small>{new Date(r.reviewed_at||r.created_at).toLocaleDateString('en-GB')}{r.admin_note?` · TORVO: ${r.admin_note}`:''}</small></div><b className="status approved">APPROVED</b><button className="primary" disabled={!catalogReady} title={catalogLoading?'Loading catalog…':catalogError?'Retry catalog first':!catalog.length?'No active catalog items available':'Create Additional Purchase Order'} onClick={()=>setActive(r)}><PlusCircle size={14}/>{catalogLoading?'Loading Products…':'Create Additional Order'}</button></article>)}</div>}
  </section>
  {active&&catalogReady&&<DealerAddOnOrderModal request={active} catalog={catalog} onClose={()=>setActive(null)} onCreated={created}/>} 
 </>;
}
