import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const app=read('src/v2/components/SalesmanAppWorkspace.jsx');
const ui=read('src/v2/components/SalesmanReferralWorkspace.jsx');
const checks=[
 ['REFERRAL WORKSPACE IMPORTED',app.includes("SalesmanReferralWorkspace from'./SalesmanReferralWorkspace'")],
 ['REFERRAL TAB MOUNTED',app.includes("tab==='referral'")&&app.includes('<SalesmanReferralWorkspace/>')],
 ['START OTP RPC',ui.includes("rpc('salesman_start_referral_otp'")&&ui.includes('p_referral_code')],
 ['VERIFY OTP RPC',ui.includes("rpc('salesman_verify_referral_otp'")&&ui.includes('p_challenge_id:challenge')&&ui.includes('p_otp:otp')],
 ['STATEMENT RPC',ui.includes("rpc('salesman_my_referral_statement'")&&ui.includes('p_from:from||null')&&ui.includes('p_to:to||null')],
 ['DATE FILTER UI',ui.includes('type="date"')&&ui.includes('APPLY DATE FILTER')],
 ['FAIL CLOSED WHATSAPP MESSAGE',ui.includes('WHATSAPP OTP WORKER NOT CONFIGURED')&&ui.includes('OTP WAS NOT SENT')],
 ['NO BROWSER OTP GENERATOR',!ui.includes('Math.random')&&!ui.includes('crypto.getRandomValues')&&!ui.includes('randomUUID')],
 ['OTP INPUT SIX DIGITS',ui.includes('maxLength="6"')&&ui.includes("replace(/\\D/g,'').slice(0,6)")],
 ['SUCCESS ONLY AFTER CHALLENGE',ui.includes("if(!c?.challenge_id)")&&ui.includes('setChallenge(c.challenge_id)')&&ui.includes('OTP SENT TO THE VERIFIED WHATSAPP NUMBER')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`SALESMAN REFERRAL UI CONTRACT FAILED: ${failed.length}`);process.exit(1)}console.log(`TORVO V2 SALESMAN REFERRAL UI CONTRACT VERIFIED (${checks.length} GATES)`);
