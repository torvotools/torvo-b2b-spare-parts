import{spawnSync}from'node:child_process';import fs from'node:fs';import path from'node:path';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,dir]=process.argv;if(!dir||!fs.existsSync(dir)||!fs.statSync(dir).isDirectory())fail('usage: node scripts/run-v2-staging-acceptance.mjs <evidence-directory>');
const jobs=[
['auth.json','scripts/verify-v2-auth-runtime-evidence.mjs'],
['b2b.json','scripts/verify-v2-b2b-flow-evidence.mjs'],
['inventory.json','scripts/verify-v2-inventory-flow-evidence.mjs'],
['returns.json','scripts/verify-v2-returns-evidence.mjs'],
['reports.json','scripts/verify-v2-report-reconciliation.mjs'],
['catalog.json','scripts/verify-v2-catalog-destructive-evidence.mjs'],
['restore.json','scripts/verify-v2-restore-rehearsal-evidence.mjs']
];
for(const [file,verifier] of jobs){const p=path.join(dir,file);if(!fs.existsSync(p))fail('missing '+file);const r=spawnSync(process.execPath,[verifier,p],{stdio:'inherit'});if(r.status!==0)fail(file+' verification failed')}
const manifest=path.join(dir,'android-release-manifest.json'),device=path.join(dir,'android-device.json');
if(!fs.existsSync(manifest)||!fs.existsSync(device))fail('missing Android manifest/device evidence');
let r=spawnSync(process.execPath,['scripts/verify-v2-android-device-evidence.mjs',manifest,device],{stdio:'inherit'});if(r.status!==0)fail('Android device evidence verification failed');
const bundle=path.join(dir,'bundle.json');if(!fs.existsSync(bundle))fail('missing bundle.json');
r=spawnSync(process.execPath,['scripts/verify-v2-acceptance-bundle.mjs',bundle],{stdio:'inherit'});if(r.status!==0)fail('acceptance bundle verification failed');
console.log('PASS TORVO V2 STAGING ACCEPTANCE EVIDENCE RUNNER');
console.log('NOTE: runner validates supplied real evidence only; it creates no users, transactions, backup artifacts, catalog deletions or physical-device evidence');
