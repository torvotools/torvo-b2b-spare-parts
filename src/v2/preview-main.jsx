import React from 'react';
import { createRoot } from 'react-dom/client';
import DealerVisualPreview from './components/DealerVisualPreview';
import AdminVisualPreview from './components/AdminVisualPreview';
import './styles.css';
import './workspace-polish.css';

const root = document.getElementById('torvo-v2-root');
if (!root) throw new Error('TORVO V2 preview root not found');
const visual=new URLSearchParams(window.location.search).get('visual')?.toLowerCase();
const Preview=visual==='admin'?AdminVisualPreview:DealerVisualPreview;
createRoot(root).render(<React.StrictMode><Preview/></React.StrictMode>);
