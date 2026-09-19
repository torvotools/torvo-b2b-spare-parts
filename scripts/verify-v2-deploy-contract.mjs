import{readFile}from'node:fs/promises';
const [normalize,wrangler,worker,workflow,buildWorkflow,androidWorkflow,releaseGates]=await Promise.all([
  readFile('scripts/normalize-v2-build.mjs','utf8'),readFile('wrangler.jsonc','utf8'),readFile('src/v2/cloudflare-worker.js','utf8'),readFile('.github/workflows/v2-cloudflare-preview.yml','utf8'),readFile('.github/workflows/v2-build-check.yml','utf8'),readFile('.github/workflows/v2-android-apk.yml','utf8'),readFile('docs/TORVO-V2-RELEASE-GATES.md','utf8')
]);
const previewUrl='https://torvo-b2b-spare-parts.torvotools.workers.dev';
const prStart=buildWorkflow.indexOf('  pull_request:');
const prEnd=buildWorkflow.indexOf('  workflow_dispatch:',prStart);
const buildPullRequest=prStart>=0&&prEnd>prStart?buildWorkflow.slice(prStart,prEnd):'';
const prWatches=(path)=>buildPullRequest.includes(path);
const gates=[
 ['GIT SHA FALLBACK',normalize.includes("git('rev-parse','HEAD')")],
 ['LOCAL SHA FORBIDDEN',normalize.includes('BUILD SHA UNAVAILABLE')&&!normalize.includes("||'LOCAL'")],
 ['WORKER ASSET BINDING',wrangler.includes('"binding": "ASSETS"')&&wrangler.includes('cloudflare-worker.js')],
 ['EVIDENCE RUNS WORKER FIRST',wrangler.includes('/torvo-build-sha.txt')&&wrangler.includes('run_worker_first')],
 ['NO STORE EVIDENCE',worker.includes("Cache-Control',NO_STORE")&&worker.includes("X-Torvo-V2','ACTIVE")],
 ['HEAD RESPONSE SAFE',worker.includes("request.method==='HEAD'?null:response.body")],
 ['CACHE BYPASS MARKER',worker.includes("X-Torvo-Cache','BYPASS")],
 ['DEPLOY PREFLIGHT REQUIRED',workflow.includes('npm run verify:v2-preflight')],
 ['LIVE SHA VERIFY',workflow.includes('VERIFY LIVE WORKER EXACT SHA')&&workflow.includes('EXPECTED_SHA')],
 ['EXTERNAL CONFIG DETECTED',workflow.includes('DETECT EXTERNAL DEPLOY CONFIG')&&workflow.includes('MISSING VITE_SUPABASE_URL')&&workflow.includes('MISSING VITE_SUPABASE_ANON_KEY')&&workflow.includes('MISSING CLOUDFLARE_API_TOKEN')&&workflow.includes('MISSING CLOUDFLARE_ACCOUNT_ID')],
 ['BACKEND CONFIG PASSED TO BUILD',workflow.includes('BUILD EXACT V2 COMMIT')&&workflow.includes('VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}')&&workflow.includes('VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}')],
 ['LIVE DEPLOY FAILS CLOSED',workflow.includes("if: steps.deploy_config.outputs.ready == 'true'")&&workflow.includes('DEPLOY EXACT V2 COMMIT')&&workflow.includes('VERIFY LIVE WORKER EXACT SHA')],
 ['MISSING CONFIG REPORTED NOT MASKED',workflow.includes('CODE VERIFIED; LIVE DEPLOY WAITING FOR REPOSITORY CONFIG')&&workflow.includes('LIVE DEPLOY: WAITING FOR SUPABASE/CLOUDFLARE REPOSITORY CONFIG')],
 ['ONE CANONICAL PREVIEW URL',workflow.includes(previewUrl+'/torvo-build-sha.txt')&&workflow.includes(previewUrl+'/torvo-build-manifest.json')],
 ['PREVIEW URL ONLY REPORTED AFTER LIVE SHA',workflow.includes('LIVE PREVIEW: '+previewUrl)&&workflow.indexOf('LIVE PREVIEW: '+previewUrl)>workflow.indexOf('test "$LIVE_SHA" = "$EXPECTED_SHA"')],
 ['PREVIEW CONFIG EVIDENCE AFTER SHA VERIFY',workflow.includes('LIVE CONFIG: SUPABASE + CLOUDFLARE READY')&&workflow.indexOf('LIVE CONFIG: SUPABASE + CLOUDFLARE READY')>workflow.indexOf('test "$LIVE_SHA" = "$EXPECTED_SHA"')],
 ['DOMAIN CUTOVER REQUIRES ACCEPTANCE',releaseGates.includes('DO NOT SWITCH `torvotools.com` UNTIL STAGING')&&releaseGates.includes('BACKUP/RESTORE')&&releaseGates.includes('OWNER ACCEPTANCE')],
 ['DOMAIN DNS EXTERNAL DEPENDENCY',releaseGates.includes('DOMAIN/DNS')&&releaseGates.includes('FINAL DEPLOYMENT DEPENDENCIES')],['CLOUDFLARE DOES NOT IGNORE DOC CONTRACTS',!workflow.includes("paths-ignore:\n      - 'docs/**'")],['BUILD WATCHES RESTORE CONTRACT',buildWorkflow.includes("docs/TORVO-V2-PORTABLE-RESTORE-RUNBOOK.md")&&buildWorkflow.includes("docs/TORVO-V2-RESTORE-GUIDE.md")&&buildWorkflow.includes("docs/TORVO-V2-MASTER-HANDOVER.md")],['ANDROID WATCHES RESTORE CONTRACT',androidWorkflow.includes("docs/TORVO-V2-PORTABLE-RESTORE-RUNBOOK.md")&&androidWorkflow.includes("docs/TORVO-V2-RESTORE-GUIDE.md")&&androidWorkflow.includes("docs/TORVO-V2-STAGING-ACCEPTANCE.md")],['BUILD WATCHES ENV INVENTORY',buildWorkflow.includes("docs/TORVO-V2-ENVIRONMENT-INVENTORY.md")],['ANDROID WATCHES ENV INVENTORY',androidWorkflow.includes("docs/TORVO-V2-ENVIRONMENT-INVENTORY.md")],['BUILD WATCHES FINAL ACCEPTANCE CONTRACTS',buildWorkflow.includes("docs/TORVO-V2-PUBLIC-WEB-APP-ARCHITECTURE.md")&&buildWorkflow.includes("docs/TORVO-V2-FINAL-DEMO-RUNBOOK.md")&&buildWorkflow.includes("docs/TORVO-V2-OWNER-REQUIREMENTS-LOCK.md")],['ANDROID WATCHES FINAL ACCEPTANCE CONTRACTS',androidWorkflow.includes("docs/TORVO-V2-PUBLIC-WEB-APP-ARCHITECTURE.md")&&androidWorkflow.includes("docs/TORVO-V2-FINAL-DEMO-RUNBOOK.md")&&androidWorkflow.includes("docs/TORVO-V2-OWNER-REQUIREMENTS-LOCK.md")],
 ['BUILD PR WATCHES ENV INVENTORY',prWatches("docs/TORVO-V2-ENVIRONMENT-INVENTORY.md")],
 ['BUILD PR WATCHES FINAL ACCEPTANCE CONTRACTS',prWatches("docs/TORVO-V2-PUBLIC-WEB-APP-ARCHITECTURE.md")&&prWatches("docs/TORVO-V2-FINAL-DEMO-RUNBOOK.md")&&prWatches("docs/TORVO-V2-OWNER-REQUIREMENTS-LOCK.md")],
 ['BUILD PR WATCHES FINAL EVIDENCE',prWatches("docs/TORVO-V2-FINAL-ACCEPTANCE-EVIDENCE.md")]
];
let failed=false;for(const[name,ok]of gates){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed=true;}if(failed)process.exit(1);console.log(`TORVO V2 DEPLOY CONTRACT VERIFIED (${gates.length} GATES)`);
