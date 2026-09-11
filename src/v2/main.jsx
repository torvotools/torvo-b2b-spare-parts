import React,{useEffect} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.jsx';
import './styles.css';
import './workspace-polish.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
const root=document.getElementById('torvo-v2-root');
if(!root) throw new Error('TORVO V2 root element is missing');
function V2Root(){useEffect(()=>installGlobalUiFeedback(),[]);return <App/>}
createRoot(root).render(<React.StrictMode><V2Root/></React.StrictMode>);
