import{requireBackend}from'./supabase';
const allowedStatus=new Set(['verified','published']);
const allowedPlatform=new Set(['android_apk','android_aab','ios']);
const cleanRelease=x=>x&&typeof x==='object'?x:null;
export async function loadAppReleases(){const{data,error}=await requireBackend().rpc('admin_app_release_center');if(error)throw error;return Array.isArray(data)?data:[]}
export function verifiedDownload(release){const x=cleanRelease(release);if(!x||!allowedStatus.has(String(x.status||'').toLowerCase())||!allowedPlatform.has(String(x.platform||'').toLowerCase()))return null;const url=String(x.artifact_url||'').trim();if(!url)return null;try{const u=new URL(url);if(u.protocol!=='https:')return null;return u.href}catch{return null}}
