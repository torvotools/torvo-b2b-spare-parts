import{createClient}from'npm:@supabase/supabase-js@2';import{clients,cors,json,secureDevice}from'../_shared/torvo-auth.ts';
const bucket='torvo-service-book-media';
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);try{
 const auth=req.headers.get('authorization')??'';if(!auth.toLowerCase().startsWith('bearer '))return json({error:'AUTH_REQUIRED'},401);
 const body=await req.json(),device=secureDevice(body.device_id),token=String(body.session_token??''),path=String(body.storage_path??'').trim();
 if(!token||!path)return json({error:'ACTIVE_DEALER_SESSION_AND_PATH_REQUIRED'},400);
 const{admin}=clients(),jwt=auth.slice(7),{data:userData,error:userError}=await admin.auth.getUser(jwt);if(userError||!userData.user)return json({error:'AUTH_REQUIRED'},401);
 const userClient=createClient(Deno.env.get('SUPABASE_URL')??'',Deno.env.get('SUPABASE_ANON_KEY')??'',{global:{headers:{Authorization:auth}},auth:{persistSession:false,autoRefreshToken:false}});
 const{data:dealerId,error:authorizeError}=await userClient.rpc('dealer_service_job_media_authorize',{p_device_id:device,p_session_token:token,p_job_id:null});
 if(authorizeError||!dealerId)return json({error:'ACTIVE_DEALER_DEVICE_SESSION_REQUIRED'},401);
 const prefix=String(dealerId)+'/incoming/';if(!path.startsWith(prefix)||path.includes('..'))return json({error:'ACCESS_DENIED'},403);
 const{data:used,error:usedErr}=await admin.from('dealer_service_jobs').select('id').eq('dealer_id',dealerId).eq('machine_photo_url',path).limit(1);if(usedErr)throw usedErr;
 if(Array.isArray(used)&&used.length)return json({error:'PHOTO_ALREADY_ATTACHED_TO_JOB'},409);
 const{error:removeError}=await admin.storage.from(bucket).remove([path]);if(removeError)throw removeError;
 return json({ok:true});
 }catch(e){console.error(e);return json({error:'SERVICE_BOOK_PHOTO_DELETE_FAILED'},400)}});
