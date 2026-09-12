import React,{useEffect} from 'react';
import {createRoot} from 'react-dom/client';
import DealerVisualPreview from './components/DealerVisualPreview';
import AdminVisualPreview from './components/AdminVisualPreview';
import LoginVisualPreview from './components/LoginVisualPreview';
import DealerRegistrationPreview from './components/DealerRegistrationPreview';
import './styles.css';import'./workspace-polish.css';import'./login-preview.css';import'./dealer-mobile-fix.css';import'./premium-ui.css';import'./compact-cloud-ui.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
const root=document.getElementById('torvo-v2-root');if(!root)throw new Error('TORVO V2 preview root not found');
const visual=new URLSearchParams(window.location.search).get('visual')?.toLowerCase()||'home';
const Preview=visual==='admin'?AdminVisualPreview:visual==='login'?LoginVisualPreview:visual==='register'?DealerRegistrationPreview:DealerVisualPreview;
const links=[['home','HOME'],['login','LOGIN'],['register','DEALER REGISTER'],['admin','ADMIN DEMO']];
const build=(import.meta.env.VITE_BUILD_SHA||'LOCAL').slice(0,8).toUpperCase();
function Switcher(){return <div style={{position:'fixed',right:'8px',bottom:'8px',zIndex:9999,display:'grid',gap:'4px',padding:'5px',borderRadius:'12px',background:'rgba(17,17,17,.94)',boxShadow:'0 8px 30px #0005',maxWidth:'calc(100vw - 16px)'}}><div style={{display:'flex',gap:'4px',overflowX:'auto'}}>{links.map(([id,label])=><button key={id} onClick={()=>{const u=new URL(location.href);id==='home'?u.searchParams.delete('visual'):u.searchParams.set('visual',id);location.href=u.toString()}} style={{border:0,borderRadius:'8px',padding:'7px 8px',whiteSpace:'nowrap',fontSize:'9px',fontWeight:900,background:visual===id||visual==='home'&&id==='home'?'#d71920':'#fff',color:visual===id||visual==='home'&&id==='home'?'#fff':'#111'}}>{label}</button>)}</div><span style={{textAlign:'right',fontSize:'8px',fontWeight:800,letterSpacing:'.5px',color:'#ddd'}}>PREVIEW BUILD · {build}</span></div>}
function PreviewRoot(){useEffect(()=>installGlobalUiFeedback(),[]);return <><Preview/><Switcher/></>};createRoot(root).render(<React.StrictMode><PreviewRoot/></React.StrictMode>);
