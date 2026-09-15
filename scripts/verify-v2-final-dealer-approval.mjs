import fs from'node:fs';
const sql=fs.readFileSync('supabase/v2-dealer-final-approval-accountant-gate.sql','utf8');
const order=fs.readFileSync('supabase/V2_INSTALL_ORDER.md','utf8');
const bind=sql.indexOf('update app_users set dealer_id=p_dealer');
const approve=sql.indexOf("update dealers set dealer_code=upper(trim(p_dealer_code)),rate_group=p_rate_group,status='approved'");
const checks=[
 ['FINAL APPROVAL OWNER ADMIN ONLY',sql.includes("a.role not in('owner','admin')")],
 ['ACCOUNTANT SUBMISSION REQUIRED',sql.includes("accountant_verification_status,'pending_accountant')<>'submitted_to_admin'")&&sql.includes('accountant_verified_by is null')&&sql.includes('accountant_verified_at is null')],
 ['CANONICAL DEALER IDENTITY REQUIRED',sql.includes('DEALER APP IDENTITY REQUIRED BEFORE APPROVAL')&&sql.includes('dealer_id=p_dealer')],
 ['AMBIGUOUS IDENTITY REJECTED',sql.includes("linked_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS'")&&sql.includes("legacy_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS'")],
 ['IDENTITY CANDIDATES LOCKED',sql.includes("dealer_id=p_dealer for update")&&sql.includes("dealer_id is null and right(regexp_replace(coalesce(mobile,''),'\\D','','g'),10)=mob for update")],
 ['UNIQUE LEGACY BIND ONLY',sql.includes('select count(*),min(id) into legacy_count,legacy_id')&&sql.includes('if legacy_count=0')&&sql.includes('elsif legacy_count>1')],
 ['IDENTITY BINDS BEFORE APPROVAL',bind>=0&&approve>bind],
 ['APPROVAL AUDITS CANONICAL BIND',sql.includes("'canonical_identity_bound',true")],
 ['FINAL GATE INSTALL ORDERED',order.includes('v2-accountant-dealer-verification.sql')&&order.includes('v2-dealer-final-approval-accountant-gate.sql')&&order.indexOf('v2-dealer-final-approval-accountant-gate.sql')>order.indexOf('v2-accountant-dealer-verification.sql')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[name,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${name}`);if(failed.length){console.error(`FINAL DEALER APPROVAL FAILED: ${failed.length} GATE(S)`);process.exit(1)}console.log(`PASS FINAL DEALER APPROVAL (${checks.length} GATES)`);
