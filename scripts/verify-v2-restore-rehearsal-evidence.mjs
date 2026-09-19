import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-restore-rehearsal-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
const req=['source_backup_run_id','restore_manifest_id','source_commit_sha','source_schema_version','source_database_version','artifact_sha256','target_project_id','target_is_production','restore_started_at_utc','restore_completed_at_utc','tester_ref','restored_commit_sha','restored_schema_version','restored_database_version'];
for(const k of req)if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
for(const k of ['source_commit_sha','restored_commit_sha'])if(!/^[a-f0-9]{40}$/i.test(e[k]))fail('invalid '+k);
if(!/^[a-f0-9]{64}$/i.test(e.artifact_sha256))fail('invalid artifact_sha256');
if(e.target_is_production!==false)fail('restore target must explicitly be non-production');
if(e.source_commit_sha!==e.restored_commit_sha)fail('restored commit does not match source manifest');
if(String(e.source_schema_version)!==String(e.restored_schema_version))fail('restored schema version mismatch');
if(String(e.source_database_version)!==String(e.restored_database_version))fail('restored database version mismatch');
for(const k of ['restore_started_at_utc','restore_completed_at_utc'])if(!/^\d{4}-\d{2}-\d{2}T/.test(e[k]))fail(k+' must be ISO timestamp');
if(Date.parse(e.restore_completed_at_utc)<=Date.parse(e.restore_started_at_utc))fail('restore completion must be after start');
const gates=['checksum_verified','restore_completed','core_schema_checked','rls_security_checked','dealer_auth_checked','staff_auth_checked','b2b_flow_checked','inventory_returns_checked','reports_reconciled','secret_values_excluded'];
for(const k of gates)if(e[k]!==true)fail(k+' is not true');
console.log('PASS TORVO V2 RESTORE REHEARSAL EVIDENCE');
console.log('source_backup_run_id='+e.source_backup_run_id);console.log('target_project_id='+e.target_project_id);console.log('commit_sha='+e.restored_commit_sha);console.log('artifact_sha256='+e.artifact_sha256);
console.log('NOTE: this validates supplied real restore evidence; it does not perform a restore or authorize production cutover');
