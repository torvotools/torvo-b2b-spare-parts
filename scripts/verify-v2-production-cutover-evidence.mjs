import fs from'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-production-cutover-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['accepted_commit_sha','owner_acceptance_ref','staging_project_id','production_project_id','cloudflare_build_run_ref','cloudflare_preview_run_ref','backup_restore_rehearsal_ref','android_device_evidence_ref','android_production_evidence_ref','approved_at_utc'])if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(!/^[a-f0-9]{40}$/i.test(e.accepted_commit_sha))fail('invalid accepted_commit_sha');
if(e.staging_project_id!=='jvmhhngjlaqrfopfavur')fail('wrong staging project');
if(e.production_project_id!=='gckafjiitjocodlrwanm')fail('wrong production project');
if(e.staging_project_id===e.production_project_id)fail('staging and production must remain separate');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.approved_at_utc))fail('approved_at_utc must be ISO timestamp');
for(const k of ['staging_runtime_gates_passed','exact_sha_build_passed','exact_sha_cloudflare_passed','backup_restore_passed','android_real_device_passed','android_production_release_passed','catalog_permanent_delete_runtime_passed','production_backup_ready','owner_explicit_cutover_approval'])if(e[k]!==true)fail(k+' is not true');
if(e.production_migrations_applied===true||e.domain_dns_cutover_completed===true||e.post_cutover_smoke_passed===true)fail('pre-cutover evidence must not claim production mutation/cutover already completed');
console.log('PASS TORVO V2 PRE-PRODUCTION CUTOVER EVIDENCE');console.log('accepted_commit_sha='+e.accepted_commit_sha);console.log('owner_acceptance_ref='+e.owner_acceptance_ref);
console.log('NOTE: this is a pre-cutover authorization evidence check only; it does not mutate production, DNS, domains or deployment state');
