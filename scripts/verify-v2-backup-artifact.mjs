import fs from 'node:fs';
import crypto from 'node:crypto';

const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,manifestPath,artifactPath]=process.argv;
if(!manifestPath||!artifactPath) fail('usage: node scripts/verify-v2-backup-artifact.mjs <manifest.json> <artifact>');
if(!fs.existsSync(manifestPath)||!fs.existsSync(artifactPath)) fail('manifest/artifact missing');
let m;try{m=JSON.parse(fs.readFileSync(manifestPath,'utf8'))}catch{fail('manifest is not valid JSON')}
const required=['backup_run_id','schema_version','database_version','code_branch','code_commit','checksum_sha256','artifact_reference','encrypted','includes_secrets'];
for(const k of required) if(m[k]===undefined||m[k]===null||m[k]==='') fail('manifest missing '+k);
for(const k of ['backup_run_id','schema_version','database_version','artifact_reference']){const v=String(m[k]).trim();if(v.length<2||v.toUpperCase().includes('REPLACE_WITH'))fail(k+' must be real non-placeholder evidence');}
if(m.code_branch!=='torvo-v2-build') fail('wrong code branch');
if(!/^[a-f0-9]{40}$/i.test(m.code_commit)) fail('invalid exact commit SHA');
if(!/^[a-f0-9]{64}$/i.test(m.checksum_sha256)) fail('invalid SHA256');
if(/^0{64}$/i.test(m.checksum_sha256)) fail('checksum_sha256 cannot be placeholder');
if(m.encrypted!==true) fail('artifact is not declared encrypted');
if(m.includes_secrets!==false) fail('manifest does not exclude secrets');
const bytes=fs.readFileSync(artifactPath);
if(!Number.isSafeInteger(m.file_size_bytes)||m.file_size_bytes<=0) fail('manifest file_size_bytes must be a positive safe integer');
if(bytes.length!==m.file_size_bytes) fail('artifact byte size differs from manifest');
if(!bytes.length) fail('artifact is empty');
const actual=crypto.createHash('sha256').update(bytes).digest('hex');
if(actual!==String(m.checksum_sha256).toLowerCase()) fail('artifact SHA256 mismatch');
const forbidden=/(service[_-]?role|password|otp[_-]?secret|signing[_-]?key|private[_-]?key|provider[_-]?secret)/i;
const manifestText=JSON.stringify(m);
if(forbidden.test(manifestText)) fail('manifest contains a forbidden secret-like field/name');
console.log('PASS TORVO V2 BACKUP ARTIFACT INTEGRITY');
console.log('backup_run_id='+m.backup_run_id);
console.log('code_commit='+m.code_commit);
console.log('sha256='+actual);
console.log('bytes='+bytes.length);
console.log('NOTE: integrity PASS is not restore-rehearsal PASS');
