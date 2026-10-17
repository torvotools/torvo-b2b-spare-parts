import React from 'react';
import {loadPublicManagedSettings} from '../services/adminManagedExperience';
const DEFAULT_LOGO='/torvo-approved-logo.svg';
let logoCache=null;let pending=null;
const safeLogo=value=>{if(typeof value!=='string')return '';try{const u=new URL(value);return u.protocol==='https:'?u.href:''}catch{return''}};
function getLogo(){if(logoCache!==null)return Promise.resolve(logoCache);if(!pending)pending=loadPublicManagedSettings().then(data=>{logoCache=safeLogo(data?.website_content?.company_logo_url)||DEFAULT_LOGO;return logoCache}).catch(()=>DEFAULT_LOGO).finally(()=>{pending=null});return pending;}
/** Central TORVO company mark; all consumers share one approved asset setting. */
export default function TorvoBrandMark({className='',label='TORVO',width=148}){
 const [src,setSrc]=React.useState(logoCache||DEFAULT_LOGO);
 const [imageAvailable,setImageAvailable]=React.useState(true);
 React.useEffect(()=>{let mounted=true;getLogo().then(url=>{if(mounted){setSrc(url);setImageAvailable(true)}});return()=>{mounted=false}},[]);
 return <span className={`torvoBrandMark ${className}`.trim()} role="img" aria-label={label} style={{width,maxWidth:'100%'}}>{imageAvailable?<img className="torvoBrandApprovedImage" src={src} alt="" aria-hidden="true" onError={()=>{if(src!==DEFAULT_LOGO)setSrc(DEFAULT_LOGO);else setImageAvailable(false)}}/>:<span className="torvoBrandFallback" aria-hidden="true">TORVO</span>}</span>;
}
