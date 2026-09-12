import{supabase,backendConfigured}from'./supabase';
const need=()=>{if(!backendConfigured)throw new Error('Backend is not configured')};
export const backupService={async list(){need();const{data,error}=await supabase.rpc('get_backup_control_status');if(error)throw error;return data||[]},async request(type,notes=''){need();const{data,error}=await supabase.rpc('request_backup_run',{p_type:type,p_notes:notes||null});if(error)throw error;return data}};
