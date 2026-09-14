import{dealerItemRate,submitDealerPurchaseOrder}from'./dealerProcurement';
import{confirmDealerSalesOrder,loadDealerOrderHistory}from'./dealerOrders';
import{loadDealerMachineSpares}from'./dealerMachineSpares';
import{reviseDealerPurchaseOrder,requestDealerSalesOrderChange,loadApprovedAdditionalRequests,createApprovedAdditionalOrder}from'./dealerBusiness';

// Compatibility facade for older UI modules. Every dealer-private action below is routed
// through the current device-bound service; this file must never call Supabase directly.
export const secureDealerLegacy={
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
