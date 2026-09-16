import{getDealerItemRate,submitDealerPO,approveLatestDealerOrder,loadDealerOrders,reviseDealerPO,requestDealerOrderChange,loadApprovedAddOnRequests,createApprovedAddOnOrder}from'./dealerB2BFlow';
import{loadDealerMachineSpares}from'./dealerMachineSpares';
import{loadDealerWorkspaceCatalog}from'./dealerWorkspace';
import{loadDealerRepairRequirements,updateDealerRepairRequirement}from'./dealerRepair';

// Compatibility facade for dealer UI modules. All B2B order/rate mutations are now routed
// through dealerB2BFlow so validation and approved-device session rules have one boundary.
const documents=async type=>{const rows=await loadDealerOrders();return rows.filter(x=>x.doc_type===type)};
const catalog=async type=>{const rows=await loadDealerWorkspaceCatalog();return rows.filter(x=>x.item_type===type)};
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
 dealerUpdateRepairRequirement:updateDealerRepairRequirement
};
export const data=secureDealerLegacy;
export const dealerPrivateActions=Object.freeze(Object.keys(secureDealerLegacy));
