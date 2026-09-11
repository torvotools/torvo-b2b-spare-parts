import React from 'react';
import { createRoot } from 'react-dom/client';
import DealerVisualPreview from './components/DealerVisualPreview';
import './styles.css';
import './workspace-polish.css';

const root = document.getElementById('torvo-v2-root');

if (!root) {
  throw new Error('TORVO V2 preview root not found');
}

createRoot(root).render(
  <React.StrictMode>
    <DealerVisualPreview />
  </React.StrictMode>
);
