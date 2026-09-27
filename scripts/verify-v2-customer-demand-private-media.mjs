import fs from'node:fs';
const s=fs.readFileSync('supabase/v2-customer-demand-private-media.sql','utf8'),o=fs.readFileSync('supabase/V2_INSTALL_ORDER.md','utf8');
const checks=[
 ['PRIVATE BUCKET',/torvo-customer-requirement-media','torvo-customer-requirement-media',false/.test(s)],
 ['IMAGE TYPES ONLY',/image\/jpeg.*image\/png.*image\/webp/.test(s)],
 ['8MB LIMIT',/8388608/.test(s)],
 ['PRIVATE METADATA RLS',/alter table customer_demand_media enable row level security/.test(s)&&/revoke all on customer_demand_media from anon,authenticated/.test(s)],
 ['DEMAND FK',/demand_id uuid not null references customer_product_demands\(id\) on delete cascade/.test(s)],
 ['NO ANON STORAGE POLICY',!/to anon/.test(s)],
 ['OWNER ADMIN STORAGE',/u\.role in\('owner','admin'\)/.test(s)],
 ['ADMIN MEDIA RPC',/admin_customer_demand_media/.test(s)&&/OWNER OR ADMIN REQUIRED/.test(s)],
 ['NO PUBLIC URL CONTRACT',/Never expose this bucket with getPublicUrl/.test(s)],
 ['SERVER MEDIATED UPLOAD REQUIRED',/server-mediated one-time upload boundary/i.test(s)],
 ['INSTALL AFTER DEMAND',o.includes('v2-customer-product-demand-leads.sql')&&o.includes('v2-customer-demand-private-media.sql')&&o.indexOf('v2-customer-demand-private-media.sql')>o.indexOf('v2-customer-product-demand-leads.sql')]
];
const bad=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(bad.length){console.error(`CUSTOMER DEMAND PRIVATE MEDIA FAILED: ${bad.length} GATE(S)`);process.exit(1)}console.log(`PASS CUSTOMER DEMAND PRIVATE MEDIA (${checks.length} GATES)`);
