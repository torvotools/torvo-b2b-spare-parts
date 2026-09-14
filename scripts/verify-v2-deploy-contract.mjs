import{readFile}from'node:fs/promises';
const [normalize,wrangler,worker,workflow]=await Promise.all([
  readFile('scripts/normalize-v2-build.mjs','utf8'),readFile('wrangler.jsonc','utf8'),readFile('src/v2/cloudflare-worker.js','utf8'),readFile('.github/workflows/v2-cloudflare-preview.yml','utf8')
]);
const gates=[
 ['GIT SHA FALLBACK',normalize.includes("git('rev-parse','HEAD')")],
 ['LOCAL SHA FORBIDDEN',normalize.includes('BUILD SHA UNAVAILABLE')&&!normalize.includes("||'LOCAL'")],
 ['WORKER ASSET BINDING',wrangler.includes('"binding": "ASSETS"')&&wrangler.includes('cloudflare-worker.js')],
 ['EVIDENCE RUNS WORKER FIRST',wrangler.includes('/torvo-build-sha.txt')&&wrangler.includes('run_worker_first')],
 ['NO STORE EVIDENCE',worker.includes("Cache-Control',NO_STORE")&&worker.includes("X-Torvo-V2','ACTIVE")],
 ['HEAD RESPONSE SAFE',worker.includes("request.method==='HEAD'?null:response.body")],
 ['CACHE BYPASS MARKER',worker.includes("X-Torvo-Cache','BYPASS")],
 ['LIVE SHA VERIFY',workflow.includes('VERIFY LIVE WORKER EXACT SHA')&&workflow.includes('EXPECTED_SHA')],
 ['PREVIEW BACKEND CONFIG REQUIRED',workflow.includes('VERIFY PREVIEW BACKEND CONFIG')&&workflow.includes('secrets.VITE_SUPABASE_URL')&&workflow.includes('secrets.VITE_SUPABASE_ANON_KEY')],
 ['BACKEND CONFIG PASSED TO BUILD',workflow.includes('BUILD EXACT V2 COMMIT')&&workflow.includes('VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}')&&workflow.includes('VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}')]
];
let failed=false;for(const[name,ok]of gates){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed=true;}
if(failed)process.exit(1);console.log(`TORVO V2 DEPLOY CONTRACT VERIFIED (${gates.length} GATES)`);
