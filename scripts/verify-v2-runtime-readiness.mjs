import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const gates=read('docs/TORVO-V2-RELEASE-GATES.md'),install=read('supabase/V2_INSTALL_ORDER.md'),auth=read('supabase/functions/_shared/torvo-auth.ts'),login=read('supabase/functions/dealer-pin-login/index.ts'),staff=read('supabase/functions/staff-one-time-login/index.ts'),staffEmail=read('supabase/functions/staff-email-otp/index.ts'),release=read('supabase/v2-app-release-center.sql'),accountant=read('supabase/v2-accountant-workspace-buttons.sql'),accountantClient=read('src/v2/services/accountantWorkspace.js');
const checks=[
 ['AUTH SHARED RUNTIME PRESENT',auth.includes("Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')")&&auth.includes("Deno.env.get('SUPABASE_URL')")&&auth.includes("Deno.env.get('SUPABASE_ANON_KEY')")],
 ['DEALER LOGIN EDGE FUNCTION PRESENT',login.includes("rpc('dealer_verify_pin'")&&login.includes("rpc('dealer_start_device_session'")&&login.includes('establishSession')],
 ['STAFF LOGIN EDGE FUNCTION PRESENT',staff.includes("rpc('staff_verify_one_time_password'")&&staff.includes("rpc('staff_create_verified_session'")&&staff.includes('establishSession')],
 ['ROLE LOGIN CONTRACT DOCUMENTED',install.includes('SALESMAN / STORE KEEPER NORMAL LOGIN = ADMIN USERNAME + ONE-TIME PASSWORD')&&install.includes('ADMIN / ACCOUNTANT SECURE DESKTOP LOGIN = BOUND EMAIL ID + USER ID + SERVER-GENERATED 6-DIGIT EMAIL OTP')&&install.includes('ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION')],
 ['STAFF EMAIL OTP EDGE FUNCTION PRESENT',staffEmail.includes("rpc('staff_email_otp_begin'")&&staffEmail.includes("rpc('staff_email_otp_verify'")&&staffEmail.includes("p_login_method:'email_otp'")],
 ['AUTH ORDER BEFORE DEVICE RPCS',install.indexOf('v2-business-login-routing.sql')<install.indexOf('v2-dealer-catalog-search.sql')],
 ['EDGE FUNCTIONS AFTER AUTH DB',install.indexOf('DEPLOY AUTH EDGE FUNCTIONS')>install.indexOf('FINAL DEALER DEVICE BOUNDARIES')],
 ['RELEASE TABLE RLS ENABLED',release.includes('alter table app_release_artifacts enable row level security')],
 ['RELEASE METADATA CLIENT WRITE CLOSED',release.includes('revoke all on table app_release_artifacts from public,anon,authenticated')],
 ['RELEASE CENTER OWNER ADMIN GATED',release.includes("a.role not in('owner','admin')")&&release.includes('grant execute on function admin_app_release_center() to authenticated')],
 ['ACCOUNTANT WORKSPACE ROLE GATED',accountant.includes("v_role not in('OWNER','ADMIN','ACCOUNTANT')")&&accountant.includes('ACCOUNTANT WORKSPACE ACCESS REQUIRED')],
 ['ACCOUNTANT WORKSPACE ADMIN WRITE GATED',(accountant.match(/v_role not in\('OWNER','ADMIN'\)/g)||[]).length>=2],
 ['ACCOUNTANT WORKSPACE SOFT DISABLE',accountant.includes('admin_disable_accountant_workspace_button')&&accountant.includes('set enabled=false')],
 ['ACCOUNTANT WORKSPACE DEFAULT SIX',accountant.includes("'SALES & ESTIMATES'")&&accountant.includes("'PURCHASE'")&&accountant.includes("'PAYMENTS'")&&accountant.includes("'RETURNS'")&&accountant.includes("'LEDGER'")&&accountant.includes("'REPORTS'")],
 ['ACCOUNTANT CLIENT ADMIN DISABLE',accountantClient.includes('adminDisableAccountantWorkspaceButton')&&accountantClient.includes("rpc('admin_disable_accountant_workspace_button'")],
 ['ACCOUNTANT CLIENT ADMIN REORDER',accountantClient.includes('adminReorderAccountantWorkspaceButton')&&accountantClient.includes("direction).toUpperCase()==='UP'")&&accountantClient.includes("direction).toUpperCase()==='DOWN'")],
 ['ACCOUNTANT CLIENT ORDER STABLE',accountantClient.includes('localeCompare')&&accountantClient.includes('sort_order')],
 ['STAGING REQUIRED BEFORE LIVE',gates.includes('DEDICATED V2 STAGING DATABASE')&&gates.includes('BACKUP/RESTORE')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`RUNTIME READINESS FAILED: ${failed.length}`);process.exit(1)}console.log(`TORVO V2 RUNTIME READINESS CONTRACT VERIFIED (${checks.length} GATES)`);
