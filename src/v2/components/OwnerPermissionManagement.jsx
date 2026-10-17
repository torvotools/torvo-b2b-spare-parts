import React,{useEffect,useState} from 'react';
import {grantOwnerStaffPermission,listOwnerStaffPermissions,revokeOwnerStaffPermission} from '../services/ownerPermissions';

const PERMISSIONS=['catalog.view','catalog.create','catalog.edit','dealer.view','dealer.approve','inventory.view','inventory.manage','dispatch.manage','report.view','sales.manage','staff.manage','website.edit'];
export default function OwnerPermissionManagement({users=[]}){
 const [staffId,setStaffId]=useState(''),[permission,setPermission]=useState(PERMISSIONS[0]);
 const [reason,setReason]=useState(''),[expiry,setExpiry]=useState(''),[grants,setGrants]=useState([]);
 const [error,setError]=useState(''),[busy,setBusy]=useState(false),[loading,setLoading]=useState(false);
 const staff=users.filter(u=>['admin','salesman','accountant','store_keeper'].includes(u.role)&&u.active!==false);
 const refresh=async()=>{try{const result=await listOwnerStaffPermissions(staffId||null)||[];setGrants(result);setError('')}catch(e){setGrants([]);setError(e.message||'UNABLE TO LOAD PERMISSIONS')}};
 useEffect(()=>{let cancelled=false;setGrants([]);setError('');setLoading(true);listOwnerStaffPermissions(staffId||null).then(result=>{if(!cancelled){setGrants(result||[]);setLoading(false)}}).catch(e=>{if(!cancelled){setGrants([]);setError(e.message||'UNABLE TO LOAD PERMISSIONS');setLoading(false)}});return()=>{cancelled=true}},[staffId]);
 const currentGrant=grants.some(g=>g.permission_key===permission&&!g.revoked_at&&(!g.valid_until||new Date(g.valid_until)>new Date()));
 const grant=async e=>{e.preventDefault();if(!staffId||busy||loading||currentGrant)return;setBusy(true);try{await grantOwnerStaffPermission(staffId,permission,reason,expiry?new Date(expiry).toISOString():null);setReason('');setExpiry('');await refresh()}catch(e){setError(e.message)}finally{setBusy(false)}};
 const revoke=async id=>{const why=window.prompt('REASON FOR REVOKING PERMISSION');if(!why)return;setBusy(true);try{await revokeOwnerStaffPermission(id,why);await refresh()}catch(e){setError(e.message)}finally{setBusy(false)}};
 return <section className="panel workspace" aria-label="Owner permission management">
  <h3>OWNER — STAFF PERMISSION CONTROL</h3>
  <p>Only Owner can grant or revoke additional access. Staff roles and login rules remain unchanged.</p>
  <form onSubmit={grant}>
   <label>STAFF <select value={staffId} onChange={e=>setStaffId(e.target.value)} required><option value="">SELECT STAFF</option>{staff.map(u=><option key={u.id} value={u.id}>{u.full_name||u.id} — {u.role.toUpperCase()}</option>)}</select></label>
   <label>PERMISSION <select value={permission} onChange={e=>setPermission(e.target.value)}>{PERMISSIONS.map(p=><option key={p}>{p}</option>)}</select></label>
   <label>REASON <input value={reason} onChange={e=>setReason(e.target.value)} minLength={5} maxLength={500} required /></label>
   <label>EXPIRY (OPTIONAL) <input type="datetime-local" value={expiry} onChange={e=>setExpiry(e.target.value)} /></label>
   <button type="submit" disabled={busy||loading||!staffId||currentGrant}>{currentGrant?'ALREADY GRANTED — REVOKE FIRST':'GRANT PERMISSION'}</button>
  </form>
  {loading&&<p role="status">LOADING STAFF PERMISSIONS...</p>}
  {error&&<p role="alert">{error}</p>}
  <button type="button" onClick={refresh} disabled={busy}>REFRESH PERMISSIONS</button>
  <div>{grants.map(g=><div key={g.grant_id} className="panel"><strong>{g.permission_key}</strong> — {g.revoked_at?'REVOKED':g.valid_until&&new Date(g.valid_until)<=new Date()?'EXPIRED':g.valid_from&&new Date(g.valid_from)>new Date()?'SCHEDULED':'GRANTED'} {g.valid_until&&<small> UNTIL {new Date(g.valid_until).toLocaleString()}</small>} {!g.revoked_at&&<button type="button" disabled={busy} onClick={()=>revoke(g.grant_id)}>REVOKE</button>}</div>)}</div>
 </section>;
}
