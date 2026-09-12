import React,{useEffect} from 'react';
import {createRoot} from 'react-dom/client';
import DealerVisualPreview from './components/DealerVisualPreview';
import AdminVisualPreview from './components/AdminVisualPreview';
import LoginVisualPreview from './components/LoginVisualPreview';
import DealerRegistrationPreview from './components/DealerRegistrationPreview';
import './styles.css';import'./workspace-polish.css';import'./login-preview.css';import'./dealer-mobile-fix.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
const root=document.getElementById('torvo-v2-root');if(!root)throw new Error('TORVO V2 preview root not found');
const visual=new URLSearchParams(window.location.search).get('visual')?.toLowerCase()||'home';
const Preview=visual==='admin'?AdminVisualPreview:visual==='login'?LoginVisualPreview:visual==='register'?DealerRegistrationPreview:DealerVisualPreview;
const links=[['home','HOME'],['login','LOGIN'],['register','DEALER REGISTER'],['admin','ADMIN DEMO']];
function Switcher(){return <div style={{position:'fixed',right:'10px',bottom:'10px',zIndex:9999,display:'flex',gap:'5px',padding:'6px',borderRadius:'14px',background:'rgba(17,17,17,.94)',boxShadow:'0 8px 30px #0005',maxWidth:'calc(100vw - 20px)',overflowX:'auto'}}>{links.map(([id,label])=><button key={id} onClick={()=>{const u=new URL(location.href);id==='home'?u.searchParams.delete('visual'):u.searchParams.set('visual',id);location.href=u.toString()}} style={{border:0,borderRadius:'9px',padding:'9px 10px',whiteSpace:'nowrap',fontSize:'10px',fontWeight:900,background:visual===id||visual==='home'&&id==='home'?'#d71920':'#fff',color:visual===id||visual==='home'&&id==='home'?'#fff':'#111'}}>{label}</button>)}</div>}
function PreviewRoot(){useEffect(()=>installGlobalUiFeedback(),[]);return <><Preview/><Switcher/></>};createRoot(root).render(<React.StrictMode><PreviewRoot/></React.StrictMode>);
