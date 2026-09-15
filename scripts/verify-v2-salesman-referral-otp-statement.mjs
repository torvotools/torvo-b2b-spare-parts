import fs from 'node:fs';
const p='supabase/v2-salesman-referral-otp-statement.sql';
const s=fs.readFileSync(p,'utf8');
const mapping=fs.readFileSync('supabase/v2-sales-team-mapping.sql','utf8');
const must=[
 'salesman_referral_otp_challenges','salesman_referral_verifications','otp_hash text not null',"expires_at timestamptz not null","attempts integer not null default 0","role='salesman'",'salesman_dealer_mappings','m.salesman_id=u.id','m.active=true','SALESMAN REFERRAL WHATSAPP OTP WORKER NOT CONFIGURED','cryptographically secure 6-digit OTP','service-role-only path','salesman_verify_referral_otp','crypt(btrim(p_otp),c.otp_hash)','OTP ATTEMPT LIMIT REACHED','REFERRAL ALREADY VERIFIED BY ANOTHER SALESMAN','SALESMAN_REFERRAL_OTP_VERIFIED','salesman_my_referral_statement','revoke all on salesman_referral_otp_challenges from anon,authenticated','revoke all on salesman_referral_verifications from anon,authenticated'
];
for(const x of must){if(!s.includes(x)){console.error('Missing referral OTP contract:',x);process.exit(1)}}
for(const x of ['create table if not exists salesman_dealer_mappings','salesman_id uuid not null references app_users(id)','dealer_id uuid not null references dealers(id)','active boolean not null default true']){if(!mapping.includes(x)){console.error('Canonical salesman mapping dependency missing:',x);process.exit(1)}}
if(s.includes('dealer_salesman_mapping')||s.includes('salesman_user_id=u.id and coalesce(m.active,true)')){console.error('Non-canonical salesman mapping reference forbidden');process.exit(1)}
if(s.includes('floor(random()*1000000)')||s.includes('crypt(v_plain,gen_salt')||s.includes("'SALESMAN_REFERRAL_OTP_REQUESTED'")){console.error('Unsafe database-generated referral OTP issuance forbidden');process.exit(1)}
if(/return query\s+select\s+v_plain/i.test(s)||/otp_hash\s*=\s*p_otp/i.test(s)){console.error('Plain OTP exposure/storage forbidden');process.exit(1)}
if(/on conflict\s*\(referral_id\)\s*do update/i.test(s)){console.error('Referral verification identity overwrite forbidden');process.exit(1)}
console.log('TORVO V2 SALESMAN REFERRAL OTP + STATEMENT FAIL-CLOSED CONTRACT PASS');
