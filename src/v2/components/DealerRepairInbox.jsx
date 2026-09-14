import React,{useCallback,useEffect,useState}from'react';
import{loadDealerRepairRequirements,updateDealerRepairRequirement}from'../services/dealerRepair';
import'../dealer-repair.css';

const text=v=>String(v??'').trim();
const upper=v=>text(v).toUpperCase();
const when=v=>{if(!v)return'—';const d=new Date(v);return Number.isNaN(d.getTime())?text(v):d.toLocaleString();};

export default function DealerRepairInbox(){
 const[items,setItems]=useState([]),[loading,setLoading]=useState(true),[busy,setBusy]=useState(''),[error,setError]=useState(''),[notice,setNotice]=useState('');
 const refresh=useCallback(async()=>{setLoading(true);setError('');try{setItems(await loadDealerRepairRequirements(null,100));}catch(e){setError(upper(e?.message||'REPAIR REQUESTS COULD NOT BE LOADED'));}finally{setLoading(false);}},[]);
 useEffect(()=>{refresh();},[refresh]);
 const change=async(id,status)=>{setBusy(id+status);setError('');setNotice('');try{await updateDealerRepairRequirement(id,status);setNotice(status==='accepted'?'REPAIR REQUEST ACCEPTED':'REPAIR REQUEST CLOSED');await refresh();}catch(e){setError(upper(e?.message||'REPAIR REQUEST UPDATE FAILED'));}finally{setBusy('');}};
 return <section className="dealer-repair" aria-labelledby="dealer-repair-title">
  <header className="dealer-repair__head"><div><h2 id="dealer-repair-title">REPAIR REQUESTS</h2><p>CUSTOMER REPAIR REQUIREMENTS ROUTED TO YOUR DEALERSHIP.</p></div><button type="button" onClick={refresh} disabled={loading||!!busy}>REFRESH</button></header>
  {error&&<div className="dealer-repair__msg dealer-repair__msg--error" role="alert">{error}</div>}
  {notice&&<div className="dealer-repair__msg" role="status">{notice}</div>}
  {loading?<div className="dealer-repair__empty">LOADING REPAIR REQUESTS…</div>:items.length===0?<div className="dealer-repair__empty">NO REPAIR REQUESTS ARE CURRENTLY ROUTED TO YOU.</div>:<div className="dealer-repair__list">{items.map((r,i)=>{
   const id=r.requirement_id||r.id;const status=upper(r.status||'ROUTED');const accepted=status==='ACCEPTED';const final=['CLOSED','CANCELLED'].includes(status);return <article className="dealer-repair__card" key={id||i}>
    <div className="dealer-repair__top"><strong>{upper(r.customer_name||r.name||'CUSTOMER')}</strong><span>{status}</span></div>
    <dl><div><dt>MOBILE</dt><dd>{text(r.customer_mobile||r.mobile)||'—'}</dd></div><div><dt>PIN CODE</dt><dd>{text(r.pin_code||r.customer_pin_code)||'—'}</dd></div><div><dt>BRAND</dt><dd>{upper(r.brand_name||r.brand)||'—'}</dd></div><div><dt>MODEL</dt><dd>{upper(r.machine_model||r.model)||'—'}</dd></div><div className="dealer-repair__problem"><dt>PROBLEM</dt><dd>{upper(r.problem_description||r.problem||r.requirement_text)||'—'}</dd></div><div><dt>REQUESTED</dt><dd>{when(r.created_at)}</dd></div></dl>
    {!final&&<div className="dealer-repair__actions">{!accepted&&<button type="button" onClick={()=>change(id,'accepted')} disabled={!id||!!busy}>{busy===id+'accepted'?'ACCEPTING…':'ACCEPT'}</button>}{accepted&&<button type="button" onClick={()=>change(id,'closed')} disabled={!id||!!busy}>{busy===id+'closed'?'CLOSING…':'CLOSE'}</button>}</div>}
   </article>;})}</div>}
 </section>;
}
