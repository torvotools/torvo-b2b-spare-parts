import React,{useCallback,useEffect,useMemo,useState}from'react';
import{AlertCircle,FilePlus2,RefreshCw}from'lucide-react';
import{secureDealerLegacy as data}from'../services/dealerLegacyBridge';
import DealerDirectAdditionalPOModal from'./DealerDirectAdditionalPOModal';
const id=v=>String(v||'').trim();const U=v=>String(v||'').trim().toUpperCase();const kind=v=>String(v||'').trim().toLowerCase();
const orderId=o=>id(o?.id||o?.order_id);const linkIds=o=>new Set([id(o?.id),id(o?.order_id),id(o?.root_order_id),id(o?.parent_id),id(o?.sales_order_id),id(o?.original_sales_order_id)].filter(Boolean));
const isBaseSalesOrder=o=>kind(o?.doc_type)==='sales_order'&&!id(o?.parent_id)&&!['additional_pending_approval','additional_approved','additional_rejected'].includes(kind(o?.status));
const estimateMatches=(estimate,order)=>{const oid=orderId(order);if(!oid)return false;const links=linkIds(estimate);return links.has(oid)||[...linkIds(order)].some(x=>x!==oid&&links.has(x))};
export default function DealerAdditionalPOWorkspace(){
 const[docs,setDocs]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState(''),[ok,setOk]=useState('');
 const load=useCallback(async()=>{setBusy(true);setErr('');try{const rows=await data.dealerOrderHistory();setDocs(Array.isArray(rows)?rows:[])}catch(e){setErr(U(e?.message)||'ORDER HISTORY COULD NOT BE LOADED')}finally{setBusy(false)}},[]);
 useEffect(()=>{load()},[load]);
 const eligible=useMemo(()=>{const estimates=docs.filter(x=>kind(x?.doc_type)==='estimate');const seen=new Set();return docs.filter(isBaseSalesOrder).filter(o=>estimates.some(e=>estimateMatches(e,o))).filter(o=>{const oid=orderId(o);if(!oid||seen.has(oid))return false;seen.add(oid);return true})},[docs]);
 const created=async result=>{setActive(null);setOk(`ADDITIONAL PURCHASE ORDER CREATED${result?.order_id?` · ${result.order_id}`:''}.`);await load()};
 if(!busy&&!err&&!eligible.length)return null;
 return <><section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">ESTIMATE CREATED</span><h3>ADD MORE ITEMS</h3><p>CREATE A SEPARATE LINKED PURCHASE ORDER ONLY FOR AN ORIGINAL SALES ORDER THAT ALREADY HAS AN ESTIMATE.</p></div><button type="button" className="iconBtn" disabled={busy} onClick={load} aria-label="REFRESH ELIGIBLE ORDERS"><RefreshCw size={17}/></button></header>{err&&<div className="inlineError" role="alert"><AlertCircle size={16}/>{err}</div>}{ok&&<div className="inlineSuccess">{ok}</div>}{busy&&!docs.length?<div className="miniEmpty">CHECKING ELIGIBLE SALES ORDERS…</div>:<div className="requestList">{eligible.map(o=><article key={orderId(o)}><div><strong>SALES ORDER {o.order_number||o.document_number||orderId(o)}</strong><span>ESTIMATE CREATED · {U(o.status)||'ORDER ACTIVE'}</span><small>ORIGINAL ORDER REMAINS UNCHANGED · NEW ITEMS WILL USE A SEPARATE LINKED ADDITIONAL PO</small></div><button type="button" className="primary" disabled={busy} onClick={()=>{setOk('');setActive(o)}}><FilePlus2 size={14}/>ADD MORE ITEMS</button></article>)}</div>}</section>{active&&<DealerDirectAdditionalPOModal order={active} onClose={()=>setActive(null)} onCreated={created}/>}</>;
}
