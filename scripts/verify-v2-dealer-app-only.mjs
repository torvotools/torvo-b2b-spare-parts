import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const runtime=read('src/v2/services/runtimePlatform.js'),router=read('src/v2/services/experienceRouter.js'),login=read('src/v2/components/BusinessLogin.jsx'),modules=read('src/v2/config/modules.js'),release=read('docs/TORVO-V2-RELEASE-GATES.md'),staging=read('docs/TORVO-V2-STAGING-ACCEPTANCE.md');
const checks=[
 ['NATIVE PLATFORM DETECTION',runtime.includes('Capacitor.isNativePlatform()')&&runtime.includes('dealerAppRuntimeAllowed')],
 ['WEB OPERATIONAL LANDING BLOCKED',router.includes('roleRuntimeAllowed(appUser.role)')&&router.includes("['dealer','salesman','store_keeper'].includes(appUser.role)")&&router.includes('operationalAppOnlyReason(appUser.role)')],
 ['WEB LOGIN HIDES DEALER OPTION',login.includes('const native=operationalAppRuntimeAllowed()')&&login.includes('{native&&<button')&&login.includes('DEALER LOGIN IS APP-ONLY')],
 ['DEALER PIN FAILS CLOSED ON WEB',login.match(/if\(!native\)throw new Error\(dealerAppOnlyReason\(\)\)/g)?.length>=2],
 ['DEALER RECOVERY FAILS CLOSED ON WEB',login.includes("if(!native)throw new Error(dealerAppOnlyReason());const r=await requestDealerPinRecovery")],
 ['BUSINESS USE WEB ONLY',login.includes("mode={native?'staff':'business'}")&&login.includes('BUSINESS USE')],
 ['BUSINESS RULE APP ONLY',modules.includes('dealerPrivateWorkspaceAppOnly:true')&&modules.includes('dealerWebPrivateLogin:false')],
 ['RELEASE CONTRACT APP ONLY',release.includes('DEALER PRIVATE LOGIN / B2B WORKSPACE IS TORVO TOOLS NATIVE APP ONLY')&&release.includes('WEB RUNTIME MUST REJECT AN ALREADY-AUTHENTICATED DEALER SESSION')],
 ['STAGING APP ONLY ACCEPTANCE',staging.includes('DEALER APP-ONLY TEST')&&staging.includes('DEALER LOGIN OPTION MUST NOT BE OFFERED')&&staging.includes('MUST REFUSE THE PRIVATE DEALER WORKSPACE')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`TORVO APP-ONLY CONTRACT FAILED: ${failed.length}`);process.exit(1)}console.log(`TORVO V2 APP-ONLY CONTRACT VERIFIED (${checks.length} GATES)`);
