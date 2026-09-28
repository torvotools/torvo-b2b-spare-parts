import{createClient}from'npm:@supabase/supabase-js@2';import{clients,cors,json,secureDevice}from'../_shared/torvo-auth.ts';
const bucket='torvo-service-book-media',types=new Set(['image/jpeg','image/png','image/webp']),max=8*1024*1024;
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);try{
 const auth=req.headers.get('authorization')??'';if(!auth.toLowerCase().startsWith('bearer '))return json({error:'AUTH_REQUIRED'},401);
 const form=await req.formData(),device=secureDevice(form.get('device_id')),token=String(form.get('session_token')??''),file=form.get('file');
 if(!token||!(file instanceof File))return json({error:'ACTIVE_DEALER_SESSION_AND_PHOTO_REQUIRED'},400);
 if(!types.has(file.type)||file.size<1||file.size>max)return json({error:'JPG_PNG_WEBP_MAX_8MB'},400);
 const{admin}=clients(),jwt=auth.slice(7),{data:userData,error:userError}=await admin.auth.getUser(jwt);if(userError||!userData.user)return json({error:'AUTH_REQUIRED'},401);
 const userClient=createClient(Deno.env.get('SUPABASE_URL')??'',Deno.env.get('SUPABASE_ANON_KEY')??'',{global:{headers:{Authorization:auth}},auth:{persistSession:false,autoRefreshToken:false}});
 const{data:dealerId,error:authorizeError}=await userClient.rpc('dealer_service_job_media_authorize',{p_device_id:device,p_session_token:token,p_job_id:null});
 if(authorizeError||!dealerId)return json({error:'ACTIVE_DEALER_DEVICE_SESSION_REQUIRED'},401);
 const ext=file.type==='image/png'?'png':file.type==='image/webp'?'webp':'jpg',path=`${dealerId}/incoming/${crypto.randomUUID()}.${ext}`;
 const{error:upErr}=await admin.storage.from(bucket).upload(path,file,{contentType:file.type,cacheControl:'3600',upsert:false});if(upErr)throw upErr;
 return json({ok:true,storage_path:path});
 }catch(e){console.error(e);return json({error:'SERVICE_BOOK_PHOTO_UPLOAD_FAILED'},400)}});
