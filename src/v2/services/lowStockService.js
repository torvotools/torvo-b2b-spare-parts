import{requireBackend}from'./supabase';
const db=()=>requireBackend();
export async function getLowStockDrilldown({search='',state='low',brand='',category='',limit=250}={}){const{data,error}=await db().rpc('get_low_stock_drilldown',{p_search:String(search||'').trim()||null,p_state:state||'low',p_brand:String(brand||'').trim()||null,p_category:String(category||'').trim()||null,p_limit:limit});if(error)throw error;return data||{rows:[],financial_visibility:'stock_only'}}
