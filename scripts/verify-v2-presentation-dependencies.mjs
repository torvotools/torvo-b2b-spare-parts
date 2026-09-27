import fs from 'node:fs';

const entryPath='src/v2/preview-main.jsx';
const entry=fs.readFileSync(entryPath,'utf8');
const canonical=[
  'torvo-ui-system.css',
  'torvo-component-contract.css',
  'torvo-operational-ui.css',
  'torvo-ai-integration-ui.css'
];
const historical=[
  'styles.css','workspace-polish.css','login-preview.css','dealer-mobile-fix.css','premium-ui.css',
  'compact-cloud-ui.css','admin-desktop-polish.css','admin-search-v2.css','accountant-search-v2.css',
  'purchase-requirements-ui.css','public-website.css','public-product-showcase.css','public-catalog-browser.css',
  'smart-search-ui.css','smart-product-filters.css','role-app-preview.css','secure-desktop-lock.css',
  'live-responsive-hotfix.css','public-desktop-final.css'
];
const imported=[...entry.matchAll(/import\s+['"]\.\/([^'"]+\.css)['"]/g)].map(m=>m[1]);
const fail=(label)=>{console.error('FAIL:',label);process.exitCode=1};
const pass=(label)=>console.log('PASS:',label);

if(new Set(imported).size!==imported.length) fail('duplicate CSS imports are forbidden');
else pass('no duplicate CSS imports');

for(const file of [...historical,...canonical]){
  if(!imported.includes(file)) fail(`required audited CSS import missing: ${file}`);
  else if(!fs.existsSync(`src/v2/${file}`)) fail(`import target missing: ${file}`);
}
if(!process.exitCode) pass('all audited presentation layers exist and remain imported');

const canonicalPositions=canonical.map(x=>imported.indexOf(x));
const historicalPositions=historical.map(x=>imported.indexOf(x));
const canonicalOrdered=canonicalPositions.every((v,i)=>i===0||v>canonicalPositions[i-1]);
if(!canonicalOrdered) fail('canonical CSS ownership order changed');
else pass('canonical CSS ownership order preserved');

if(Math.min(...canonicalPositions)<=Math.max(...historicalPositions)) fail('canonical CSS layers must load after audited historical layers');
else pass('canonical layers load after historical compatibility layers');

const cleanup=fs.readFileSync('docs/TORVO-V2-PRESENTATION-CLEANUP-MAP.md','utf8');
for(const file of canonical){
  if(!cleanup.includes(file)) fail(`cleanup map missing canonical layer: ${file}`);
}
for(const file of historical){
  if(!cleanup.includes(file)) fail(`cleanup map missing audited historical layer: ${file}`);
}
if(!process.exitCode) pass('cleanup map covers current presentation chain');

if(process.exitCode) process.exit(process.exitCode);
console.log(`TORVO V2 presentation dependency guard passed (${imported.length} CSS imports).`);
