import{requireBackend}from'./supabase';
export async function loadRewardBalance(){const c=requireBackend(),{data,error}=await c.rpc('dealer_reward_balance');if(error)throw error;return Number(data)||0}
export async function loadRewardOptions(){const c=requireBackend(),{data,error}=await c.rpc('dealer_reward_options');if(error)throw error;return Array.isArray(data)?data:[]}
export async function claimReward(rewardId){const c=requireBackend(),{data,error}=await c.rpc('dealer_claim_reward',{p_reward:rewardId});if(error)throw error;return data}
export async function issueRewardVoucher(claimId,provider,code){const c=requireBackend(),{data,error}=await c.rpc('admin_issue_reward_voucher',{p_claim:claimId,p_provider:String(provider||'').toUpperCase(),p_code:String(code||'').trim()});if(error)throw error;return data}
