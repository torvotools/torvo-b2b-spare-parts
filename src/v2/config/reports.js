export const REPORT_CATALOG=[
{id:'sales',name:'Sales Report',roles:['owner','admin','accountant'],metrics:['gross_sales','net_sales','orders','avg_order']},
{id:'profit',name:'Profit & Margin',roles:['owner','admin'],metrics:['sales','cost','profit','margin']},
{id:'conversion',name:'Quotation Conversion',roles:['owner','admin'],metrics:['queries','quotations','accepted','conversion_rate']},
{id:'order-estimate',name:'Order vs Estimate',roles:['owner','admin','accountant'],metrics:['orders','estimates','variance']},
{id:'outstanding',name:'Payment Outstanding & Aging',roles:['owner','admin','accountant'],metrics:['pending','0_30','31_60','61_plus']},
{id:'dealer',name:'Dealer Performance',roles:['owner','admin'],metrics:['active','inactive','sales','orders']},
{id:'product',name:'Product / Brand Performance',roles:['owner','admin'],metrics:['qty','sales','top_items','slow_items']},
{id:'inventory',name:'Inventory & Stock Movement',roles:['owner','admin'],metrics:['stock','movement','low','out']},
{id:'reorder',name:'Low Stock & Reorder',roles:['owner','admin'],metrics:['low','out','required','ordered']},
{id:'dispatch',name:'Dispatch Turnaround',roles:['owner','admin'],metrics:['pending','ready','delivered','turnaround']},
{id:'scheme',name:'Scheme Progress',roles:['owner','admin'],metrics:['participants','achieved','points','rewards']},
{id:'opportunity',name:'Missing Range Opportunity',roles:['owner','admin'],metrics:['searches','requests','sourced','open']},
{id:'audit',name:'Audit & Activity',roles:['owner','admin'],metrics:['actions','users','sensitive_actions','changes']}
];
export const EXPORT_FORMATS=['xlsx','pdf'];
export const DATE_PRESETS=['today','this_week','this_month','this_quarter','custom'];
