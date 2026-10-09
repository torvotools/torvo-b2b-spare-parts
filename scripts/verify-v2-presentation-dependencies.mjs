import fs from 'node:fs';
const entryPaths=['src/v2/preview-main.jsx','src/v2/main.jsx'];
const entries=entryPaths.map(path=>({path,content:fs.readFileSync(path,'utf8')}));
const cssImports=content=>[...content.matchAll(/import\s+['"]\.\/([^'"]+\.css)['"]/g)].map(m=>m[1]);
const canonical=['torvo-component-contract.css','torvo-operational-ui.css','torvo-ai-integration-ui.css','torvo-design-foundation.css'];
const retired=['torvo-ui-system.css','workspace-polish.css','dealer-mobile-fix.css','premium-ui.css','compact-cloud-ui.css','secure-desktop-lock.css','live-responsive-hotfix.css','public-desktop-final.css','dealer-search-lock.css','final-ui-balance.css','dealer-rewards-ui.css','login-ui.css','admin-desktop-polish.css','admin-search-v2.css','accountant-search-v2.css'];
const runtimeSourcePaths=[];
const collectRuntimeSources=dir=>{for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const path=dir+'/'+entry.name;if(entry.isDirectory())collectRuntimeSources(path);else if(/\.(?:js|jsx|mjs)$/.test(entry.name))runtimeSourcePaths.push(path)}};
collectRuntimeSources('src/v2');
const runtimeSourceContent=runtimeSourcePaths.map(path=>({path,content:fs.readFileSync(path,'utf8')}));
const structural=['styles.css','login-preview.css','purchase-requirements-ui.css','public-website.css','public-product-showcase.css','public-catalog-browser.css','smart-search-ui.css','smart-product-filters.css','role-app-preview.css','accountant-admin-parity-fix.css'];
const previewImported=cssImports(entries[0].content);
const appImported=cssImports(entries[1].content);
const imported=previewImported;
// Every shared visual surface must inherit the same structural-to-canonical cascade.
// Additional native-only structural layers are permitted, but none may override
// the final TORVO design foundation or reorder shared styles between entrypoints.
const sharedLayers=previewImported.filter(file=>appImported.includes(file));
const appSharedLayers=appImported.filter(file=>previewImported.includes(file));
if(JSON.stringify(sharedLayers)!==JSON.stringify(appSharedLayers)){
  console.error('FAIL: public preview and native app disagree on shared CSS cascade order');
  process.exitCode=1;
}else console.log('PASS: public preview and native app share one CSS cascade order');
const fail=label=>{console.error('FAIL:',label);process.exitCode=1},pass=label=>console.log('PASS:',label);
if(new Set(imported).size!==imported.length)fail('duplicate CSS imports are forbidden');else pass('no duplicate CSS imports');
if(new Set(appImported).size!==appImported.length)fail('duplicate CSS imports are forbidden in app entry');else pass('no duplicate CSS imports in app entry');
for(const file of retired){
  for(const {path,content} of entries)if(cssImports(content).includes(file))fail(`retired override layer must not remain imported by ${path}: ${file}`);
}for(const {path,content} of entries){
  for(const file of cssImports(content))if(!fs.existsSync(`src/v2/${file}`))fail(`CSS import target missing from ${path}: ${file}`);
}
for(const file of retired){
  for(const {path,content} of runtimeSourceContent)if(content.includes(file))fail(`retired presentation layer referenced by runtime source ${path}: ${file}`);
}
pass(`full src/v2 runtime graph blocks retired presentation layers (${runtimeSourcePaths.length} JS/JSX/MJS files scanned)`);
for(const file of retired){if(fs.existsSync(`src/v2/${file}`))pass(`retired presentation file kept as non-runtime archive: ${file}`)}
pass('retired presentation layers are disconnected from both runtime entrypoints and runtime source references');

for(const file of canonical){
  if(!appImported.includes(file))fail(`canonical presentation layer missing from app entry: ${file}`);
}
const appCanonicalPositions=canonical.map(x=>appImported.indexOf(x));
if(!appCanonicalPositions.every((v,i)=>i===0||v>appCanonicalPositions[i-1]))fail('app canonical CSS ownership order changed');else pass('app canonical CSS ownership order preserved');
if(appImported.at(-1)!=='torvo-design-foundation.css')fail('app clean TORVO design foundation must load last');else pass('app clean TORVO design foundation owns final presentation primitives');
for(const file of [...structural,...canonical]){if(!imported.includes(file))fail(`required presentation layer missing: ${file}`);else if(!fs.existsSync(`src/v2/${file}`))fail(`import target missing: ${file}`)}
for(const file of retired){if(imported.includes(file))fail(`retired override layer must not remain imported: ${file}`)}
const positions=canonical.map(x=>imported.indexOf(x));
if(!positions.every((v,i)=>i===0||v>positions[i-1]))fail('canonical CSS ownership order changed');else pass('canonical CSS ownership order preserved');
if(Math.min(...positions)<=Math.max(...structural.map(x=>imported.indexOf(x))))fail('canonical CSS layers must load after structural compatibility layers');else pass('authoritative design system loads after structural layers');
if(imported.at(-1)!=='torvo-design-foundation.css')fail('clean TORVO design foundation must load last');else pass('clean TORVO design foundation owns final presentation primitives');
const cleanup=fs.readFileSync('docs/TORVO-V2-PRESENTATION-CLEANUP-MAP.md','utf8');
for(const file of [...canonical,...structural,...retired])if(!cleanup.includes(file))fail(`cleanup map missing audited layer: ${file}`);
if(!process.exitCode)pass('cleanup map covers active and retired presentation layers');
if(process.exitCode)process.exit(process.exitCode);

const designConstitution=fs.readFileSync('docs/TORVO-V2-UI-DESIGN-CONSTITUTION.md','utf8');
if(!designConstitution.includes('NO DUPLICATE UI ACTIONS')||!designConstitution.includes('REPLACE or CONSOLIDATE'))fail('owner no-duplicate UI rule missing');
pass('owner no-duplicate UI action rule locked');
console.log(`TORVO V2 presentation dependency guard passed (${imported.length} active CSS imports; ${retired.length} retired override imports blocked).`);
