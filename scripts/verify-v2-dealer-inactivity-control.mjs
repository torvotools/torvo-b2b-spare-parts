import fs from 'node:fs';

const sql = fs.readFileSync(new URL('../supabase/v2-dealer-inactivity-control.sql', import.meta.url), 'utf8');
const must = [
  "interval '3 months'",
  'NO BILLING/PURCHASE ACTIVITY FOR 3 CONSECUTIVE MONTHS',
  'admin_set_dealer_suspension',
  "u.role not in('owner','admin')",
  "status='suspended'",
  "status='approved'",
  "update app_users set active=false",
  "update app_users set active=true",
  'forced_logout_at',
  'DEALER_SUSPENDED',
  'DEALER_REACTIVATED',
  'REASON REQUIRED'
];
for (const token of must) {
  if (!sql.includes(token)) throw new Error(`Dealer inactivity contract missing: ${token}`);
}
if (/delete\s+from\s+dealers/i.test(sql)) throw new Error('Dealer inactivity control must never delete Dealer records');
if (/update\s+dealers\s+set\s+status\s*=\s*'suspended'[\s\S]{0,300}interval\s+'3 months'/i.test(sql)) {
  throw new Error('Three-month review must not auto-suspend a Dealer');
}
console.log('TORVO V2 dealer inactivity control contract verified.');
