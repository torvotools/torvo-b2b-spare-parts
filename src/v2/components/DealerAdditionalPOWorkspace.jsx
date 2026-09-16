import React,{useCallback,useEffect,useMemo,useState}from'react';
import{AlertCircle,FilePlus2,RefreshCw}from'lucide-react';
import{secureDealerLegacy as data}from'../services/dealerLegacyBridge';
import DealerDirectAdditionalPOModal from'./DealerDirectAdditionalPOModal';
const id=v=>String(v||'').trim();const U=v=>String(v||'').trim().toUpperCase();
const orderId=o=>id(o?.id||o?.order_id);const rootId=o=>id(o?.root_order_id||o?.parent_id);
export default function DealerAdditionalPOWorkspace(){
 const[docs,setDocs]=useState([]),[active,setActive]=useState(null),[busy,setBusy]=useState(false),[err,setErr]=useState(''),[ok,setOk]=useState('');
 const load=useCallback(async()=>{setBusy(true);setErr('');try{const rows=await data.dealerOrderHistory();setDocs(Array.isArray(rows)?rows:[])}catch(e){setErr(U(e?.message)||'ORDER HISTORY COULD NOT BE LOADED')}finally{setBusy(false)}},[]);
 useEffect(()=>{load()},[load]);
 const eligible=useMemo(()=>{const estimates=docs.filter(x=>String(x.doc_type||'').toLowerCase()==='estimate');return docs.filter(x=>String(x.doc_type||'').toLowerCase()==='sales_order').filter(o=>{const oid=orderId(o);if(!oid)return false;return estimates.some(e=>rootId(e)===oid||id(e?.parent_id)===oid||id(e?.root_order_id)===oid)})},[docs]);
 const created=async result=>{setActive(null);setOk(`ADDITIONAL PURCHASE ORDER CREATED${result?.order_id?` · ${result.order_id}`:''}.`);await load()};
 if(!busy&&!err&&!eligible.length)return null;
 return <><section className="panel approvedAddOnPanel"><header><div><span className="eyebrow">ESTIMATE CREATED</span><h3>ADD MORE ITEMS</h3><p>CREATE A SEPARATE LINKED PURCHASE ORDER ONLY FOR SALES ORDERS THAT ALREADY HAVE AN ESTIMATE.</p></div><button type="button" className="iconBtn" disabled={busy} onClick={load} aria-label="REFRESH ELIGIBLE ORDERS"><RefreshCw size={17}/></button></header>{err&&<div className="inlineError" role="alert"><AlertCircle size={16}/>{err}</div>}{ok&&<div className="inlineSuccess">{ok}</div>}{busy&&!docs.length?<div className="miniEmpty">CHECKING ELIGIBLE SALES ORDERS…</div>:<div className="requestList">{eligible.map(o=><article key={orderId(o)}><div><strong>SALES ORDER {o.order_number||o.document_number||orderId(o)}</strong><span>{U(o.status)||'ESTIMATE CREATED'}</span><small>ORIGINAL ORDER REMAINS UNCHANGED · NEW ITEMS WILL USE A LINKED ADDITIONAL PO</small></div><button type="button" className="primary" disabled={busy} onClick={()=>{setOk('');setActive(o)}}><FilePlus2 size={14}/>ADD MORE ITEMS</button></article>)}</div>}</section>{active&&<DealerDirectAdditionalPOModal order={active} onClose={()=>setActive(null)} onCreated={created}/>}</>;
}
