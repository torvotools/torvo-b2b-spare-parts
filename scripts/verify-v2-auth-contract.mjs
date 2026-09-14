import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const pin=read('supabase/v2-dealer-pin-auth.sql'),missing=read('supabase/v2-dealer-missing-part-request.sql'),staff=read('src/v2/services/staffAuth.js'),session=read('src/v2/services/dealerSession.js'),app=read('src/v2/App.jsx');
const checks=[
 ['ONE ACTIVE DEALER DEVICE INDEX',pin.includes('uq_dealer_one_active_device')&&pin.includes('where revoked_at is null')],
 ['NEW DEVICE REVOKES OLD SESSION',pin.includes("revoke_reason='NEW_DEVICE_LOGIN'")],
 ['PIN CHANGE REVOKES SESSION',pin.includes("revoke_reason='PIN_CHANGED'")],
 ['TRUSTED SESSION FUNCTIONS PRIVATE',pin.includes('revoke all on function dealer_start_device_session')&&pin.includes('revoke all on function dealer_validate_device_session')],
 ['DEALER CLIENT STORES OPAQUE TOKEN',staff.includes('dealer_session_token')&&staff.includes('DEALER_SESSION_KEY')],
 ['APP VALIDATES DEALER DEVICE SESSION',session.includes("functions.invoke('dealer-session-valid'")&&app.includes('enforceDealerSession')],
 ['DEALER PROFILE SERVER DERIVED',missing.includes('dealer_my_profile()')&&missing.includes('auth.uid()')],
 ['AMBIGUOUS DEALER LINK REJECTED',missing.includes('DEALER LINK AMBIGUOUS')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[name,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${name}`);if(failed.length){console.error(`AUTH CONTRACT FAILED: ${failed.length} CHECK(S)`);process.exit(1)}console.log('TORVO V2 AUTH CONTRACT VERIFIED');
