import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const sql=read('supabase/v2-app-release-center.sql'),svc=read('src/v2/services/appRelease.js'),ui=read('src/v2/components/AppReleaseCenter.jsx'),settings=read('src/v2/components/SettingsAuditWorkspace.jsx'),android=read('.github/workflows/v2-android-apk.yml');
const checks=[
 ['OWNER ADMIN SERVER GATE',sql.includes("a.role not in('owner','admin')")],
 ['NO AUTHENTICATED TABLE WRITE',sql.includes('revoke all on table app_release_artifacts from public,anon,authenticated')],
 ['VERIFIED DOWNLOAD STATUS ALLOWLIST',svc.includes("new Set(['verified','published'])")&&svc.includes('allowedStatus.has')],
 ['VERIFIED DOWNLOAD PLATFORM ALLOWLIST',svc.includes("new Set(['android_apk','android_aab','ios'])")&&svc.includes('allowedPlatform.has')],
 ['VERIFIED DOWNLOAD HTTPS ONLY',svc.includes("u.protocol!=='https:'")],
 ['VERIFIED DOWNLOAD MALFORMED URL CLOSED',svc.includes('catch{return null}')],
 ['RELEASE LOAD ARRAY BOUNDARY',svc.includes('Array.isArray(data)?data:[]')],
 ['RELEASE BACKEND REQUIRED',svc.includes("requireBackend().rpc('admin_app_release_center')")],
 ['RELEASE UI CONNECTED',ui.includes('loadAppReleases')&&ui.includes('DOWNLOAD VERIFIED FILE')],
 ['ADMIN SETTINGS TAB CONNECTED',settings.includes("tab==='release'")&&settings.includes('<AppReleaseCenter/>')],
 ['ANDROID TEST APK CLEARLY LABELED',android.includes('TEST-DEBUG')&&android.includes('production_signed')&&android.includes('VERIFIED_TEST')],
 ['ANDROID FULL RELEASE GATES REQUIRED',android.includes('verify:v2-auth')&&android.includes('verify:v2-ready')&&android.includes('verify:v2-dealer-business')&&android.includes('verify:v2-release-gates')&&android.includes('verify:v2-runtime')&&android.includes('verify:v2-release-center')],
 ['ANDROID EXACT SHA STAMPED',android.includes('torvo-build-sha.txt')&&android.includes('${GITHUB_SHA}')],
 ['ANDROID ARTIFACT HASHED',android.includes('sha256sum')&&android.includes('apk_sha256')],
 ['ANDROID APK MUST EXIST',android.includes('test -f android/app/build/outputs/apk/debug/app-debug.apk')],
 ['ANDROID MANIFEST MUST EXIST',android.includes('test -s release-artifact/release-manifest.json')],
 ['ANDROID MANIFEST SHA BOUND',android.includes('grep -q "${GITHUB_SHA}" release-artifact/release-manifest.json')],
 ['ANDROID ARTIFACT FAILS CLOSED',android.includes('if-no-files-found: error')],
 ['ANDROID ARTIFACT RETAINED',android.includes('retention-days: 90')],
 ['ANDROID TEST NOT PRODUCTION',android.includes('TEST-DEBUG (NOT PLAY STORE PRODUCTION)')&&android.includes('"production_signed":false')],
 ['ANDROID ONE DEVICE AUTH ASSET',android.includes('dealer-session-valid')&&android.includes('VERIFY ANDROID SINGLE-DEVICE AUTH ASSET')],
 ['ANDROID VERSIONED FILE NAME',android.includes('TORVO-TOOLS-TEST-v2-build-${BUILD_NO}-${SHORT_SHA}.apk')],
 ['ANDROID WORKFLOW BRANCH BOUND',android.includes('test "${GITHUB_REF_NAME}" = "torvo-v2-build"')]
];
const bad=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(bad.length){console.error(`RELEASE CENTER FAILED: ${bad.length}`);process.exit(1)}console.log(`TORVO V2 RELEASE CENTER VERIFIED (${checks.length} GATES)`);
