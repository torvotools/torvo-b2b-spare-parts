import fs from 'node:fs';
import assert from 'node:assert/strict';

const sql = fs.readFileSync('supabase/v2-salesman-attendance.sql', 'utf8');
const india = "timezone('Asia/Kolkata', now())::date";
assert.ok(!/\bcurrent_date\b/i.test(sql), 'UTC-dependent current_date remains');
assert.ok(sql.includes("alter column attendance_date set default (" + india + ")"), 'existing table default not updated');
assert.ok(sql.includes('attendance_date date not null default (' + india + ')'), 'new table default not India-local');
for (const fn of ['salesman_my_attendance_today', 'salesman_attendance_check_in', 'salesman_attendance_check_out']) {
  const start = sql.indexOf('function public.' + fn + '(');
  assert.ok(start >= 0, fn + ' missing');
  const end = sql.indexOf('$$;', start);
  assert.ok(end > start, fn + ' body missing');
  assert.ok(sql.slice(start, end).includes(india), fn + ' does not use India-local date');
}
assert.ok(sql.includes('p_from date default (' + india + ' - 30)'), 'report from default wrong');
assert.ok(sql.includes('p_to date default (' + india + ')'), 'report to default wrong');
console.log('PASS salesman attendance India timezone source contract');
