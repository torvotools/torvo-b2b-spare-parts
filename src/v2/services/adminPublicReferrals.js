import{requireBackend}from'./supabase';
const db=()=>requireBackend();
const statuses=new Set(['','DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED']);
const actions=new Set(['MARK_CONTACTED','MARK_CONVERTED','CLOSE','REOPEN']);
const clean=(v,max=200)=>String(v||'').trim().slice(0,max);
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export async function loadAdminPublicReferrals({status='',search='',limit=100}={}){const s=clean(status,40).toUpperCase();if(!statuses.has(s))throw new Error('INVALID REFERRAL STATUS');const{data,error}=await db().rpc('admin_public_referral_crm',{p_status:s||null,p_search:clean(search,160)||null,p_limit:Math.max(1,Math.min(Number(limit)||100,500))});if(error)throw error;return Array.isArray(data)?data:[]}
export async function updateAdminPublicReferral(referralId,action,note=''){const id=clean(referralId,40),a=clean(action,40).toUpperCase();if(!UUID.test(id))throw new Error('INVALID REFERRAL ID');if(!actions.has(a))throw new Error('INVALID REFERRAL ACTION');const{data,error}=await db().rpc('admin_update_public_referral',{p_referral_id:id,p_action:a,p_note:clean(note,1000)||null});if(error)throw error;return Array.isArray(data)?data[0]||null:data||null}
