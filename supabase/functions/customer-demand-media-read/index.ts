import{clients,cors,json,secureDevice}from'../_shared/torvo-auth.ts';
const bucket='torvo-customer-requirement-media',ttl=120;
const uuid=v=>{const s=String(v??'').trim();if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s))throw new Error('VALID_ID_REQUIRED');return s};
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);try{
 const auth=req.headers.get('authorization')??'';if(!auth.toLowerCase().startsWith('bearer '))return json({error:'AUTH_REQUIRED'},401);
 const{admin}=clients(),jwt=auth.slice(7),{data:userData,error:userError}=await admin.auth.getUser(jwt);if(userError||!userData.user)return json({error:'AUTH_REQUIRED'},401);
 const body=await req.json(),mediaId=uuid(body.media_id),{data:app,error:appErr}=await admin.from('app_users').select('id,role,active,dealer_id').eq('auth_user_id',userData.user.id).eq('active',true).single();if(appErr||!app)return json({error:'ACCESS_DENIED'},403);
 let rows:any[]|null=null,err:any=null;
 if(app.role==='owner'||app.role==='admin'){const r=await admin.rpc('admin_customer_demand_media_paths',{p_demand_id:uuid(body.demand_id)});rows=r.data;err=r.error}
 else if(app.role==='dealer'&&app.dealer_id){const device=secureDevice(body.device_id);if(!body.session_token)return json({error:'ACTIVE_DEALER_DEVICE_SESSION_REQUIRED'},401);const v=await admin.rpc('dealer_validate_device_session',{p_dealer_id:app.dealer_id,p_device_id:device,p_session_token:String(body.session_token)});if(v.error||v.data!==true)return json({error:'ACTIVE_DEALER_DEVICE_SESSION_REQUIRED'},401);const r=await admin.rpc('dealer_customer_demand_media_paths',{p_lead_id:uuid(body.lead_id),p_device_id:device,p_session_token:String(body.session_token)});rows=r.data;err=r.error}
 else return json({error:'ACCESS_DENIED'},403);
 if(err)return json({error:'ACCESS_DENIED'},403);const media=(Array.isArray(rows)?rows:[]).find(x=>x.media_id===mediaId);if(!media?.storage_path)return json({error:'MEDIA_NOT_AVAILABLE'},404);
 const{data:signed,error:signErr}=await admin.storage.from(bucket).createSignedUrl(media.storage_path,ttl);if(signErr||!signed?.signedUrl)return json({error:'MEDIA_NOT_AVAILABLE'},404);
 return json({ok:true,url:signed.signedUrl,expires_in:ttl,mime_type:media.mime_type,byte_size:media.byte_size});
 }catch(e){console.error(e);return json({error:'MEDIA_ACCESS_FAILED'},400)}});