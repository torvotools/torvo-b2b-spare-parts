import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const need=k=>{const v=process.env[k];if(!v)fail(k+' is required');return v};
const runId=need('TORVO_BACKUP_RUN_ID');
const workerJobId=need('TORVO_BACKUP_WORKER_JOB_ID');
const databaseUrl=need('TORVO_BACKUP_DATABASE_URL');
const outputDir=need('TORVO_BACKUP_OUTPUT_DIR');
const encryptionKey=need('TORVO_BACKUP_ENCRYPTION_KEY');
const codeCommit=need('TORVO_BACKUP_CODE_COMMIT');
const schemaVersion=need('TORVO_BACKUP_SCHEMA_VERSION');
const databaseVersion=need('TORVO_BACKUP_DATABASE_VERSION');
const codeBranch=process.env.TORVO_BACKUP_CODE_BRANCH||'torvo-v2-build';

if(process.env.TORVO_BACKUP_ALLOW_PRODUCTION==='true')fail('production backup execution is disabled by this staging worker');
if(codeBranch!=='torvo-v2-build')fail('only torvo-v2-build is allowed');
if(!/^[a-f0-9]{40}$/i.test(codeCommit))fail('TORVO_BACKUP_CODE_COMMIT must be an exact 40-character SHA');
if(!fs.existsSync(outputDir)||!fs.statSync(outputDir).isDirectory())fail('output directory does not exist');
if(encryptionKey.length<32)fail('TORVO_BACKUP_ENCRYPTION_KEY must be at least 32 characters');
if(!/^postgres(?:ql)?:\/\//i.test(databaseUrl))fail('TORVO_BACKUP_DATABASE_URL must be a PostgreSQL connection URL');

for(const k of ['VITE_SUPABASE_ANON_KEY','VITE_SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY']){
 if(process.env[k])fail(k+' must not be used as backup worker credentials');
}

const safeId=runId.replace(/[^a-zA-Z0-9._-]/g,'_');
const dumpPath=path.join(outputDir,safeId+'.dump');
const artifactPath=path.join(outputDir,safeId+'.dump.enc');
const manifestPath=path.join(outputDir,safeId+'.manifest.json');
const cleanup=()=>{for(const p of [dumpPath])try{if(fs.existsSync(p))fs.rmSync(p,{force:true})}catch{}};

try{
 const dump=spawnSync('pg_dump',['--format=custom','--no-owner','--no-privileges','--file',dumpPath,databaseUrl],{stdio:['ignore','inherit','inherit'],env:{...process.env,PGAPPNAME:'torvo-v2-backup-worker'}});
 if(dump.error)fail('pg_dump could not start: '+dump.error.message);
 if(dump.status!==0)fail('pg_dump failed with exit code '+dump.status);
 if(!fs.existsSync(dumpPath)||fs.statSync(dumpPath).size<=0)fail('pg_dump produced an empty artifact');

 const salt=crypto.randomBytes(16);
 const iv=crypto.randomBytes(12);
 const key=crypto.scryptSync(encryptionKey,salt,32);
 const cipher=crypto.createCipheriv('aes-256-gcm',key,iv);
 const plain=fs.readFileSync(dumpPath);
 const encrypted=Buffer.concat([cipher.update(plain),cipher.final()]);
 const tag=cipher.getAuthTag();
 const envelope=Buffer.concat([Buffer.from('TORVOV2B1'),salt,iv,tag,encrypted]);
 fs.writeFileSync(artifactPath,envelope,{mode:0o600});
 cleanup();

 const bytes=fs.readFileSync(artifactPath);
 const checksum=crypto.createHash('sha256').update(bytes).digest('hex');
 const manifest={
  backup_run_id:runId,
  worker_job_id:workerJobId,
  backup_type:'full_restore_point',
  schema_version:schemaVersion,
  database_version:databaseVersion,
  code_branch:codeBranch,
  code_commit:codeCommit.toLowerCase(),
  checksum_algorithm:'SHA-256',
  checksum_sha256:checksum,
  file_size_bytes:bytes.length,
  artifact_format:'TORVOV2B1/AES-256-GCM/PG_CUSTOM',
  artifact_reference:path.basename(artifactPath),
  encrypted:true,
  includes_secrets:false,
  created_at:new Date().toISOString()
 };
 fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n',{mode:0o600});
 console.log('PASS TORVO V2 ENCRYPTED BACKUP ARTIFACT CREATED');
 console.log('run_id='+runId);
 console.log('worker_job_id='+workerJobId);
 console.log('artifact='+artifactPath);
 console.log('manifest='+manifestPath);
 console.log('sha256='+checksum);
 console.log('bytes='+bytes.length);
 console.log('NOTE: artifact creation PASS is not restore-rehearsal PASS; trusted completion RPC/provider upload remains a separate protected-runtime step.');
}catch(e){cleanup();fail(e instanceof Error?e.message:String(e))}
