import{requireBackend}from'./supabase';
export const TORVO_ANDROID_PACKAGE='com.torvotools.app';
const allowedStatus=new Set(['verified','published']);
const allowedPlatform=new Set(['android_apk','android_aab','ios']);
const ephemeralHosts=new Set(['objects.githubusercontent.com','pipelines.actions.githubusercontent.com','productionresultssa0.blob.core.windows.net']);
const cleanRelease=x=>x&&typeof x==='object'?x:null;
const text=v=>String(v??'').trim();
const number=v=>{const n=Number(v);return Number.isSafeInteger(n)&&n>=0?n:null};
const packageOf=x=>text(x?.package_id??x?.package??x?.app_id);
const channelOf=x=>text(x?.channel).toLowerCase();
const sha256Of=x=>text(x?.artifact_sha256).toLowerCase();
export function durableDownload(release){const url=verifiedDownload(release);if(!url)return null;try{const u=new URL(url);const host=u.hostname.toLowerCase();if(ephemeralHosts.has(host)||host.endsWith('.blob.core.windows.net')||u.searchParams.has('se')&&u.searchParams.has('sig'))return null;return u.href}catch{return null}}
export async function loadAppReleases(){const{data,error}=await requireBackend().rpc('admin_app_release_center');if(error)throw error;if(data==null)return[];if(!Array.isArray(data))throw new Error('INVALID APP RELEASE RESPONSE');return data.filter(cleanRelease)}
export async function loadPublicAndroidUpdate(){const{data,error}=await requireBackend().rpc('public_android_app_update');if(error)throw error;if(data==null)return null;if(!Array.isArray(data))throw new Error('INVALID APP UPDATE RESPONSE');const release=cleanRelease(data[0]);const normalized=release?{...release,platform:'android_apk',status:'published',production_signed:true}:null;return normalized&&isProductionAndroidRelease(normalized)&&durableDownload(normalized)&&/^[0-9a-f]{64}$/.test(sha256Of(normalized))?normalized:null}
export function verifiedDownload(release){const x=cleanRelease(release);if(!x||!allowedStatus.has(text(x.status).toLowerCase())||!allowedPlatform.has(text(x.platform).toLowerCase()))return null;const url=text(x.artifact_url);if(!url)return null;try{const u=new URL(url);if(u.protocol!=='https:'||u.username||u.password)return null;return u.href}catch{return null}}
export function isProductionAndroidRelease(release){const x=cleanRelease(release);if(!x||text(x.platform).toLowerCase()!=='android_apk'||!verifiedDownload(x))return false;if(packageOf(x)!==TORVO_ANDROID_PACKAGE)return false;if(x.production_signed!==true)return false;const channel=channelOf(x);return channel==='production'||channel==='play'||channel==='stable'}
export function latestVerifiedRelease(releases,platform='android_apk'){const wanted=text(platform).toLowerCase();if(!allowedPlatform.has(wanted)||!Array.isArray(releases))return null;return releases.filter(x=>cleanRelease(x)&&text(x.platform).toLowerCase()===wanted&&verifiedDownload(x)).sort((a,b)=>(number(b.build_number)??-1)-(number(a.build_number)??-1))[0]||null}
export function latestProductionAndroidRelease(releases){if(!Array.isArray(releases))return null;return releases.filter(x=>isProductionAndroidRelease(x)&&durableDownload(x)).sort((a,b)=>(number(b.build_number)??-1)-(number(a.build_number)??-1))[0]||null}
export function appUpdateState(releases,currentBuild,platform='android_apk'){const current=number(currentBuild);const latest=platform==='android_apk'?latestProductionAndroidRelease(releases):latestVerifiedRelease(releases,platform);const next=number(latest?.build_number);if(current==null||!latest||next==null)return{available:false,required:false,release:latest};const minimum=number(latest?.min_supported_build);return{available:next>current,required:minimum!=null&&current<minimum,release:latest}}
