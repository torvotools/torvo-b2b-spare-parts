import React,{useEffect} from 'react';
import { createRoot } from 'react-dom/client';
import DealerVisualPreview from './components/DealerVisualPreview';
import AdminVisualPreview from './components/AdminVisualPreview';
import LoginVisualPreview from './components/LoginVisualPreview';
import './styles.css';
import './workspace-polish.css';
import {installGlobalUiFeedback} from './services/uiFeedback.js';

const root = document.getElementById('torvo-v2-root');
if (!root) throw new Error('TORVO V2 preview root not found');
const visual=new URLSearchParams(window.location.search).get('visual')?.toLowerCase();
const Preview=visual==='admin'?AdminVisualPreview:visual==='login'?LoginVisualPreview:DealerVisualPreview;
function PreviewRoot(){useEffect(()=>installGlobalUiFeedback(),[]);return <Preview/>}
createRoot(root).render(<React.StrictMode><PreviewRoot/></React.StrictMode>);
