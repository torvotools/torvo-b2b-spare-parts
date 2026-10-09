import fs from'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-acceptance-bundle.mjs <bundle.json>');
let b;try{b=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid bundle JSON')}
for(const k of ['environment_project_id','accepted_commit_sha','captured_at_utc','evidence'])if(b[k]===undefined||b[k]===null||b[k]==='')fail('missing '+k);
if(b.environment_project_id!=='jvmhhngjlaqrfopfavur')fail('acceptance bundle must be staging');
if(!/^[a-f0-9]{40}$/i.test(b.accepted_commit_sha))fail('invalid accepted_commit_sha');
if(!/^\d{4}-\d{2}-\d{2}T/.test(b.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
if(!Number.isFinite(Date.parse(b.captured_at_utc))||!/(Z|[+-]\d{2}:\d{2})$/.test(b.captured_at_utc)||Date.parse(b.captured_at_utc)>Date.now()+300000)fail('captured_at_utc must be valid, timezone-aware and not in the future');
const required=['auth','b2b','inventory','returns','reports','catalog','restore','android_device'];
for(const name of required){const e=b.evidence?.[name];if(!e||typeof e!=='object')fail('missing evidence '+name);if(e.status!=='PASS')fail(name+' status must be PASS');if(e.commit_sha!==b.accepted_commit_sha)fail(name+' commit SHA mismatch');if(e.environment_project_id&&e.environment_project_id!==b.environment_project_id)fail(name+' environment mismatch');if(!e.evidence_ref)fail(name+' evidence_ref missing');const ref=String(e.evidence_ref).trim();if(ref.length<3||ref.toUpperCase().includes('REPLACE_WITH'))fail(name+' evidence_ref must be real non-placeholder evidence')}
if(b.evidence.android_device.environment_project_id&&b.evidence.android_device.environment_project_id!==b.environment_project_id)fail('android device environment mismatch');
if(b.owner_final_acceptance===true)fail('staging bundle must not self-claim Owner final production acceptance');
console.log('PASS TORVO V2 ACCEPTANCE BUNDLE CONSISTENCY');console.log('accepted_commit_sha='+b.accepted_commit_sha);console.log('environment_project_id='+b.environment_project_id);
console.log('NOTE: consistency PASS only; referenced evidence must independently pass its dedicated verifier and this script creates no runtime evidence');
