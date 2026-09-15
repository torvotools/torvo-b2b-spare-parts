import{requireBackend}from'./supabase';
export async function loadExpenseReport(from=null,to=null){
 const{data,error}=await requireBackend().rpc('get_business_expenses',{p_from:from,p_to:to});
 if(error)throw error;
 return Array.isArray(data)?data:[];
}
