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
  const end = sql.indexOf(String.fromCharCode(36, 36) + ';', start);
  assert.ok(end > start, fn + ' body missing');
  assert.ok(sql.slice(start, end).includes(india), fn + ' does not use India-local date');
}
assert.ok(sql.includes('p_from date default (' + india + ' - 30)'), 'report from default wrong');
assert.ok(sql.includes('p_to date default (' + india + ')'), 'report to default wrong');
// Ensure report defaults are India-local and the attendance table remains locked down.
assert.ok(sql.includes('revoke all on public.salesman_attendance from anon,authenticated'), 'attendance table direct access must remain revoked');
assert.ok(sql.includes('unique(salesman_user_id,attendance_date)'), 'one daily attendance row constraint missing');
assert.ok(sql.includes("lower(role)='salesman'"), 'salesman role binding missing');
assert.ok(sql.includes("lower(role) in('owner','admin')"), 'admin report authorization missing');
const salesmanUi = fs.readFileSync('src/v2/components/SalesmanAttendance.jsx', 'utf8');
const reportUi = fs.readFileSync('src/v2/components/SalesmanAttendanceReport.jsx', 'utf8');
const service = fs.readFileSync('src/v2/services/salesmanAttendance.js', 'utf8');
for (const [name, ui] of [['Salesman', salesmanUi], ['Owner/Admin report', reportUi]]) {
  assert.ok(ui.includes("timeZone:'Asia/Kolkata'"), name + ' time display must use IST');
  assert.ok(!ui.includes('toLocaleTimeString([],'), name + ' uses device-local time');
}
assert.ok(reportUi.includes("timeZone:'Asia/Kolkata',year:'numeric'"), 'report calendar date must use India timezone');
assert.ok(!reportUi.includes('toISOString().slice(0,10)'), 'UTC date conversion reintroduced in report');
assert.ok(service.includes('if(text(from))params.p_from=text(from)') && service.includes('if(text(to))params.p_to=text(to)'), 'report must omit absent date parameters rather than send null');
console.log('PASS salesman attendance India timezone and role safety source contract');
