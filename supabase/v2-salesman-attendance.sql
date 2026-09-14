begin;
create table if not exists public.salesman_attendance(
 id uuid primary key default gen_random_uuid(),
 salesman_user_id uuid not null references public.app_users(id) on delete restrict,
 attendance_date date not null default current_date,
 check_in_at timestamptz not null default now(),
 check_out_at timestamptz,
 check_in_note text,
 check_out_note text,
 status text not null default 'present' check(status in('present','late','leave','absent')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(salesman_user_id,attendance_date),
 check(check_out_at is null or check_out_at>=check_in_at)
);
alter table public.salesman_attendance enable row level security;
revoke all on public.salesman_attendance from anon,authenticated;

create or replace function public.salesman_current_user_id() returns uuid language sql stable security definer set search_path=public as $$
 select id from public.app_users where auth_user_id=auth.uid() and active=true and lower(role)='salesman' limit 1
$$;
revoke all on function public.salesman_current_user_id() from public;grant execute on function public.salesman_current_user_id() to authenticated;

create or replace function public.salesman_my_attendance_today() returns setof public.salesman_attendance language sql stable security definer set search_path=public as $$
 select a.* from public.salesman_attendance a where a.salesman_user_id=public.salesman_current_user_id() and a.attendance_date=current_date limit 1
$$;
revoke all on function public.salesman_my_attendance_today() from public;grant execute on function public.salesman_my_attendance_today() to authenticated;

create or replace function public.salesman_my_attendance_history(p_limit integer default 31) returns setof public.salesman_attendance language sql stable security definer set search_path=public as $$
 select a.* from public.salesman_attendance a where a.salesman_user_id=public.salesman_current_user_id() order by a.attendance_date desc limit greatest(1,least(coalesce(p_limit,31),93))
$$;
revoke all on function public.salesman_my_attendance_history(integer) from public;grant execute on function public.salesman_my_attendance_history(integer) to authenticated;

create or replace function public.salesman_attendance_check_in(p_note text default null) returns public.salesman_attendance language plpgsql security definer set search_path=public as $$
declare uid uuid; row_out public.salesman_attendance;
begin
 uid:=public.salesman_current_user_id();if uid is null then raise exception 'SALESMAN LOGIN REQUIRED';end if;
 insert into public.salesman_attendance(salesman_user_id,attendance_date,check_in_note) values(uid,current_date,nullif(trim(p_note),''))
 on conflict(salesman_user_id,attendance_date) do update set check_in_note=coalesce(public.salesman_attendance.check_in_note,excluded.check_in_note),updated_at=now()
 returning * into row_out;return row_out;
end$$;
revoke all on function public.salesman_attendance_check_in(text) from public;grant execute on function public.salesman_attendance_check_in(text) to authenticated;

create or replace function public.salesman_attendance_check_out(p_note text default null) returns public.salesman_attendance language plpgsql security definer set search_path=public as $$
declare uid uuid; row_out public.salesman_attendance;
begin
 uid:=public.salesman_current_user_id();if uid is null then raise exception 'SALESMAN LOGIN REQUIRED';end if;
 update public.salesman_attendance set check_out_at=coalesce(check_out_at,now()),check_out_note=coalesce(nullif(trim(p_note),''),check_out_note),updated_at=now() where salesman_user_id=uid and attendance_date=current_date returning * into row_out;
 if row_out.id is null then raise exception 'CHECK IN BEFORE CHECK OUT';end if;return row_out;
end$$;
revoke all on function public.salesman_attendance_check_out(text) from public;grant execute on function public.salesman_attendance_check_out(text) to authenticated;
commit;
