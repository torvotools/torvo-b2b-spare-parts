import React from 'react';

/**
 * Staging-only implementation for the owner's selected 1536x864 TORVO hero.
 * This does NOT use the older four-slot mask prototype. No image is bundled:
 * pass a verified, owner-approved image URL after it has been uploaded.
 * Do not mount until artwork/logo/text are reviewed and the CTA hit areas
 * have been visually tested on mobile and desktop.
 */
const safeImageUrl = (value) => {
  if (typeof value !== 'string') return '';
  if (value.startsWith('/')) return value.startsWith('//') ? '' : value;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' ? url.href : '';
  } catch {
    return '';
  }
};

const actionStyle = (left, top, width, height) => ({
  position: 'absolute',
  left: `${left}%`,
  top: `${top}%`,
  width: `${width}%`,
  height: `${height}%`,
  display: 'block',
  borderRadius: '4px',
});

const allowedActions={products:'#products',dealer:'#torvo-dealer',contact:'#contact',none:''};
export default function OwnerSelectedHeroDraft({imageUrl,mobile=false,actions}){
 const src=safeImageUrl(imageUrl);if(!src)return null;
 const configured=Array.isArray(actions)?actions:[{enabled:true,label:'EXPLORE PRODUCTS',action:'products'},{enabled:true,label:'FIND A DEALER',action:'dealer'}];
 const links=configured.filter(x=>x?.enabled&&allowedActions[x.action]&&String(x.label||'').trim()).slice(0,2);
 return <section aria-label="TORVO HERO"><div style={{maxWidth:1920,margin:'0 auto'}}><img src={src} alt="TORVO POWER TOOL SPARE PARTS" decoding="async" loading="eager" style={{display:'block',width:'100%',height:'auto'}}/>{links.length>0&&<nav aria-label="HERO ACTIONS" style={{display:'flex',gap:10,padding:'12px 14px',justifyContent:'center',flexWrap:'wrap',background:'#fff'}}>{links.map((x,i)=><a key={i} href={allowedActions[x.action]} style={{padding:'12px 16px',background:i===0?'#c81920':'#171717',color:'#fff',fontWeight:700,textDecoration:'none',borderRadius:4}}>{x.label}</a>)}</nav>}</div></section>;
}
