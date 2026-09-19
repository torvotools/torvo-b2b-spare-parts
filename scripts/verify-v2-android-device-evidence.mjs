import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,manifestPath,evidencePath]=process.argv;
if(!manifestPath||!evidencePath||!fs.existsSync(manifestPath)||!fs.existsSync(evidencePath))fail('usage: node scripts/verify-v2-android-device-evidence.mjs <release-manifest.json> <evidence.json>');
let m,e;try{m=JSON.parse(fs.readFileSync(manifestPath,'utf8'));e=JSON.parse(fs.readFileSync(evidencePath,'utf8'))}catch{fail('invalid manifest/evidence JSON')}
for(const k of ['package','channel','production_signed','commit_sha','apk_sha256','status'])if(m[k]===undefined||m[k]===null||m[k]==='')fail('release manifest missing '+k);
if(m.package!=='com.torvotools.app'||m.channel!=='TEST-DEBUG'||m.production_signed!==false||m.status!=='VERIFIED_TEST')fail('release manifest is not verified TEST-DEBUG');
if(!/^[a-f0-9]{40}$/i.test(m.commit_sha)||!/^[a-f0-9]{64}$/i.test(m.apk_sha256))fail('invalid release manifest commit/hash');
const req=['package_id','channel','production_signed','commit_sha','apk_sha256','device_model','android_version','tested_at_utc','tester','apk_installed','app_opened','login_logout_revoke_checked','screenshots_recorded'];
for(const k of req)if(e[k]===undefined||e[k]===null||e[k]==='')fail('evidence missing '+k);
if(e.package_id!==m.package)fail('device evidence package does not match release manifest');
if(e.channel!==m.channel||e.production_signed!==m.production_signed)fail('device evidence channel/signing does not match release manifest');
if(String(e.commit_sha).toLowerCase()!==String(m.commit_sha).toLowerCase())fail('device evidence commit does not match release manifest');
if(String(e.apk_sha256).toLowerCase()!==String(m.apk_sha256).toLowerCase())fail('device evidence APK SHA256 does not match release manifest');
for(const k of ['apk_installed','app_opened','login_logout_revoke_checked','screenshots_recorded'])if(e[k]!==true)fail(k+' is not true');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.tested_at_utc))fail('tested_at_utc must be ISO timestamp');
console.log('PASS TORVO V2 ANDROID REAL-DEVICE EVIDENCE');
console.log('commit_sha='+m.commit_sha);console.log('apk_sha256='+m.apk_sha256);console.log('device_model='+e.device_model);
console.log('NOTE: this cross-validates recorded physical-test evidence against the CI release manifest; it does not fabricate or independently perform the physical device test');
