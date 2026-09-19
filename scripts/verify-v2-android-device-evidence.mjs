import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-android-device-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
const req=['package_id','channel','production_signed','commit_sha','apk_sha256','device_model','android_version','tested_at_utc','tester','apk_installed','app_opened','login_logout_revoke_checked','screenshots_recorded'];
for(const k of req)if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(e.package_id!=='com.torvotools.app')fail('wrong package');
if(e.channel!=='TEST-DEBUG'||e.production_signed!==false)fail('real-device evidence must be TEST-DEBUG, not production');
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^[a-f0-9]{64}$/i.test(e.apk_sha256))fail('invalid APK SHA256');
for(const k of ['apk_installed','app_opened','login_logout_revoke_checked','screenshots_recorded'])if(e[k]!==true)fail(k+' is not true');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.tested_at_utc))fail('tested_at_utc must be ISO timestamp');
console.log('PASS TORVO V2 ANDROID REAL-DEVICE EVIDENCE STRUCTURE');
console.log('commit_sha='+e.commit_sha);console.log('apk_sha256='+e.apk_sha256);
console.log('NOTE: this validates recorded evidence structure; it does not fabricate or independently perform the physical device test');
