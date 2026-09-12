import React,{useCallback,useEffect,useState}from'react';
import{AlertCircle,RefreshCw}from'lucide-react';
import DealerPortal from'./DealerPortal';
import DealerApprovedAddOnOrders from'./DealerApprovedAddOnOrders';
import{data}from'../services/repository';

export default function DealerPortalMounted({user}){
 const[catalog,setCatalog]=useState([]),[catalogLoading,setCatalogLoading]=useState(true),[catalogError,setCatalogError]=useState('');
 const loadCatalog=useCallback(async()=>{
  setCatalogLoading(true);setCatalogError('');
  try{
   const groups=await Promise.all(['machine','spare_part','accessory'].map(type=>data.catalog(type)));
   setCatalog(groups.flat().filter(item=>item.active!==false));
  }catch(e){setCatalog([]);setCatalogError(e?.message||'Catalog could not be loaded.');}
  finally{setCatalogLoading(false)}
 },[]);
 useEffect(()=>{loadCatalog()},[loadCatalog]);
 return <>
  <DealerPortal user={user}/>
  {user?.dealer_id&&<DealerApprovedAddOnOrders catalog={catalog} catalogLoading={catalogLoading} catalogError={catalogError} onRetryCatalog={loadCatalog}/>} 
 </>;
}
