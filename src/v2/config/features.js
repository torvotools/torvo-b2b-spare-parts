export const FEATURES={
 dealer_registration:true,dealer_approval:true,dealer_hold:true,dealer_reject:true,
 machines:true,spare_parts:true,accessories:true,compatibility:true,
 query:true,quotation:true,sales_order:true,estimate:true,payments:true,
 pick_list:true,packing:true,dispatch:true,delivery:true,
 inventory:true,reorder:true,schemes:true,rewards:true,referrals:true,
 non_available_requests:true,messages:true,notifications:true,reports:true,
 users_roles:true,audit:true,recycle_bin:true,uploads:true
};
export const PROTECTED_RULES=['role_security','payment_before_delivery','once_only_stock_deduction','audit_integrity'];
export const FEATURE_GROUPS={
 Dealer:['dealer_registration','dealer_approval','dealer_hold','dealer_reject'],
 Catalog:['machines','spare_parts','accessories','compatibility','uploads'],
 Sales:['query','quotation','sales_order','estimate','payments'],
 Store:['pick_list','packing','dispatch','delivery','inventory','reorder'],
 Engagement:['schemes','rewards','referrals','non_available_requests','messages','notifications'],
 System:['reports','users_roles','audit','recycle_bin']
};
