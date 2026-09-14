import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const gates=read('docs/TORVO-V2-RELEASE-GATES.md'),install=read('supabase/V2_INSTALL_ORDER.md'),pkg=JSON.parse(read('package.json'));
const checks=[
 ['V2 BRANCH LOCK DOCUMENTED',gates.includes('torvo-v2-build')&&gates.includes('V27 / MAIN IS NOT A RELEASE SOURCE')],
 ['ONE DEALER DEVICE RELEASE GATE',gates.includes('ONE DEALER ACCOUNT = ONE ACTIVE MOBILE DEVICE SESSION')],
 ['STAGING INSTALL ORDER REQUIRED',gates.includes('V2_INSTALL_ORDER.md')&&gates.includes('STOP ON FIRST SQL ERROR')],
 ['PUBLIC CHECKOUT REMAINS RETIRED',install.includes('v2-public-checkout-payment-modes.sql')&&install.includes('DO NOT ENABLE')],
 ['ANDROID DEBUG NOT PRODUCTION',gates.includes('ANDROID DEBUG APK IS TEST ONLY')&&gates.includes('SIGNED AAB/APK')],
 ['LIVE DOMAIN HELD UNTIL ACCEPTANCE',gates.includes('DO NOT SWITCH `torvotools.com`')],
 ['DEALER BUSINESS VERIFY IN BUILD',String(pkg.scripts['verify:v2-build']).includes('verify:v2-dealer-business')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`RELEASE GATES FAILED: ${failed.length}`);process.exit(1)}console.log('TORVO V2 RELEASE GATES VERIFIED');
