import{dealerItemRate,submitDealerPurchaseOrder}from'./dealerProcurement';
import{confirmDealerSalesOrder,requestDealerAdditionalOrder,loadDealerOrderHistory}from'./dealerOrders';
import{loadDealerMachineSpares}from'./dealerMachineSpares';

export const secureDealerLegacy={
 dealerMachineSpares:loadDealerMachineSpares,
 dealerItemRate,
 submitPurchaseOrder:submitDealerPurchaseOrder,
 dealerConfirmSalesOrder:confirmDealerSalesOrder,
 dealerCreateAddOnOrder:(requestId,lines)=>requestDealerAdditionalOrder(requestId,lines,'APPROVED ADDITIONAL PURCHASE ORDER'),
 dealerOrderHistory:loadDealerOrderHistory
};
