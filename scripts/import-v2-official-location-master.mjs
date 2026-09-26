#!/usr/bin/env node
/**
 * TORVO V2 official India location importer.
 * Input is trusted Government of India LGD/OGD CSV exports only.
 * Dry-run is the default. --apply requires the TORVO V2 STAGING project ref.
 * Public OTHER city/town text is never imported by this script.
 */
import fs from 'node:fs/promises';

const STAGING_REF='jvmhhngjlaqrfopfavur';
const APPLY=process.argv.includes('--apply');
const arg=n=>{const i=process.argv.indexOf(n);return i>=0?process.argv[i+1]:''};
const files={states:arg('--states'),districts:arg('--districts'),localBodies:arg('--local-bodies')};
for(const [k,v] of Object.entries(files))if(!v)throw new Error(`MISSING --${k.replace(/[A-Z]/g,m=>'-'+m.toLowerCase())} CSV`);

const clean=v=>String(v??'').replace(/^\uFEFF/,'').trim();
const key=v=>clean(v).toLowerCase().replace(/[^a-z0-9]/g,'');
const parseCsv=s=>{const rows=[];let row=[],cell='',q=false;for(let i=0;i<s.length;i++){const c=s[i],n=s[i+1];if(c==='"'&&q&&n==='"'){cell+='"';i++;}else if(c==='"')q=!q;else if(c===','&&!q){row.push(cell);cell='';}else if((c==='\n'||c==='\r')&&!q){if(c==='\r'&&n==='\n')i++;row.push(cell);if(row.some(x=>clean(x)))rows.push(row);row=[];cell='';}else cell+=c;}if(cell||row.length){row.push(cell);rows.push(row)}return rows};
const load=async path=>{const rows=parseCsv(await fs.readFile(path,'utf8'));const headers=rows.shift().map(key);return rows.map(r=>Object.fromEntries(headers.map((h,i)=>[h,clean(r[i])])));};
const pick=(r,names)=>{for(const n of names){const v=r[key(n)];if(v)return v}return''};
const digits=v=>clean(v).replace(/\D/g,'');
const statesRaw=await load(files.states),districtsRaw=await load(files.districts),bodiesRaw=await load(files.localBodies);

const states=statesRaw.map(r=>({lgd_code:digits(pick(r,['State Code','State LGD Code','StateCode'])),name:pick(r,['State Name (In English)','State Name','StateName'])})).filter(x=>x.lgd_code&&x.name);
const stateCodes=new Set(states.map(x=>x.lgd_code));
const districts=districtsRaw.map(r=>({lgd_code:digits(pick(r,['District Code','District LGD Code','DistrictCode'])),state_lgd_code:digits(pick(r,['State Code','State LGD Code','StateCode'])),name:pick(r,['District Name (In English)','District Name','DistrictName'])})).filter(x=>x.lgd_code&&x.state_lgd_code&&x.name);
const districtCodes=new Set(districts.map(x=>x.lgd_code));
const urbanType=r=>pick(r,['Local Body Type Name','Localbody Type Name','Local Body Type','Localbody Type','LocalBodyType','Local Body Type Code','Localbody Type Code']);
const urbanPattern=/municipal|municipality|corporation|nagar\s*panchayat|town\s*panchayat|notified\s*area|cantonment|urban/i;
const ruralPattern=/gram\s*panchayat|village\s*panchayat|janpad|panchayat\s*samiti|zilla|zila|district\s*panchayat|block\s*panchayat|intermediate\s*panchayat/i;
const typedBodies=bodiesRaw.map(r=>({row:r,type:urbanType(r)}));
if(!typedBodies.some(x=>x.type))throw new Error('LOCAL BODY TYPE COLUMN REQUIRED: REFUSING TO MAP ALL LOCAL BODIES AS CITIES');
const unknownTypes=[...new Set(typedBodies.map(x=>x.type).filter(Boolean).filter(t=>!urbanPattern.test(t)&&!ruralPattern.test(t)))];
if(unknownTypes.length)throw new Error('UNKNOWN LOCAL BODY TYPES: '+unknownTypes.slice(0,20).join(', '));
const cities=typedBodies.filter(x=>urbanPattern.test(x.type)&&!ruralPattern.test(x.type)).map(({row:r,type})=>({lgd_code:digits(pick(r,['Localbody Code','Local Body Code','LocalBodyCode','LGD Code'])),district_lgd_code:digits(pick(r,['District Code','District LGD Code','DistrictCode'])),name:pick(r,['Localbody Name (In English)','Local Body Name (In English)','Local Body Name','LocalBodyName']),local_body_type:type})).filter(x=>x.lgd_code&&x.district_lgd_code&&x.name);

const uniq=(a,f)=>{const m=new Map();for(const x of a){const k=f(x);if(m.has(k))throw new Error('DUPLICATE OFFICIAL CODE '+k);m.set(k,x)}return [...m.values()]};
const S=uniq(states,x=>x.lgd_code),D=uniq(districts,x=>x.lgd_code),C=uniq(cities,x=>x.lgd_code);
const badD=D.filter(x=>!stateCodes.has(x.state_lgd_code));
const badC=C.filter(x=>!districtCodes.has(x.district_lgd_code));
if(!S.length||!D.length||!C.length)throw new Error('OFFICIAL DATASET EMPTY OR HEADERS NOT RECOGNIZED');
if(badD.length||badC.length)throw new Error(`RELATIONSHIP VALIDATION FAILED districts=${badD.length} cities=${badC.length}`);

console.log(JSON.stringify({mode:APPLY?'APPLY':'DRY_RUN',states:S.length,districts:D.length,urban_local_bodies:C.length,rejected_rural_local_bodies:typedBodies.filter(x=>ruralPattern.test(x.type)).length,source:'GOVERNMENT_OF_INDIA_LGD_OGD'},null,2));
if(!APPLY)process.exit(0);

const url=clean(process.env.SUPABASE_URL),token=clean(process.env.SUPABASE_SERVICE_ROLE_KEY);
if(!url||!token)throw new Error('SUPABASE_URL AND SUPABASE_SERVICE_ROLE_KEY REQUIRED FOR --apply');
const ref=new URL(url).hostname.split('.')[0];
if(ref!==STAGING_REF)throw new Error(`REFUSING NON-STAGING TARGET: ${ref}`);
const headers={apikey:token,Authorization:`Bearer ${token}`,'Content-Type':'application/json',Prefer:'resolution=merge-duplicates,return=minimal'};
const rest=async(path,body)=>{const r=await fetch(`${url}/rest/v1/${path}`,{method:'POST',headers,body:JSON.stringify(body)});if(!r.ok)throw new Error(`${path}: ${r.status} ${await r.text()}`)};
const chunks=(a,n=250)=>Array.from({length:Math.ceil(a.length/n)},(_,i)=>a.slice(i*n,i*n+n));
for(const batch of chunks(S))await rest('location_states?on_conflict=lgd_code',batch.map((x,i)=>({lgd_code:x.lgd_code,name:x.name.toUpperCase(),active:true,sort_order:i})));
const stateRows=await (await fetch(`${url}/rest/v1/location_states?select=id,lgd_code`,{headers:{apikey:token,Authorization:`Bearer ${token}`}})).json();
const stateId=new Map(stateRows.map(x=>[x.lgd_code,x.id]));
for(const batch of chunks(D))await rest('location_districts?on_conflict=lgd_code',batch.map((x,i)=>({lgd_code:x.lgd_code,state_id:stateId.get(x.state_lgd_code),name:x.name.toUpperCase(),active:true,sort_order:i})));
const districtRows=await (await fetch(`${url}/rest/v1/location_districts?select=id,lgd_code`,{headers:{apikey:token,Authorization:`Bearer ${token}`}})).json();
const districtId=new Map(districtRows.map(x=>[x.lgd_code,x.id]));
const today=new Date().toISOString().slice(0,10);
for(const batch of chunks(C))await rest('location_cities?on_conflict=lgd_code',batch.map((x,i)=>({lgd_code:x.lgd_code,district_id:districtId.get(x.district_lgd_code),name:x.name.toUpperCase(),pincode:null,source_kind:'LGD_LOCAL_BODY',source_updated_on:today,active:true,sort_order:i})));
console.log('TORVO V2 STAGING OFFICIAL LOCATION IMPORT COMPLETE');
