import{clients,cors,json,secureDevice}from'../_shared/torvo-auth.ts';
const bucket='torvo-service-book-media',ttl=120;
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);try{
 const auth=req.headers.get('authorization')??'';if(!auth.toLowerCase().startsWith('bearer '))return json({error:'AUTH_REQUIRED'},401);
 const body=await req.json(),device=secureDevice(body.device_id),token=String(body.session_token??''),job=String(body.job_id??'').trim();if(!token||!job)return json({error:'ACTIVE_DEALER_SESSION_AND_JOB_REQUIRED'},400);
 const{admin}=clients(),jwt=auth.slice(7),{data:userData,error:userError}=await admin.auth.getUser(jwt);if(userError||!userData.user)return json({error:'AUTH_REQUIRED'},401);
 const{data:app,error:appErr}=await admin.from('app_users').select('role,active,dealer_id').eq('auth_user_id',userData.user.id).eq('active',true).single();if(appErr||app?.role!=='dealer'||!app?.dealer_id)return json({error:'ACCESS_DENIED'},403);
 const{data:valid,error:vErr}=await admin.rpc('dealer_validate_device_session',{p_dealer_id:app.dealer_id,p_device_id:device,p_session_token:token});if(vErr||valid!==true)return json({error:'ACTIVE_DEALER_DEVICE_SESSION_REQUIRED'},401);
 const{data:jobs,error:jErr}=await admin.rpc('dealer_service_jobs_read',{p_device_id:device,p_session_token:token,p_status:null,p_limit:300});if(jErr)return json({error:'ACCESS_DENIED'},403);const row=(Array.isArray(jobs)?jobs:[]).find((x:any)=>x.id===job);if(!row?.machine_photo_url)return json({error:'PHOTO_NOT_AVAILABLE'},404);
 const path=String(row.machine_photo_url);if(!path.startsWith(app.dealer_id+'/'))return json({error:'ACCESS_DENIED'},403);
 const{data:signed,error:signErr}=await admin.storage.from(bucket).createSignedUrl(path,ttl);if(signErr||!signed?.signedUrl)return json({error:'PHOTO_NOT_AVAILABLE'},404);return json({ok:true,url:signed.signedUrl,expires_in:ttl});
 }catch(e){console.error(e);return json({error:'SERVICE_BOOK_PHOTO_READ_FAILED'},400)}});
