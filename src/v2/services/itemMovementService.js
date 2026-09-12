import{requireBackend}from'./supabase';
const db=()=>requireBackend();
export async function getItemMovementCenter(itemId,{from=null,to=null,kind='all',limit=250}={}){if(!itemId)throw new Error('Item required');const{data,error}=await db().rpc('get_item_movement_center',{p_item:itemId,p_from:from||null,p_to:to||null,p_kind:kind,p_limit:limit});if(error)throw error;return data||{}}
