import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-auth-runtime-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['environment_project_id','commit_sha','captured_at_utc','dealer','staff'])if(e[k]===undefined||e[k]===null)fail('missing '+k);
if(e.environment_project_id!=='jvmhhngjlaqrfopfavur')fail('runtime evidence must come from TORVO V2 STAGING');
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
const d=e.dealer,s=e.staff;
for(const k of ['identity_ref','device_a_ref','device_b_ref','pin_login_succeeded','device_b_replaced_a','device_a_revoked_private_reads_failed','device_a_revoked_private_writes_failed','device_b_remained_valid','logout_or_revoke_failed_afterwards'])if(d[k]===undefined||d[k]===null||d[k]==='')fail('dealer missing '+k);
for(const k of ['identity_ref','role','approved_device_ref','email_otp_consumed_once','otp_replay_failed','unapproved_device_failed','runtime_role_boundary_passed','revoke_invalidated_session'])if(s[k]===undefined||s[k]===null||s[k]==='')fail('staff missing '+k);
if(!['SALESMAN','STORE KEEPER','ACCOUNTANT'].includes(String(s.role).toUpperCase()))fail('unsupported staff acceptance role');
for(const [scope,obj,keys] of [['dealer',d,['pin_login_succeeded','device_b_replaced_a','device_a_revoked_private_reads_failed','device_a_revoked_private_writes_failed','device_b_remained_valid','logout_or_revoke_failed_afterwards']],['staff',s,['email_otp_consumed_once','otp_replay_failed','unapproved_device_failed','runtime_role_boundary_passed','revoke_invalidated_session']]])for(const k of keys)if(obj[k]!==true)fail(scope+' '+k+' is not true');
if(String(d.identity_ref).trim().length<3||String(s.identity_ref).trim().length<3)fail('real non-secret identity references required');
console.log('PASS TORVO V2 AUTH RUNTIME EVIDENCE');
console.log('commit_sha='+e.commit_sha);console.log('dealer_identity_ref='+d.identity_ref);console.log('staff_identity_ref='+s.identity_ref);console.log('staff_role='+s.role);
console.log('NOTE: this validates supplied real staging auth evidence; it does not create users, credentials, devices or sessions');
