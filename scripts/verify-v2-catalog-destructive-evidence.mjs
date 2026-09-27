import fs from'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-catalog-destructive-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['environment_project_id','commit_sha','captured_at_utc','actor_ref','actor_role','test_master_refs'])if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(e.environment_project_id!=='jvmhhngjlaqrfopfavur')fail('catalog destructive acceptance must be staging');
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
if(!['OWNER','ADMIN'].includes(String(e.actor_role).toUpperCase()))fail('real Owner/Admin actor required');
if(!Array.isArray(e.test_master_refs)||e.test_master_refs.length<3)fail('at least three non-secret test master references required');
{const v=String(e.actor_ref).trim();if(v.length<3||v.toUpperCase().includes('REPLACE_WITH'))fail('actor_ref must be real non-placeholder evidence');}
for(const [i,ref] of e.test_master_refs.entries()){const v=String(ref||'').trim();if(v.length<3||v.toUpperCase().includes('REPLACE_WITH'))fail('test_master_refs['+i+'] must be real non-placeholder evidence');}
if(new Set(e.test_master_refs.map(x=>String(x).trim())).size!==e.test_master_refs.length)fail('test_master_refs must be distinct');
for(const k of ['permanent_delete_rpc_installed','public_execute_denied','anon_execute_denied','browser_direct_write_denied','wrong_confirmation_rejected','not_in_trash_rejected','in_use_master_rejected','zero_usage_trashed_master_deleted','deleted_master_absent_after_call','audit_log_or_test_record_captured'])if(e[k]!==true)fail(k+' is not true');
console.log('PASS TORVO V2 CATALOG DESTRUCTIVE RUNTIME EVIDENCE');console.log('commit_sha='+e.commit_sha);console.log('actor_role='+e.actor_role);
console.log('NOTE: this validates supplied real staging destructive-test evidence; it does not execute catalog deletion itself');
