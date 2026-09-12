import React from'react';
import DealerPortal from'./DealerPortal';
import DealerApprovedAddOnOrders from'./DealerApprovedAddOnOrders';

export default function DealerPortalMounted({user}){
 return <>
  <DealerPortal user={user}/>
  {user?.dealer_id&&<DealerApprovedAddOnOrders/>}
 </>;
}
