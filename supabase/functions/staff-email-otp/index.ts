import{createClient}from'https://esm.sh/@supabase/supabase-js@2.57.0';
import{establishSession,secureDevice}from'../_shared/torvo-auth.ts';
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,x-client-info,apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS'};
const json=(b:unknown,s=200)=>new Response(JSON.stringify(b),{status:s,headers:{...cors,'content-type':'application/json'}});
const hash=async(s:string)=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))).map(b=>b.toString(16).padStart(2,'0')).join('');
const otp=()=>{const b=new Uint32Array(1);crypto.getRandomValues(b);return String(b[0]%1e6).padStart(6,'0')};
async function mail(email:string,code:string,m:{role:string;username:string;name:string}){
 const token=Deno.env.get('TORVO_EMAIL_OTP_TOKEN');if(!token)throw Error('EMAIL_PROVIDER_NOT_CONFIGURED');
 const h={'authorization':`Bearer ${token}`,'content-type':'application/json','accept':'application/json'};
 const me=await fetch('https://api.mail.hostinger.com/api/v1/me',{headers:h});if(!me.ok)throw Error('EMAIL_DELIVERY_FAILED');
 const j=await me.json(),box=j?.data?.mailboxes?.find((x:any)=>String(x?.address||'').toLowerCase()==='otp@torvotools.com');if(!box?.resourceId)throw Error('EMAIL_SENDER_NOT_FOUND');
 const role=m.role.toUpperCase(),subject=`TORVO OTP - ${role} ${m.username} Login Code`;
 const text=`TORVO OTP FOR ${m.username} (${role})\n\nUser ID: ${m.username}\nRole: ${role}\nEmployee: ${m.name}\n\nYour 6-digit verification code is: ${code}\n\nLogin: TORVO Staff Sign-in\n\nThis code expires in 10 minutes. Do not share this code with anyone.\n\nDO NOT REPLY - this mailbox is not monitored.`;
 const html=`<div style="font-family:Arial,sans-serif;max-width:520px"><h2>TORVO OTP</h2><p style="font-size:18px"><b>${m.username}</b> &nbsp;|&nbsp; ${role} &nbsp;|&nbsp; ${m.name}</p><p>Your 6-digit verification code is:</p><p style="font-size:32px;letter-spacing:6px;font-weight:700">${code}</p><p><b>Login:</b> TORVO Staff Sign-in</p><p>This code expires in <b>10 minutes</b>. Do not share this code with anyone.</p><hr><p style="font-size:12px">DO NOT REPLY - this mailbox is not monitored.</p></div>`;
 const r=await fetch(`https://api.mail.hostinger.com/api/v1/mailboxes/${encodeURIComponent(box.resourceId)}/send`,{method:'POST',headers:h,body:JSON.stringify({to:[email],displayName:'TORVO OTP',subject,text,html})});if(r.status!==204)throw Error('EMAIL_DELIVERY_FAILED');
}
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);
 try{
  const url=Deno.env.get('SUPABASE_URL'),service=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),anon=Deno.env.get('SUPABASE_ANON_KEY');if(!url||!service||!anon)throw Error('SERVER_AUTH_NOT_CONFIGURED');
  const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}}),pub=createClient(url,anon,{auth:{persistSession:false,autoRefreshToken:false}});
  const body=await req.json(),action=String(body.action??'begin'),username=String(body.username??'').trim().toUpperCase(),device=secureDevice(body.device_id),deviceType=String(body.device_type??'desktop').toLowerCase();if(!/^[A-Z]{2,8}@[0-9]{2,6}$/.test(username))throw Error('LOGIN_FAILED');
  const{data:id,error:iErr}=await admin.from('staff_access_identities').select('app_user_id,username,employee_name,staff_role,active').eq('username',username).eq('active',true).maybeSingle();if(iErr||!id)throw iErr??Error('LOGIN_FAILED');
  const role=String(id.staff_role??'').trim().toLowerCase();if(!['owner','admin','accountant','salesman','store_keeper'].includes(role))throw Error('LOGIN_FAILED');if(role==='accountant'&&deviceType!=='desktop')return json({error:'DEVICE_NOT_ALLOWED'},403);
  const{data:app,error:aErr}=await admin.from('app_users').select('id,auth_user_id,role,active').eq('id',id.app_user_id).eq('active',true).maybeSingle();if(aErr||!app||String(app.role??'').trim().toLowerCase()!==role||!app.auth_user_id)throw aErr??Error('LOGIN_FAILED');
  const{data:set,error:sErr}=await admin.from('staff_otp_settings').select('master_email').eq('singleton',true).maybeSingle();const email=String(set?.master_email??'').trim().toLowerCase();if(sErr||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw sErr??Error('LOGIN_FAILED');
  if(action==='begin'){
   const{data:wait}=await admin.from('staff_email_otp_challenges').select('id,resend_after').eq('app_user_id',app.id).eq('device_id',device).is('revoked_at',null).is('consumed_at',null).gt('resend_after',new Date().toISOString()).limit(1);if(wait?.length)return json({error:'RESEND_WAIT_REQUIRED'},429);
   await admin.from('staff_email_otp_challenges').update({revoked_at:new Date().toISOString()}).eq('app_user_id',app.id).is('consumed_at',null).is('revoked_at',null);
   const code=otp(),cid=crypto.randomUUID(),now=Date.now();const{error:cErr}=await admin.from('staff_email_otp_challenges').insert({id:cid,app_user_id:app.id,email_normalized:email,otp_hash:await hash(code),device_id:device,expires_at:new Date(now+600000).toISOString(),resend_after:new Date(now+45000).toISOString()});if(cErr)throw cErr;
   try{await mail(email,code,{role,username:id.username,name:id.employee_name})}catch(e){await admin.from('staff_email_otp_challenges').update({revoked_at:new Date().toISOString()}).eq('id',cid);throw e}
   return json({ok:true,challenge_id:cid,expires_in_seconds:600,resend_after_seconds:45});
  }
  if(action==='verify'){
   const cid=String(body.challenge_id??''),code=String(body.otp??'');if(!/^[0-9]{6}$/.test(code))throw Error('LOGIN_FAILED');
   const{data:c,error:cErr}=await admin.from('staff_email_otp_challenges').select('*').eq('id',cid).eq('app_user_id',app.id).eq('device_id',device).maybeSingle();if(cErr||!c||c.consumed_at||c.revoked_at||new Date(c.expires_at).getTime()<=Date.now()||c.failed_attempts>=5||c.email_normalized!==email)throw cErr??Error('LOGIN_FAILED');
   if(c.otp_hash!==await hash(code)){const n=Math.min(5,(c.failed_attempts??0)+1);await admin.from('staff_email_otp_challenges').update({failed_attempts:n,revoked_at:n>=5?new Date().toISOString():null}).eq('id',cid);throw Error('LOGIN_FAILED')}
   const{data:used,error:uErr}=await admin.from('staff_email_otp_challenges').update({consumed_at:new Date().toISOString()}).eq('id',cid).is('consumed_at',null).is('revoked_at',null).select('id').maybeSingle();if(uErr||!used)throw uErr??Error('LOGIN_FAILED');
   const password=crypto.randomUUID()+'-Aa1!';const session=await establishSession(admin,pub,app,password);
   await admin.from('staff_auth_sessions').update({revoked_at:new Date().toISOString(),revoked_by:app.id}).eq('app_user_id',app.id).is('revoked_at',null);
   const{data:ss,error:ssErr}=await admin.from('staff_auth_sessions').insert({app_user_id:app.id,auth_user_id:app.auth_user_id,login_method:'email_otp',device_id:device,expires_at:new Date(Date.now()+30*86400000).toISOString()}).select('id').single();if(ssErr)throw ssErr;
   return json({ok:true,session,staff_session_id:ss.id,role,username:id.username});
  }
  return json({error:'METHOD_NOT_ALLOWED'},400);
 }catch(e){console.error(e);return json({error:'LOGIN_FAILED'},400)}
});