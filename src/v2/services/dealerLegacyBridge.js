import{dealerItemRate,submitDealerPurchaseOrder}from'./dealerProcurement';
import{confirmDealerSalesOrder,loadDealerOrderHistory}from'./dealerOrders';
import{loadDealerMachineSpares}from'./dealerMachineSpares';
import{loadDealerWorkspaceCatalog}from'./dealerWorkspace';
import{reviseDealerPurchaseOrder,requestDealerSalesOrderChange,loadApprovedAdditionalRequests,createApprovedAdditionalOrder}from'./dealerBusiness';

// Compatibility facade for dealer UI modules. Every dealer-private action below is routed
// through a current device-bound service; this file must never call Supabase directly.
const documents=async type=>{const rows=await loadDealerOrderHistory();return rows.filter(x=>x.doc_type===type)};
const catalog=async type=>{const rows=await loadDealerWorkspaceCatalog();return rows.filter(x=>x.item_type===type)};
export const secureDealerLegacy={
 documents,
 catalog,
 dealerMachineSpares:loadDealerMachineSpares,
 dealerItemRate,
 submitPurchaseOrder:submitDealerPurchaseOrder,
 dealerConfirmSalesOrder:confirmDealerSalesOrder,
 dealerReviseSalesOrder:reviseDealerPurchaseOrder,
 dealerRequestSalesOrderChange:requestDealerSalesOrderChange,
 dealerApprovedAddOnRequests:loadApprovedAdditionalRequests,
 dealerCreateAddOnOrder:createApprovedAdditionalOrder,
 dealerOrderHistory:loadDealerOrderHistory
};
export const dealerPrivateActions=Object.freeze(Object.keys(secureDealerLegacy));
