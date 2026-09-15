import fs from 'node:fs';
const p='supabase/v2-salesman-referral-otp-statement.sql';
const s=fs.readFileSync(p,'utf8');
const must=[
 'salesman_referral_otp_challenges','salesman_referral_verifications','otp_hash text not null',"expires_at timestamptz not null","attempts integer not null default 0","role='salesman'",'dealer_salesman_mapping','crypt(v_plain,gen_salt','SALESMAN_REFERRAL_OTP_REQUESTED','salesman_verify_referral_otp','crypt(btrim(p_otp),c.otp_hash)','OTP ATTEMPT LIMIT REACHED','SALESMAN_REFERRAL_OTP_VERIFIED','salesman_my_referral_statement','revoke all on salesman_referral_otp_challenges from anon,authenticated','revoke all on salesman_referral_verifications from anon,authenticated'
];
for(const x of must){if(!s.includes(x)){console.error('Missing referral OTP contract:',x);process.exit(1)}}
if(/return query\s+select\s+v_plain/i.test(s)||/otp_hash\s*=\s*p_otp/i.test(s)){console.error('Plain OTP exposure/storage forbidden');process.exit(1)}
console.log('TORVO V2 SALESMAN REFERRAL OTP + STATEMENT CONTRACT PASS');
