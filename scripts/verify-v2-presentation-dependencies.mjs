import fs from 'node:fs';
const entryPath='src/v2/preview-main.jsx';
const entry=fs.readFileSync(entryPath,'utf8');
const canonical=['torvo-component-contract.css','torvo-operational-ui.css','torvo-ai-integration-ui.css','torvo-ui-system.css'];
const retired=['workspace-polish.css','dealer-mobile-fix.css','premium-ui.css','compact-cloud-ui.css','secure-desktop-lock.css','live-responsive-hotfix.css','public-desktop-final.css'];
const structural=['styles.css','login-preview.css','purchase-requirements-ui.css','public-website.css','public-product-showcase.css','public-catalog-browser.css','smart-search-ui.css','smart-product-filters.css','role-app-preview.css','admin-desktop-polish.css','admin-search-v2.css','accountant-search-v2.css'];
const imported=[...entry.matchAll(/import\s+['"]\.\/([^'"]+\.css)['"]/g)].map(m=>m[1]);
const fail=label=>{console.error('FAIL:',label);process.exitCode=1},pass=label=>console.log('PASS:',label);
if(new Set(imported).size!==imported.length)fail('duplicate CSS imports are forbidden');else pass('no duplicate CSS imports');
for(const file of [...structural,...canonical]){if(!imported.includes(file))fail(`required presentation layer missing: ${file}`);else if(!fs.existsSync(`src/v2/${file}`))fail(`import target missing: ${file}`)}
for(const file of retired){if(imported.includes(file))fail(`retired override layer must not remain imported: ${file}`)}
const positions=canonical.map(x=>imported.indexOf(x));
if(!positions.every((v,i)=>i===0||v>positions[i-1]))fail('canonical CSS ownership order changed');else pass('canonical CSS ownership order preserved');
if(Math.min(...positions)<=Math.max(...structural.map(x=>imported.indexOf(x))))fail('canonical CSS layers must load after structural compatibility layers');else pass('authoritative design system loads after structural layers');
if(imported.at(-1)!=='torvo-ui-system.css')fail('authoritative TORVO design system must load last');else pass('authoritative TORVO design system owns final presentation');
const cleanup=fs.readFileSync('docs/TORVO-V2-PRESENTATION-CLEANUP-MAP.md','utf8');
for(const file of [...canonical,...structural,...retired])if(!cleanup.includes(file))fail(`cleanup map missing audited layer: ${file}`);
if(!process.exitCode)pass('cleanup map covers active and retired presentation layers');
if(process.exitCode)process.exit(process.exitCode);

const designConstitution=read('docs/TORVO-V2-UI-DESIGN-CONSTITUTION.md');
if(!designConstitution.includes('NO DUPLICATE UI ACTIONS')||!designConstitution.includes('REPLACE or CONSOLIDATE'))fail('owner no-duplicate UI rule missing');
pass('owner no-duplicate UI action rule locked');
console.log(`TORVO V2 presentation dependency guard passed (${imported.length} active CSS imports; ${retired.length} retired override imports blocked).`);
