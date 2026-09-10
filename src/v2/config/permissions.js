export const PERMISSIONS={
 owner:['*'],
 admin:['dealer.view','dealer.approve','dealer.hold','dealer.reject','catalog.view','catalog.create','catalog.edit','mapping.manage','sales.manage','payment.view','payment.update','inventory.view','inventory.manage','dispatch.manage','scheme.manage','message.manage','report.view','user.manage','audit.view','feature.manage'],
 salesman:['dealer.view','catalog.view','mapping.view','sales.manage','scheme.view','message.manage'],
 accountant:['payment.view','payment.update','sales.financial_view','report.view'],
 store_keeper:['inventory.view','inventory.manage','dispatch.manage'],
 dealer:['catalog.view_public','mapping.view_public','query.create','quotation.view','sales_order.view','estimate.view','payment.view_own','scheme.view_own','message.create']
};
export function can(role,permission){const list=PERMISSIONS[role]||[];return list.includes('*')||list.includes(permission)}
export const FINANCIAL_FIELDS=['rate','purchase_cost','selling_price','discount','tax','freight','profit','margin','total','payable'];
export function stripFinancials(record){if(!record)return record;const copy={...record};FINANCIAL_FIELDS.forEach(k=>delete copy[k]);return copy}
