import{requireBackend}from'./supabase';
const text=v=>String(v||'').trim();
export async function myAttendanceToday(){const{data,error}=await requireBackend().rpc('salesman_my_attendance_today');if(error)throw error;return Array.isArray(data)?data[0]||null:data||null}
export async function myAttendanceHistory(limit=31){const n=Math.max(1,Math.min(93,Number(limit)||31));const{data,error}=await requireBackend().rpc('salesman_my_attendance_history',{p_limit:n});if(error)throw error;return data||[]}
export async function attendanceCheckIn(note=''){const{data,error}=await requireBackend().rpc('salesman_attendance_check_in',{p_note:text(note)||null});if(error)throw error;return data}
export async function attendanceCheckOut(note=''){const{data,error}=await requireBackend().rpc('salesman_attendance_check_out',{p_note:text(note)||null});if(error)throw error;return data}
export async function adminSalesmanAttendance(from,to){const{data,error}=await requireBackend().rpc('admin_salesman_attendance',{p_from:from||null,p_to:to||null});if(error)throw error;return data||[]}
