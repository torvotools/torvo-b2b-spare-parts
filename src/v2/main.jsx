import React,{useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.jsx';
import BackupCloseModal from './components/BackupCloseModal.jsx';
import './styles.css';
import './workspace-polish.css';
import './app-install-ui.css';
import './backup-ui.css';
import './backup-close-ui.css';
import './dealer-addon-ui.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';
import {installAppFoundation} from './services/appInstall.js';
import {forceSignOut} from './services/auth.js';
const root=document.getElementById('torvo-v2-root');
if(!root) throw new Error('TORVO V2 root element is missing');
function V2Root(){const[backupClose,setBackupClose]=useState(false);useEffect(()=>{const stopFeedback=installGlobalUiFeedback();const stopInstall=installAppFoundation();const open=()=>setBackupClose(true);window.addEventListener('torvo:backup-close',open);return()=>{stopFeedback?.();stopInstall?.();window.removeEventListener('torvo:backup-close',open)}},[]);const finish=async()=>{await forceSignOut();setBackupClose(false)};return <><App/><BackupCloseModal open={backupClose} onCancel={()=>setBackupClose(false)} onSignOut={finish}/></>}
createRoot(root).render(<React.StrictMode><V2Root/></React.StrictMode>);
