import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8'),fail=m=>{console.error(`PUBLIC SERVICE EXPORT CONTRACT FAILED: ${m}`);process.exit(1)};
const service=read('src/v2/services/publicWebsite.js');
const consumers=['src/v2/components/PublicWebsitePreview.jsx','src/v2/components/CustomerApp.jsx'];
const exported=new Set([...service.matchAll(/export\s+async\s+function\s+([A-Za-z_$][\w$]*)/g)].map(x=>x[1]));
for(const file of consumers){const text=read(file);for(const m of text.matchAll(/import\s*\{([^}]+)\}\s*from\s*['"]\.\.\/services\/publicWebsite['"]/g)){for(const raw of m[1].split(',')){const spec=raw.trim();if(!spec)continue;const imported=spec.split(/\s+as\s+/)[0].trim();if(!exported.has(imported))fail(`${file} IMPORTS ${imported} BUT publicWebsite.js DOES NOT EXPORT IT`)}}}
for(const required of['createProductDemand','createProductEnquiry','createProductRequirement','createReferral','createRepair','findDealers','loadDealerProfile','registerDealer'])if(!exported.has(required))fail(`REQUIRED PUBLIC SERVICE EXPORT MISSING: ${required}`);
console.log('TORVO V2 public website service export contract OK');
