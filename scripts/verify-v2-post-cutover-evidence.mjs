import fs from'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-post-cutover-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['accepted_commit_sha','production_project_id','production_domain','cloudflare_deployment_ref','production_backup_ref','cutover_approval_ref','captured_at_utc','tester_ref'])if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(!/^[a-f0-9]{40}$/i.test(e.accepted_commit_sha))fail('invalid accepted_commit_sha');
if(e.production_project_id!=='gckafjiitjocodlrwanm')fail('wrong production project');
if(e.production_domain!=='torvotools.com')fail('wrong production domain');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
for(const k of ['owner_cutover_approval_verified','production_backup_verified','production_migrations_verified','domain_dns_cutover_verified','https_verified','public_website_smoke_passed','backend_identity_verified','dealer_auth_entry_health_passed','staff_auth_entry_health_passed','app_release_metadata_verified','netlify_remains_retired','post_cutover_smoke_passed'])if(e[k]!==true)fail(k+' is not true');
if(e.deployed_commit_sha!==e.accepted_commit_sha)fail('deployed commit does not match accepted commit');
if(e.backend_project_id!==e.production_project_id)fail('backend identity does not match production project');
if(e.rollback_required===true)fail('rollback_required is true');
console.log('PASS TORVO V2 POST-CUTOVER SMOKE EVIDENCE');console.log('accepted_commit_sha='+e.accepted_commit_sha);console.log('production_domain='+e.production_domain);
console.log('NOTE: validates supplied post-cutover evidence only; it does not deploy, migrate, change DNS, touch production data or authorize cutover');
