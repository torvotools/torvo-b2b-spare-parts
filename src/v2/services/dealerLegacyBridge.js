import{getDealerItemRate,submitDealerPO,approveLatestDealerOrder,loadDealerOrders,reviseDealerPO,requestDealerOrderChange,loadApprovedAddOnRequests,createApprovedAddOnOrder}from'./dealerB2BFlow';
import{loadDealerMachineSpares}from'./dealerMachineSpares';
import{loadDealerWorkspaceCatalog}from'./dealerWorkspace';
import{loadDealerRepairRequirements,updateDealerRepairRequirement,acceptDealerRepairRequirement,closeDealerRepairRequirement,loadOpenDealerRepairRequirements,loadAcceptedDealerRepairRequirements,dealerRepairStatuses}from'./dealerRepair';
// Compatibility facade for dealer UI modules. Private actions stay behind approved-device services.
const documents=async type=>{const t=String(type||'').trim().toLowerCase();if(!['sales_order','estimate'].includes(t))throw new Error('INVALID DOCUMENT TYPE');const rows=await loadDealerOrders();return rows.filter(x=>x.doc_type===t)};
const catalog=async type=>{const t=String(type||'').trim().toLowerCase();if(!['machine','spare_part','accessory'].includes(t))throw new Error('INVALID PRODUCT TYPE');const rows=await loadDealerWorkspaceCatalog();return rows.filter(x=>x.item_type===t)};
export const secureDealerLegacy={
 documents,catalog,
 dealerMachineSpares:loadDealerMachineSpares,
 dealerItemRate:getDealerItemRate,
 submitPurchaseOrder:submitDealerPO,
 dealerConfirmSalesOrder:approveLatestDealerOrder,
 dealerReviseSalesOrder:(orderId,items,reason)=>reviseDealerPO({orderId,items,reason}),
 dealerRequestSalesOrderChange:(orderId,type,reason)=>requestDealerOrderChange({orderId,type,reason}),
 dealerApprovedAddOnRequests:loadApprovedAddOnRequests,
 dealerCreateAddOnOrder:(requestId,items)=>createApprovedAddOnOrder({requestId,items}),
 dealerOrderHistory:loadDealerOrders,
 dealerRepairRequirements:loadDealerRepairRequirements,
 dealerOpenRepairRequirements:loadOpenDealerRepairRequirements,
 dealerAcceptedRepairRequirements:loadAcceptedDealerRepairRequirements,
 dealerAcceptRepairRequirement:acceptDealerRepairRequirement,
 dealerCloseRepairRequirement:closeDealerRepairRequirement,
 dealerUpdateRepairRequirement:updateDealerRepairRequirement,
 dealerRepairStatuses
};
export const data=secureDealerLegacy;
export const dealerPrivateActions=Object.freeze(Object.keys(secureDealerLegacy));
