import{getSupabase}from'./supabase';
const db=()=>{const x=getSupabase();if(!x)throw new Error('BACKEND NOT CONFIGURED');return x};
export async function loadAppReleases(){const{data,error}=await db().rpc('admin_app_release_center');if(error)throw error;return data||[]}
export function verifiedDownload(release){if(!release||release.status!=='verified'&&release.status!=='published'||!release.artifact_url)return null;return release.artifact_url}
