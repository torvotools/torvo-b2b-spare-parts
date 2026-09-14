import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const gates=read('docs/TORVO-V2-RELEASE-GATES.md'),auth=read('supabase/functions/_shared/torvo-auth.ts'),login=read('supabase/functions/dealer-pin-login/index.ts'),staff=read('supabase/functions/staff-one-time-login/index.ts'),release=read('supabase/v2-app-release-center.sql');
const checks=[
 ['AUTH SHARED RUNTIME PRESENT',auth.includes('SUPABASE_SERVICE_ROLE_KEY')&&auth.includes('SUPABASE_URL')],
 ['DEALER LOGIN EDGE FUNCTION PRESENT',login.includes('dealer_start_device_session')],
 ['STAFF LOGIN EDGE FUNCTION PRESENT',staff.includes('staff')&&staff.includes('signIn')],
 ['RELEASE TABLE RLS ENABLED',release.includes('enable row level security')],
 ['RELEASE METADATA CLIENT WRITE CLOSED',release.includes('revoke all on table app_release_artifacts from public, anon, authenticated')],
 ['STAGING REQUIRED BEFORE LIVE',gates.includes('DEDICATED V2 STAGING DATABASE')&&gates.includes('BACKUP/RESTORE')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`RUNTIME READINESS FAILED: ${failed.length}`);process.exit(1)}console.log('TORVO V2 RUNTIME READINESS CONTRACT VERIFIED');
