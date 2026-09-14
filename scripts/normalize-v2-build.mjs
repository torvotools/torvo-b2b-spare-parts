import{access,copyFile,rm,writeFile}from'node:fs/promises';
const source='dist/v2-preview.html',target='dist/index.html';
await access(source);await copyFile(source,target);await rm(source);
const sha=String(process.env.VITE_BUILD_SHA||process.env.GITHUB_SHA||'LOCAL').trim();
const branch=String(process.env.GITHUB_REF_NAME||'LOCAL').trim();
await writeFile('dist/torvo-build-sha.txt',sha,'utf8');
await writeFile('dist/torvo-build-manifest.json',JSON.stringify({app:'TORVO V2',branch,commit_sha:sha,built_at_utc:new Date().toISOString()},null,2)+'\n','utf8');
console.log(`TORVO V2 BUILD READY: dist/index.html [${sha}]`);
