import React,{useEffect,useState}from'react';
import DealerPortal from'./DealerPortal';
import DealerApprovedAddOnOrders from'./DealerApprovedAddOnOrders';
import{data}from'../services/repository';

export default function DealerPortalEnhanced({user}){
 const[catalog,setCatalog]=useState([]),[refreshKey,setRefreshKey]=useState(0);
 useEffect(()=>{let live=true;Promise.all([data.catalog('machine'),data.catalog('spare_part'),data.catalog('accessory')]).then(parts=>{if(live)setCatalog(parts.flat().filter(x=>x.active!==false))}).catch(()=>{});return()=>{live=false}},[]);
 return <>
  <DealerPortal key={refreshKey} user={user}/>
  {user?.dealer_id&&<DealerApprovedAddOnOrders catalog={catalog} onOrderCreated={()=>setRefreshKey(k=>k+1)}/>} 
 </>;
}
