import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const portal=read('src/v2/components/DealerPortal.jsx'),mounted=read('src/v2/components/DealerPortalMounted.jsx'),workspace=read('src/v2/services/dealerWorkspace.js'),proc=read('src/v2/services/dealerProcurement.js'),orders=read('src/v2/services/dealerOrders.js'),missing=read('src/v2/services/dealerMissingPart.js'),sql=read('supabase/v2-dealer-workspace-device-bound.sql'),staging=read('supabase/tests/v2-dealer-auth-security-checklist.sql'),install=read('supabase/V2_INSTALL_ORDER.md');
const proof=x=>x.includes('p_device_id:proof.deviceId')&&x.includes('p_session_token:proof.token');
const checks=[
 ['DEALER WORKSPACE READ RPC DEVICE BOUND',sql.includes('dealer_assert_my_device_session')&&sql.includes('dealer_workspace_catalog')],
 ['DEALER WORKSPACE CLIENT DEVICE PROOF',proof(workspace)&&workspace.match(/assertDealerSession\(\)/g)?.length>=2],
 ['DEALER WORKSPACE MOUNT SESSION GATE',mounted.includes('assertDealerSession')&&mounted.includes('VERIFYING DEALER DEVICE')],
 ['DEALER WORKSPACE REVOKE FAIL CLOSED',mounted.includes("torvo:dealer-session-revoked")&&mounted.includes("torvo:dealer-session-ended")],
 ['DEALER TAB SWITCH REVALIDATES DEVICE',mounted.includes('const changeMode=async')&&mounted.includes('await assertDealerSession()')],
 ['PROCUREMENT CLIENT DEVICE PROOF',proof(proc)],
 ['ORDER CLIENT DEVICE PROOF',proof(orders)],
 ['MISSING PART CLIENT DEVICE PROOF',proof(missing)],
 ['FUNCTIONAL MISSING PART FORM MOUNTED',mounted.includes("DealerMissingPartForm")&&mounted.includes('<DealerMissingPartForm/>')],
 ['NO FAKE PHOTO UPLOAD',missing.includes('SECURE PHOTO UPLOAD IS NOT CONNECTED YET')],
 ['STAGING COVERS PRIVATE WORKSPACE',staging.includes("dealer_workspace_catalog")&&staging.includes('REVOKED DEVICE A MUST FAIL PRIVATE WORKSPACE CATALOG')],
 ['INSTALL ORDER HAS WORKSPACE BOUNDARY',install.includes('v2-dealer-workspace-device-bound.sql')],
 ['NO PUBLIC CHECKOUT ENABLEMENT',install.includes('v2-public-checkout-payment-modes.sql')&&install.includes('DO NOT ENABLE')],
 ['DEALER PORTAL DOES NOT CLAIM PUBLIC CHECKOUT',!portal.includes('PUBLIC CHECKOUT')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`FINAL READINESS CONTRACT FAILED: ${failed.length}`);process.exit(1)}console.log('TORVO V2 FINAL READINESS CONTRACT VERIFIED');
