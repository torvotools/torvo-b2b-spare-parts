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
 const over=links.filter(x=>x.position==='overlay');const below=links.filter(x=>x.position!=='overlay');
 const buttons=(items)=>items.map((x,i)=><a key={x.action+'-'+i} href={allowedActions[x.action]} style={{display:'inline-block',padding:'12px 16px',background:x.style==='white'?'#fff':x.style==='black'?'#171717':'#c81920',color:x.style==='white'?'#171717':'#fff',border:x.style==='white'?'1px solid #777':'1px solid transparent',fontWeight:700,textDecoration:'none',borderRadius:4}}>{x.label}</a>);
 return <section aria-label="TORVO HERO"><div style={{maxWidth:1920,margin:'0 auto'}}><div style={{position:'relative'}}><img src={src} alt="TORVO POWER TOOL SPARE PARTS" decoding="async" loading="eager" style={{display:'block',width:'100%',height:'auto'}}/>{over.length>0&&<nav aria-label="HERO IMAGE ACTIONS" style={{position:'absolute',bottom:12,left:0,right:0,display:'flex',gap:8,justifyContent:'center',flexWrap:'wrap',padding:'0 12px'}}>{buttons(over)}</nav>}</div>{below.length>0&&<nav aria-label="HERO ACTIONS" style={{display:'flex',gap:10,padding:'12px 14px',justifyContent:'center',flexWrap:'wrap',background:'#fff'}}>{buttons(below)}</nav>}</div></section>;
}
