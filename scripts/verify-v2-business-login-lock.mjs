import fs from'node:fs';
const login=fs.readFileSync('src/v2/components/BusinessLogin.jsx','utf8');
const css=fs.readFileSync('src/v2/login-preview.css','utf8');
const fail=m=>{throw new Error('BUSINESS LOGIN LOCK REGRESSION: '+m)};
const required=[
 ['approved shell',login.includes('businessFinalLogin')&&login.includes('businessFinalCard')],
 ['control center',login.includes('CONTROL CENTER')],
 ['welcome',login.includes('<h2>WELCOME</h2>')],
 ['user id',login.includes('USER ID')&&login.includes('ENTER YOUR USER ID')],
 ['validation',login.includes('VALID USER ID')&&login.includes('INVALID USER ID')],
 ['send otp',login.includes('SEND OTP')],
 ['inline otp',login.includes('ENTER OTP')&&login.includes('ENTER 6-DIGIT OTP')],
 ['login action',login.includes("'LOGIN'")],
 ['staff otp begin',login.includes('beginStaffEmailOtp(normalized)')],
 ['staff otp verify',login.includes('verifyStaffEmailOtp(normalized, challenge, otp)')],
 ['no email field',!login.includes('EMAIL ID')],
 ['no dealer web auth',!login.includes('beginDealerEmailOtp')&&!login.includes('verifyDealerEmailOtp')],
 ['approved css',css.includes('.businessFinalLogin')&&css.includes('.businessFinalCard')&&css.includes('.businessFinalUserField')]
];
for(const[n,ok]of required){if(!ok)fail(n);console.log('PASS '+n.toUpperCase())}
console.log('TORVO BUSINESS LOGIN LOCK VERIFIED ('+required.length+' GATES)');
