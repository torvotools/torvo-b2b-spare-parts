import{clients,cors,json,secureDevice,randomPassword,establishSession,fail}from'../_shared/torvo-auth.ts';

const otp=()=>{const b=new Uint32Array(1);crypto.getRandomValues(b);return String(b[0]%1_000_000).padStart(6,'0')};

async function sendOtp(email:string,code:string){
  const endpoint=Deno.env.get('TORVO_EMAIL_OTP_ENDPOINT');
  const token=Deno.env.get('TORVO_EMAIL_OTP_TOKEN');
  if(!endpoint||!token)throw new Error('EMAIL_PROVIDER_NOT_CONFIGURED');
  const r=await fetch(endpoint,{method:'POST',headers:{'content-type':'application/json','authorization':`Bearer ${token}`},body:JSON.stringify({to:email,template:'torvo_staff_login_otp',otp:code,expires_minutes:10})});
  if(!r.ok)throw new Error('EMAIL_DELIVERY_FAILED');
}

Deno.serve(async req=>{
  if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
  if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);
  try{
    const body=await req.json();
    const action=String(body.action??'');
    const email=String(body.email??'').trim().toLowerCase();
    const username=String(body.username??'').trim();
    const device=secureDevice(body.device_id);
    const{admin,publicClient}=clients();

    if(action==='begin'){
      const code=otp();
      const{data:challenge,error}=await admin.rpc('staff_email_otp_begin',{p_email:email,p_username:username,p_device_id:device,p_otp:code});
      if(error||!challenge)throw error??new Error('LOGIN_FAILED');
      try{await sendOtp(email,code)}catch(e){
        await admin.from('staff_email_otp_challenges').update({revoked_at:new Date().toISOString()}).eq('id',challenge);
        throw e;
      }
      return json({ok:true,challenge_id:challenge,expires_in_seconds:600,resend_after_seconds:45});
    }

    if(action==='verify'){
      const challenge=String(body.challenge_id??'').trim();
      const code=String(body.otp??'').trim();
      if(!/^[0-9]{6}$/.test(code))throw new Error('LOGIN_FAILED');
      const{data:appUserId,error:vErr}=await admin.rpc('staff_email_otp_verify',{p_challenge_id:challenge,p_email:email,p_username:username,p_device_id:device,p_otp:code});
      if(vErr||!appUserId)throw vErr??new Error('LOGIN_FAILED');
      const{data:appUser,error:uErr}=await admin.from('app_users').select('id,auth_user_id,role,active').eq('id',appUserId).eq('active',true).single();
      if(uErr||!['admin','accountant'].includes(appUser.role))throw uErr??new Error('STAFF_ACCESS_DENIED');
      const session=await establishSession(admin,publicClient,appUser,randomPassword());
      const{data:staffSessionId,error:sErr}=await admin.rpc('staff_create_verified_session',{p_auth_user_id:session.user.id,p_device_id:device,p_login_method:'email_otp'});
      if(sErr)throw sErr;
      return json({session,staff_session_id:staffSessionId,role:appUser.role});
    }

    return json({error:'METHOD_NOT_ALLOWED'},400);
  }catch(e){return fail(e)}
});
