import{requireBackend}from'./supabase';
import{assertDealerSession}from'./dealerSession';
const proof=async()=>{const p=await assertDealerSession();if(!p?.deviceId||!p?.token)throw new Error('ACTIVE DEALER DEVICE SESSION REQUIRED');return p};
const leadId=v=>{const s=String(v||'').trim();if(!s||s.length>128)throw new Error('CUSTOMER LEAD IS INVALID');return s};
const rpc=async(name,args={})=>{const p=await proof();const{data,error}=await requireBackend().rpc(name,{...args,p_device_id:p.deviceId,p_session_token:p.token});if(error)throw error;await assertDealerSession();return data};
export const loadDealerCustomerLeads=async(limit=50)=>{const n=Math.max(1,Math.min(Number(limit)||50,100));const data=await rpc('dealer_customer_demand_leads',{p_limit:n});if(data==null)return[];if(!Array.isArray(data))throw new Error('INVALID CUSTOMER LEAD RESPONSE');return data};
export const acceptDealerCustomerLead=async(id)=>{const data=await rpc('dealer_accept_customer_demand_lead',{p_lead_id:leadId(id)});const row=Array.isArray(data)?data[0]:data;if(!row?.lead_id)throw new Error('CUSTOMER CONTACT UNLOCK FAILED');return row};
export const declineDealerCustomerLead=async(id)=>{const data=await rpc('dealer_decline_customer_demand_lead',{p_lead_id:leadId(id)});if(data!==true)throw new Error('CUSTOMER LEAD DECLINE FAILED');return true};
