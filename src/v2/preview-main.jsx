import React,{useEffect} from 'react';
import {createRoot} from 'react-dom/client';
import PublicWebsitePreview from './components/PublicWebsitePreview';
import RoleAppPreview from './components/RoleAppPreview';
import AdminVisualPreview from './components/AdminVisualPreview';
import AccountantVisualPreview from './components/AccountantVisualPreview';
import LoginVisualPreview from './components/LoginVisualPreview';
import DealerRegistrationPreview from './components/DealerRegistrationPreview';
import './styles.css';import './workspace-polish.css';import './login-preview.css';import './dealer-mobile-fix.css';import './premium-ui.css';import './compact-cloud-ui.css';import './admin-desktop-polish.css';import './public-website.css';import './public-mobile-fix.css';import './public-product-showcase.css';import './public-catalog-browser.css';import './smart-search-ui.css';import './smart-product-filters.css';import './role-app-preview.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
const root=document.getElementById('torvo-v2-root');if(!root)throw new Error('TORVO V2 preview root not found');
const params=new URLSearchParams(window.location.search);const visual=(params.get('visual')||'website').toLowerCase();
function Preview(){if(visual==='admin'||visual==='desktop')return <AdminVisualPreview/>;if(visual==='accountant')return <AccountantVisualPreview/>;if(visual==='login')return <LoginVisualPreview/>;if(visual==='register')return <DealerRegistrationPreview/>;if(visual==='salesman')return <RoleAppPreview role="salesman"/>;if(visual==='store')return <RoleAppPreview role="store"/>;if(visual==='app'||visual==='dealer')return <RoleAppPreview role="dealer"/>;return <PublicWebsitePreview/>}
const links=[['website','WEBSITE'],['dealer','DEALER APP'],['salesman','SALESMAN APP'],['store','STORE APP'],['accountant','ACCOUNTANT DESKTOP'],['admin','ADMIN DESKTOP']];const build=(import.meta.env.VITE_BUILD_SHA||'LOCAL').slice(0,8).toUpperCase();
function Switcher(){return <div className="previewSwitcher"><div className="previewSwitcherButtons">{links.map(([id,label])=><button key={id} onClick={()=>{const u=new URL(location.href);id==='website'?u.searchParams.delete('visual'):u.searchParams.set('visual',id);location.href=u.toString()}} className={(visual===id)||(visual==='website'&&id==='website')?'active':''}>{label}</button>)}</div><span>PREVIEW BUILD · {build}</span></div>}
function PreviewRoot(){useEffect(()=>installGlobalUiFeedback(),[]);return <><Preview/><Switcher/></>};createRoot(root).render(<React.StrictMode><PreviewRoot/></React.StrictMode>);
