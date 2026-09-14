import fs from 'node:fs';
const css=fs.readFileSync('src/v2/accountant-search-v2.css','utf8');
const component=fs.readFileSync('src/v2/components/AccountantVisualPreview.jsx','utf8');
const checks=[
 ['DESKTOP ADMIN GRID',css.includes('grid-template-columns:minmax(118px,155px) minmax(720px,1fr) auto!important')],
 ['LARGE DESKTOP ADMIN GRID',css.includes('grid-template-columns:150px minmax(900px,1fr) auto!important')],
 ['COMPACT DESKTOP ADMIN GRID',css.includes('grid-template-columns:110px minmax(480px,1fr) auto!important')],
 ['ADMIN SEARCH ICON WIDTH',css.includes('width:46px!important;min-width:46px!important')],
 ['ADMIN SEARCH HEIGHT',css.includes('height:44px!important;min-height:44px!important')],
 ['ADMIN FILTER Y POSITION',css.includes('top:48px!important;height:27px!important')],
 ['ADMIN FILTER PANEL Y POSITION',css.includes('.accountantFilterPanel{top:77px')],
 ['ADMIN BELL HOVER',css.includes('.accountantBell:hover,.accountantBell:focus-visible')],
 ['ADMIN TITLE WIDTH',css.includes('max-width:155px!important')&&css.includes('max-width:110px!important')],
 ['SHARED ADMIN SEARCH MARKUP',component.includes('adminUniversalSearch')&&component.includes('adminUniversalBar')],
 ['SHARED ADMIN FILTER MARKUP',component.includes('adminFilterToggle accountantFilterToggle')],
 ['SHARED ADMIN BELL MARKUP',component.includes('iconBtn accountantBell')]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}if(bad){console.error(`ACCOUNTANT ADMIN PARITY FAILED: ${bad}`);process.exit(1)}console.log('TORVO V2 ACCOUNTANT HEADER MATCHES ADMIN GEOMETRY');
