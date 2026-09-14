import{readFile}from'node:fs/promises';
const[sql,service,auth,order,login,attendance,workspace]=await Promise.all([readFile('supabase/v2-salesman-attendance.sql','utf8'),readFile('src/v2/services/salesmanAttendance.js','utf8'),readFile('src/v2/services/staffAuth.js','utf8'),readFile('supabase/V2_INSTALL_ORDER.md','utf8'),readFile('src/v2/components/BusinessLogin.jsx','utf8'),readFile('src/v2/components/SalesmanAttendance.jsx','utf8'),readFile('src/v2/components/SalesmanAppWorkspace.jsx','utf8')]);
const gates=[
 ['ATTENDANCE TABLE',sql.includes('create table if not exists public.salesman_attendance')],
 ['ONE DAILY RECORD',sql.includes('unique(salesman_user_id,attendance_date)')],
 ['ROLE DERIVED SERVER SIDE',sql.includes("lower(role)='salesman'")&&sql.includes('auth.uid()')],
 ['DIRECT TABLE ACCESS BLOCKED',sql.includes('revoke all on public.salesman_attendance from anon,authenticated')],
 ['CHECK IN RPC',sql.includes('salesman_attendance_check_in')],
 ['CHECK OUT REQUIRES CHECK IN',sql.includes("raise exception 'CHECK IN BEFORE CHECK OUT'")],
 ['SELF HISTORY RPC',sql.includes('salesman_my_attendance_history')],
 ['CLIENT ATTENDANCE SERVICE',service.includes('attendanceCheckIn')&&service.includes('attendanceCheckOut')&&service.includes('myAttendanceHistory')],
 ['DEALER MOBILE VALIDATOR',auth.includes('normalizeDealerMobile')],
 ['STAFF ID VALIDATOR',auth.includes('normalizeStaffUsername')&&auth.includes('STAFF USER ID')],
 ['DUAL LOGIN SCREEN',login.includes('DEALER MOBILE')&&login.includes('STAFF USER ID')&&login.includes('REGISTER AS DEALER')],
 ['STAFF ONE TIME PASSWORD LOGIN',login.includes('loginStaffWithAdminPassword')&&login.includes('ADMIN-ISSUED ONE-TIME PASSWORD')],
 ['ATTENDANCE UI',attendance.includes('CHECK IN')&&attendance.includes('CHECK OUT')&&attendance.includes('myAttendanceHistory')],
 ['SALESMAN APP TABS',workspace.includes('BUSINESS')&&workspace.includes('ATTENDANCE')&&workspace.includes('<SalesmanAttendance/>')],
 ['INSTALL ORDER LOCKED',order.includes('v2-salesman-attendance.sql')]
];let failed=false;for(const[name,ok]of gates){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed=true}if(failed)process.exit(1);console.log(`TORVO V2 SALESMAN ATTENDANCE / LOGIN CONTRACT VERIFIED (${gates.length} GATES)`);
