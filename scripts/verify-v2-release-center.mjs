import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const sql=read('supabase/v2-app-release-center.sql'),svc=read('src/v2/services/appRelease.js'),ui=read('src/v2/components/AppReleaseCenter.jsx'),settings=read('src/v2/components/SettingsAuditWorkspace.jsx'),android=read('.github/workflows/v2-android-apk.yml');
const checks=[
 ['OWNER ADMIN SERVER GATE',sql.includes("a.role not in('owner','admin')")],
 ['NO AUTHENTICATED TABLE WRITE',sql.includes('revoke all on table app_release_artifacts from public,anon,authenticated')],
 ['VERIFIED DOWNLOAD ONLY',svc.includes("release.status!=='verified'")&&svc.includes("release.status!=='published'")],
 ['RELEASE UI CONNECTED',ui.includes('loadAppReleases')&&ui.includes('DOWNLOAD VERIFIED FILE')],
 ['ADMIN SETTINGS TAB CONNECTED',settings.includes("tab==='release'")&&settings.includes('<AppReleaseCenter/>')],
 ['ANDROID TEST APK CLEARLY LABELED',android.includes('TEST-DEBUG')&&android.includes('production_signed')&&android.includes('VERIFIED_TEST')],
 ['ANDROID FULL RELEASE GATES REQUIRED',android.includes('verify:v2-dealer-business')&&android.includes('verify:v2-release-gates')&&android.includes('verify:v2-runtime')],
 ['ANDROID EXACT SHA STAMPED',android.includes('torvo-build-sha.txt')&&android.includes('${GITHUB_SHA}')],
 ['ANDROID ARTIFACT HASHED',android.includes('sha256sum')&&android.includes('apk_sha256')]
];
const bad=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(bad.length){console.error(`RELEASE CENTER FAILED: ${bad.length}`);process.exit(1)}console.log('TORVO V2 RELEASE CENTER VERIFIED');
