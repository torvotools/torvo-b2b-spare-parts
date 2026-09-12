import {supabase}from'./supabase';
const ok=r=>{if(r.error)throw r.error;return r.data||[]};
export const approvalService={
 async pending(limit=200){return ok(await supabase.rpc('get_pending_approval_queue',{p_limit:limit}))},
 async mine(limit=200){return ok(await supabase.rpc('get_my_approval_work',{p_limit:limit}))},
 async decide(id,decision,note=''){const r=await supabase.rpc('decide_approval_request',{p_approval:id,p_decision:decision,p_note:note||null});if(r.error)throw r.error},
 async setPermission(userId,canApprove,canApproveOwn=false){const r=await supabase.rpc('set_transaction_approval_permission',{p_user:userId,p_can_approve:!!canApprove,p_can_approve_own:!!canApproveOwn});if(r.error)throw r.error},
 async submit({module,entityType,entityId,actionType,summary,amount=null,payload={}}){const r=await supabase.rpc('submit_approval_request',{p_module:module,p_entity_type:entityType,p_entity_id:String(entityId),p_action_type:actionType,p_summary:summary,p_amount:amount,p_payload:payload});if(r.error)throw r.error;return r.data}
};
