import React from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.jsx';
import './styles.css';
import './workspace-polish.css';
const root=document.getElementById('torvo-v2-root');
if(!root) throw new Error('TORVO V2 root element is missing');
createRoot(root).render(<React.StrictMode><App/></React.StrictMode>);
