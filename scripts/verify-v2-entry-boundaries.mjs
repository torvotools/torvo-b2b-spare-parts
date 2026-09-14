import fs from'node:fs';
const r=p=>fs.readFileSync(p,'utf8');
const previewConfig=r('vite.v2-preview.config.js');
const previewHtml=r('v2-preview.html');
const previewMain=r('src/v2/preview-main.jsx');
const appConfig=r('vite.app.config.js');
const appHtml=r('v2.html');
const appMain=r('src/v2/main.jsx');
const normalize=r('scripts/normalize-v2-build.mjs');
const gates=[
 ['PUBLIC BUILD INPUT',previewConfig.includes("'v2-preview.html'")],
 ['PUBLIC ENTRY ONLY',previewHtml.includes('/src/v2/preview-main.jsx')&&!previewHtml.includes('/src/v2/main.jsx')],
 ['PUBLIC MANAGED WEBSITE',previewMain.includes('PublicWebsitePreview')&&previewMain.includes('PublicManagedLinks')],
 ['NATIVE BUILD INPUT',appConfig.includes("'v2.html'")&&appConfig.includes("outDir:'dist-app'")),
 ['NATIVE ENTRY ONLY',appHtml.includes('/src/v2/main.jsx')&&!appHtml.includes('/src/v2/preview-main.jsx')],
 ['NATIVE SECURE APP',appMain.includes("import App from './App.jsx'")],
 ['PUBLIC NORMALIZATION',normalize.includes("const source='dist/v2-preview.html',target='dist/index.html'")&&normalize.includes("await copyFile(source,target)")),
 ['PUBLIC BUILD STAMP',normalize.includes('torvo-build-sha.txt')&&normalize.includes('torvo-build-manifest.json')),
 ['BOUNDARIES SEPARATE',!previewConfig.includes('vite.app.config.js')&&!appConfig.includes('v2-preview.html'))
];
let bad=0;for(const[n,v]of gates){console.log(`${v?'PASS':'FAIL'} ${n}`);if(!v)bad++}
if(bad)process.exit(1);
console.log(`TORVO V2 ENTRY BOUNDARIES VERIFIED (${gates.length} GATES)`);
