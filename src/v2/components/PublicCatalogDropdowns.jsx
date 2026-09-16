import React,{useEffect,useState}from'react';
import{loadCatalogBrands,loadCatalogMachineModels}from'../services/publicWebsite';

export default function PublicCatalogDropdowns({value,onChange,disabled=false}){
 const[brands,setBrands]=useState([]),[models,setModels]=useState([]),[loading,setLoading]=useState(''),[error,setError]=useState('');
 useEffect(()=>{let live=true;setLoading('BRAND');setError('');loadCatalogBrands().then(x=>{if(live)setBrands(x||[])}).catch(()=>{if(live){setBrands([]);setError('CATALOG BRAND MASTER NOT AVAILABLE')}}).finally(()=>{if(live)setLoading('')});return()=>{live=false}},[]);
 useEffect(()=>{let live=true;const brand=String(value?.brand||'').trim();if(!brand){setModels([]);return()=>{live=false}}setLoading('MODEL');setError('');loadCatalogMachineModels(brand).then(x=>{if(live)setModels(x||[])}).catch(()=>{if(live){setModels([]);setError('MACHINE / MODEL MASTER NOT AVAILABLE')}}).finally(()=>{if(live)setLoading('')});return()=>{live=false}},[value?.brand]);
 const changeBrand=e=>onChange?.({...value,brand:e.target.value,machineModel:''});
 const changeModel=e=>onChange?.({...value,machineModel:e.target.value});
 return <><div className="formTwo"><label>BRAND<select name="brand" value={value?.brand||''} onChange={changeBrand} disabled={disabled||loading==='BRAND'}><option value="">{loading==='BRAND'?'LOADING BRANDS…':'SELECT BRAND'}</option>{brands.map(x=><option key={x.id||x.name} value={x.name}>{x.name}</option>)}</select></label><label>MACHINE / MODEL<select name="machineModel" value={value?.machineModel||''} onChange={changeModel} disabled={disabled||!value?.brand||loading==='MODEL'}><option value="">{loading==='MODEL'?'LOADING MODELS…':'SELECT MACHINE / MODEL'}</option>{models.map(x=><option key={x.id||x.name} value={x.name}>{x.name}</option>)}</select></label></div>{error&&<small className="errorText">{error}</small>}</>;
}
