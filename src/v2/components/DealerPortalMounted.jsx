import React,{useEffect,useState}from'react';
import DealerPortal from'./DealerPortal';
import DealerApprovedAddOnOrders from'./DealerApprovedAddOnOrders';
import{data}from'../services/repository';
export default function DealerPortalMounted({user}){const[catalog,setCatalog]=useState([]);useEffect(()=>{let live=true;Promise.all(['machine','spare_part','accessory'].map(x=>data.catalog(x))).then(x=>live&&setCatalog(x.flat().filter(i=>i.active!==false))).catch(()=>{});return()=>{live=false}},[]);return <><DealerPortal user={user}/>{user?.dealer_id&&<DealerApprovedAddOnOrders catalog={catalog}/>}</>}
