import React,{useCallback,useEffect,useState}from'react';
import{AlertCircle,CheckCircle2,PlusCircle,RefreshCw}from'lucide-react';
import{secureDealerLegacy as data}from'../services/dealerLegacyBridge';
import DealerAddOnOrderModal from'./DealerAddOnOrderModal';
const U=v=>String(v||'').trim().toUpperCase();
const when=v=>{if(!v)return'';const d=new Date(v);return Number.isNaN(d.getTime())?'':d.toLocaleDateString('en-GB')};
export default function DealerApprovedAddOnOrders({onOrderCreated}){
 const[requests,setRequests]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState('');
 const load=useCallback(async()=>{if(busy)return;setBusy(true);setErr('');try{const rows=await data.dealerApprovedAddOnRequests();setRequests(Array.isArray(rows)?rows:[])}catch(e){setErr(U(e?.message)||'APPROVED REQUESTS COULD NOT BE LOADED')}finally{setBusy(false)}},[busy]);
 useEffect(()=>{let live=true;(async()=>{setBusy(true);setErr('');try{const rows=await data.dealerApprovedAddOnRequests();if(live)setRequests(Array.isArray(rows)?rows:[])}catch(e){if(live)setErr(U(e?.message)||'APPROVED REQUESTS COULD NOT BE LOADED')}finally{if(live)setBusy(false)}})();return()=>{live=false}},[]);
 const created=async orderId=>{setActive(null);setBusy(true);setErr('');try{const rows=await data.dealerApprovedAddOnRequests();setRequests(Array.isArray(rows)?rows:[]);onOrderCreated?.(orderId)}catch(e){setErr(U(e?.message)||'ORDER CREATED, BUT APPROVAL LIST COULD NOT BE REFRESHED')}finally{setBusy(false)}};
 if(!busy&&!err&&!requests.length)return null;
 return <><section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">APPROVED BY TORVO</span><h3>ADDITIONAL PURCHASE ORDERS</h3><p>APPROVED ADD MORE ITEMS REQUESTS WAITING FOR YOUR ITEM SELECTION.</p></div><button type="button" className="iconBtn" disabled={busy} onClick={load} title="REFRESH APPROVALS" aria-label="REFRESH APPROVED ADDITIONAL ORDERS"><RefreshCw size={17}/></button></header>{err&&<div className="inlineError" role="alert"><AlertCircle size={16}/>{err}</div>}{busy&&!requests.length?<div className="miniEmpty">CHECKING APPROVED REQUESTS…</div>:<div className="requestList">{requests.map(r=><article key={r.id||r.request_id}><div><strong><CheckCircle2 size={14}/> ADD MORE ITEMS APPROVED</strong><span>{U(r.reason)||'ADDITIONAL ITEMS APPROVED'}</span><small>{when(r.reviewed_at||r.created_at)}{r.admin_note?` · TORVO: ${U(r.admin_note)}`:''}</small></div><b className="status approved">APPROVED</b><button type="button" className="primary" disabled={busy} onClick={()=>setActive(r)}><PlusCircle size={14}/>CREATE ADDITIONAL ORDER</button></article>)}</div>}</section>{active&&<DealerAddOnOrderModal request={active} onClose={()=>setActive(null)} onCreated={created}/>}</>;
}
