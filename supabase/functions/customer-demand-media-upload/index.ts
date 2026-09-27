import{clients,cors,json}from'../_shared/torvo-auth.ts';
const bucket='torvo-customer-requirement-media',types=new Set(['image/jpeg','image/png','image/webp']),max=8*1024*1024;
const mobile=v=>String(v??'').replace(/\D/g,'').slice(-10);
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response('ok',{headers:cors});if(req.method!=='POST')return json({error:'METHOD_NOT_ALLOWED'},405);try{
 const form=await req.formData(),demand=String(form.get('demand_id')??'').trim(),m=mobile(form.get('mobile')),file=form.get('file');
 if(!demand||m.length!==10||!(file instanceof File))return json({error:'VALID_DEMAND_MOBILE_PHOTO_REQUIRED'},400);
 if(!types.has(file.type)||file.size<1||file.size>max)return json({error:'JPG_PNG_WEBP_MAX_8MB'},400);
 const{admin}=clients();
 const{data:rows,error:proofErr}=await admin.rpc('service_customer_demand_media_upload_proof',{p_demand_id:demand,p_mobile:m});
 if(proofErr||!Array.isArray(rows)||rows.length!==1||rows[0]?.allowed!==true)return json({error:'CUSTOMER_REQUIREMENT_PROOF_FAILED'},403);
 const ext=file.type==='image/png'?'png':file.type==='image/webp'?'webp':'jpg',path=`${demand}/${crypto.randomUUID()}.${ext}`;
 const{error:upErr}=await admin.storage.from(bucket).upload(path,file,{contentType:file.type,cacheControl:'3600',upsert:false});if(upErr)throw upErr;
 const{error:metaErr}=await admin.rpc('service_register_customer_demand_media',{p_demand_id:demand,p_storage_path:path,p_mime_type:file.type,p_byte_size:file.size});
 if(metaErr){await admin.storage.from(bucket).remove([path]);throw metaErr}
 return json({ok:true});
 }catch(e){console.error(e);return json({error:'REQUIREMENT_PHOTO_UPLOAD_FAILED'},400)}});