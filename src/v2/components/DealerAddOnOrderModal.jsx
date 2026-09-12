import React,{useMemo,useState}from'react';
import{CheckCircle2,PlusCircle,Search,ShoppingCart,X}from'lucide-react';
import{data}from'../services/repository';

const money=n=>`₹${Number(n||0).toLocaleString('en-IN',{maximumFractionDigits:2})}`;
const norm=v=>String(v||'').trim().toLowerCase();

export default function DealerAddOnOrderModal({request,catalog=[],onClose,onCreated}){
 const[search,setSearch]=useState('');
 const[cart,setCart]=useState({});
 const[rates,setRates]=useState({});
 const[busy,setBusy]=useState(false);
 const[err,setErr]=useState('');
 const terms=useMemo(()=>norm(search).split(/\s+/).filter(Boolean),[search]);
 const items=useMemo(()=>catalog.filter(x=>x.active!==false&&terms.every(t=>norm(`${x.item_code} ${x.oem_code||''} ${x.name||''} ${x.brand||''} ${x.category||''} ${x.model||''}`).includes(t))).slice(0,80),[catalog,terms]);
 const selected=useMemo(()=>catalog.filter(x=>Number(cart[x.id])>0),[catalog,cart]);
 const total=selected.reduce((n,x)=>n+Number(rates[x.id]?.amount||0),0);
 const bad=selected.some(x=>!rates[x.id]?.rate);
 const changeQty=async(id,value)=>{
  const qty=value===''?'':Math.max(0,Math.floor(Number(value)||0));
  setCart(v=>({...v,[id]:qty}));
  if(!qty){setRates(v=>{const n={...v};delete n[id];return n});return}
  try{const rate=await data.dealerItemRate(id,qty);setRates(v=>({...v,[id]:rate}))}
  catch(e){setRates(v=>({...v,[id]:{error:e.message}}))}
 };
 const create=async()=>{
  if(busy||!request||!selected.length||bad)return;
  if(!confirm(`Create Additional Purchase Order for ${money(total)}?`))return;
  setBusy(true);setErr('');
  try{
   const id=await data.dealerCreateAddOnOrder(request.id,selected.map(x=>({item_id:x.id,qty:Number(cart[x.id])})));
   onCreated?.(id);
  }catch(e){setErr(e.message)}finally{setBusy(false)}
 };
 return <div className="modalLayer"><section className="dealerActionModal addOnOrderModal">
  <header><div><span className="eyebrow">TORVO APPROVED · ADD MORE ITEMS</span><h3>Create Additional Purchase Order</h3><p>This creates a new linked order. Your original Purchase Order / Estimate remains unchanged.</p></div><button className="iconBtn" disabled={busy} onClick={onClose}><X/></button></header>
  {err&&<div className="inlineError">{err}</div>}
  <div className="addOnApproval"><CheckCircle2/><div><b>APPROVAL ACTIVE</b><span>{request.admin_note||'TORVO has approved your Add More Items request.'}</span></div></div>
  <label className="addOnSearch"><Search size={17}/><input autoFocus value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search item code, OEM, product, brand or model"/></label>
  <div className="addOnCatalog">{items.length===0?<div className="miniEmpty">No matching product.</div>:items.map(x=>{const r=rates[x.id];return <article key={x.id}><div><b>{x.item_code}</b><strong>{x.name}</strong><small>{[x.oem_code&&`OEM ${x.oem_code}`,x.brand,x.category,x.model].filter(Boolean).join(' · ')}</small>{r?.rate&&<span className="dealerRate">Your Rate: <strong>{money(r.rate)}</strong> · Amount: <strong>{money(r.amount)}</strong></span>}{r?.error&&<span className="dealerRate error">{r.error}</span>}</div><input type="number" min="0" step="1" value={cart[x.id]||''} onChange={e=>changeQty(x.id,e.target.value)} placeholder="Qty"/></article>})}</div>
  {selected.length>0&&<div className="poSummary"><div><strong>{selected.length} item{selected.length===1?'':'s'} selected</strong><span>Additional Purchase Order Total</span></div><b>{money(total)}</b></div>}
  <div className="modalNotice"><strong>Rate security:</strong> displayed rates are only a preview. On final submit, TORVO recalculates every rate on the server from your current Dealer Rate Group and quantity. Existing order totals are never overwritten.</div>
  <footer><button className="secondary" disabled={busy} onClick={onClose}>CANCEL</button><button className="primary" disabled={busy||!selected.length||bad} onClick={create}><ShoppingCart/>{busy?'CREATING…':'CREATE ADDITIONAL ORDER'}</button></footer>
 </section></div>;
}
