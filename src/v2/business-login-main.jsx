import React from 'react';
import {createRoot} from 'react-dom/client';
import LoginVisualPreview from './components/LoginVisualPreview.jsx';
import './styles.css';
import './login-preview.css';
const root=document.getElementById('torvo-v2-root');
if(!root)throw new Error('TORVO Business Login root missing');
createRoot(root).render(<LoginVisualPreview/>);
