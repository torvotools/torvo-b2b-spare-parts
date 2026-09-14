import{requireBackend}from'./supabase';
const rpc=async(name,args={})=>{const c=requireBackend(),{data,error}=await c.rpc(name,args);if(error)throw error;return data};
export async function loadRewardBalance(){return Number(await rpc('dealer_reward_balance'))||0}
export async function loadRewardOptions(){const data=await rpc('dealer_reward_options');return Array.isArray(data)?data:[]}
export async function loadRewardProgress(){const data=await rpc('dealer_reward_progress');return Array.isArray(data)?data[0]||null:data||null}
export async function loadRewardClaims(){const data=await rpc('dealer_reward_claim_history');return Array.isArray(data)?data:[]}
export async function claimReward(rewardId){return rpc('dealer_claim_reward',{p_reward:rewardId})}
export async function loadTargetRewardAdminData(){const d=await rpc('admin_dealer_target_reward_data');return d||{scheme_year:null,target_types:[],target_slabs:[],assignments:[],reward_options:[],claims:[],dealers:[]}}
export async function issueRewardVoucher(claimId,provider,code){return rpc('admin_issue_reward_voucher',{p_claim:claimId,p_provider:String(provider||'').toUpperCase(),p_code:String(code||'').trim()})}
export async function approveRewardClaim(claimId){return rpc('admin_approve_reward_claim',{p_claim:claimId})}
export async function cancelRewardClaim(claimId,reason){return rpc('admin_cancel_reward_claim',{p_claim:claimId,p_reason:String(reason||'').trim()})}
export async function settleDealerTarget(dealerId,schemeYear){const data=await rpc('admin_settle_dealer_target',{p_dealer:dealerId,p_scheme_year:Number(schemeYear)});return Array.isArray(data)?data[0]||null:data||null}
export async function saveTargetType(name,startMonth=4){return rpc('admin_save_dealer_target_type',{p_name:String(name||'').trim(),p_start_month:Number(startMonth)||4})}
export async function saveTargetSlab(targetTypeId,targetValue,points){return rpc('admin_save_dealer_target_slab',{p_target_type:targetTypeId,p_target_value:Number(targetValue),p_points:Number(points)})}
export async function assignDealerTarget(dealerId,targetTypeId,schemeYear){return rpc('admin_assign_dealer_target',{p_dealer:dealerId,p_target_type:targetTypeId,p_scheme_year:Number(schemeYear)})}
export async function saveRewardOption(name,pointsRequired,giftValue=0,redemptionType='gift'){return rpc('admin_save_dealer_reward_option',{p_name:String(name||'').trim(),p_points:Number(pointsRequired),p_gift_value:Number(giftValue)||0,p_redemption_type:String(redemptionType||'gift').toLowerCase()})}
