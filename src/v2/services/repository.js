import{requireBackend}from'./supabase';
const db=()=>requireBackend();
export const data={
 async list(table,{select='*',order='created_at',ascending=false}={}){const{data,error}=await db().from(table).select(select).order(order,{ascending});if(error)throw error;return data||[]},
 async create(table,payload){const{data,error}=await db().from(table).insert(payload).select().single();if(error)throw error;return data},
 async update(table,id,payload){const{data,error}=await db().from(table).update(payload).eq('id',id).select().single();if(error)throw error;return data},
 async dealers(){return this.list('dealers')},
 async catalog(type){const{data,error}=await db().from('catalog_items').select('*').eq('item_type',type).eq('active',true).order('name');if(error)throw error;return data||[]},
 async documents(type){const{data,error}=await db().from('sales_documents').select('*,dealers(shop_name,dealer_code),sales_document_lines(*)').eq('doc_type',type).order('created_at',{ascending:false});if(error)throw error;return data||[]},
 async inventory(){const{data,error}=await db().from('inventory').select('*,catalog_items(item_code,name,item_type,brand,model)').order('updated_at',{ascending:false});if(error)throw error;return data||[]},
 async dispatches(){const{data,error}=await db().from('dispatches').select('*,sales_documents(*,dealers(shop_name,dealer_code))').order('id',{ascending:false});if(error)throw error;return data||[]},
 async compatibility(){const{data,error}=await db().from('machine_spare_mapping').select('*,machine:catalog_items!machine_id(*),spare:catalog_items!spare_part_id(*)');if(error)throw error;return data||[]}
};
