import React from 'react';

/** One accessible brand asset across public and authenticated TORVO surfaces. */
export default function TorvoBrandMark({className='',label='TORVO',width=148}){
 const [imageAvailable,setImageAvailable]=React.useState(true);
 return <span className={`torvoBrandMark ${className}`.trim()} role="img" aria-label={label} style={{width,maxWidth:'100%'}}>
  {imageAvailable
   ? <img className="torvoBrandApprovedImage" src="/torvo-approved-logo.webp" alt="" aria-hidden="true" onError={()=>setImageAvailable(false)}/>
   : <span className="torvoBrandFallback" aria-hidden="true">TORVO</span>}
 </span>;
}
