import React from 'react';

/**
 * TORVO V2 canonical brand mark.
 * The approved artwork is served from a single public asset, never rebuilt
 * from letter glyphs. Keep the text fallback until the image asset is present.
 * No business, authentication, or routing behavior lives here.
 */
export default function TorvoBrandMark({className='',label='TORVO TOOLS'}){
 const [imageAvailable,setImageAvailable]=React.useState(true);
 return <span className={`torvoBrandMark ${className}`.trim()} role="img" aria-label={label}>
  {imageAvailable?<img className="torvoBrandApprovedImage" src="/torvo-approved-logo.webp" alt="" aria-hidden="true" onError={()=>setImageAvailable(false)}/>:<span className="torvoBrandFallback">TORVO</span>}
 </span>;
}
