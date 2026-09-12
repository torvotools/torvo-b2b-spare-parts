import React,{useEffect} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.jsx';
import './styles.css';
import './workspace-polish.css';
import './app-install-ui.css';
import './backup-ui.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
import {installAppFoundation} from './services/appInstall.js';
const root=document.getElementById('torvo-v2-root');
if(!root) throw new Error('TORVO V2 root element is missing');
function V2Root(){useEffect(()=>{const stopFeedback=installGlobalUiFeedback();const stopInstall=installAppFoundation();return()=>{stopFeedback?.();stopInstall?.()}},[]);return <App/>}
createRoot(root).render(<React.StrictMode><V2Root/></React.StrictMode>);
