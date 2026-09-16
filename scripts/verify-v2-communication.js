import fs from 'node:fs';
const files=['v2-communication-config.js','v2-social-lead-source.js','v2-public-contact.js','v2-admin-communication-controls.js'];
let failed=false;
for(const file of files){const text=fs.readFileSync(file,'utf8');if(/PRIVATE_ADMIN_EMAIL|privateAdminEmail/i.test(text)){console.error('FAIL private admin email surface:',file);failed=true}}
const config=fs.readFileSync('v2-communication-config.js','utf8');
if(!config.includes("primaryChannel: 'WHATSAPP'")){console.error('FAIL WhatsApp primary contract');failed=true}
const lead=fs.readFileSync('v2-social-lead-source.js','utf8');
for(const source of['WEBSITE','FACEBOOK','INSTAGRAM','YOUTUBE','WHATSAPP','EMAIL','OTHER']){if(!lead.includes(source)){console.error('FAIL missing lead source',source);failed=true}}
const publicContact=fs.readFileSync('v2-public-contact.js','utf8');
if(!/WHATSAPP/i.test(publicContact)){console.error('FAIL public WhatsApp contact action');failed=true}
const adminControls=fs.readFileSync('v2-admin-communication-controls.js','utf8');
if(!/save/i.test(adminControls)){console.error('FAIL admin communication save contract');failed=true}
if(failed)process.exit(1);
console.log('TORVO V2 COMMUNICATION VERIFICATION PASS');
