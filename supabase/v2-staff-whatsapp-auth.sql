-- TORVO V2 STAFF AUTH SESSION FOUNDATION
-- FINAL LOGIN: MASTER-EMAIL OTP ONLY. Legacy emergency/password login paths are retired.
create extension if not exists pgcrypto;
create table if not exists staff_auth_sessions(id uuid primary key default gen_random_uuid(),app_user_id uuid not null references app_users(id) on delete cascade,auth_user_id uuid not null,login_method text not null,device_id text not null,created_at timestamptz not null default now(),expires_at timestamptz not null,revoked_at timestamptz,revoked_by uuid references app_users(id),last_seen_at timestamptz not null default now());
alter table staff_auth_sessions drop constraint if exists staff_auth_sessions_login_method_check;
alter table staff_auth_sessions add constraint staff_auth_sessions_login_method_check check(login_method='email_otp');
create index if not exists idx_staff_auth_session_user on staff_auth_sessions(app_user_id,expires_at desc);
alter table staff_auth_sessions enable row level security;
create or replace function torvo_is_staff_role(p_role text) returns boolean language sql immutable set search_path=public as $select lower(coalesce(p_role,'')) in('owner','admin','accountant','salesman','store_keeper')$;
create or replace function staff_create_verified_session(p_auth_user_id uuid,p_device_id text,p_login_method text default 'email_otp') returns uuid language plpgsql security definer set search_path=public as $$declare v app_users%rowtype;sid uuid;begin if p_auth_user_id is null then raise exception 'AUTH_IDENTITY_REQUIRED';end if;if length(btrim(coalesce(p_device_id,'')))<8 or length(coalesce(p_device_id,''))>180 then raise exception 'SECURE_DEVICE_ID_REQUIRED';end if;select * into v from app_users where auth_user_id=p_auth_user_id and active=true;if v.id is null or not torvo_is_staff_role(v.role) then raise exception 'STAFF_ACCESS_DENIED';end if;if p_login_method<>'email_otp' then raise exception 'INVALID_LOGIN_METHOD';end if;if lower(coalesce(v.role,'')) not in('admin','accountant','salesman','store_keeper') then raise exception 'EMAIL_OTP_ROLE_NOT_ALLOWED';end if;insert into staff_auth_sessions(app_user_id,auth_user_id,login_method,device_id,expires_at) values(v.id,p_auth_user_id,'email_otp',left(btrim(p_device_id),180),now()+interval '30 days') returning id into sid;return sid;end$$;
create or replace function staff_session_valid(p_session_id uuid,p_device_id text) returns boolean language sql security definer set search_path=public as $$select auth.uid() is not null and exists(select 1 from staff_auth_sessions s join app_users u on u.id=s.app_user_id where s.id=p_session_id and s.auth_user_id=auth.uid() and length(btrim(coalesce(p_device_id,'')))>=8 and length(coalesce(p_device_id,''))<=180 and s.device_id=btrim(p_device_id) and s.revoked_at is null and s.expires_at>now() and u.active=true and torvo_is_staff_role(u.role))$$;
create or replace function staff_revoke_my_sessions() returns integer language plpgsql security definer set search_path=public as $$declare n integer;begin if auth.uid() is null then raise exception 'AUTH_REQUIRED';end if;update staff_auth_sessions set revoked_at=coalesce(revoked_at,now()) where auth_user_id=auth.uid() and revoked_at is null;get diagnostics n=row_count;return n;end$$;
create or replace function staff_touch_verified_session(p_session_id uuid,p_device_id text) returns boolean language plpgsql security definer set search_path=public as $$begin if not staff_session_valid(p_session_id,p_device_id) then return false;end if;update staff_auth_sessions set last_seen_at=now() where id=p_session_id and auth_user_id=auth.uid() and revoked_at is null and expires_at>now();return found;end$$;
drop function if exists admin_create_staff_emergency_code(uuid,text,text,integer);
drop function if exists admin_revoke_staff_emergency_codes(uuid);
drop function if exists staff_verify_emergency_code(text,text);
drop table if exists staff_emergency_login_codes;
revoke all on function staff_create_verified_session(uuid,text,text) from public,anon,authenticated;
revoke all on function staff_session_valid(uuid,text) from public,anon;
revoke all on function staff_revoke_my_sessions() from public,anon;
revoke all on function staff_touch_verified_session(uuid,text) from public,anon;
grant execute on function staff_create_verified_session(uuid,text,text) to service_role;
grant execute on function staff_session_valid(uuid,text) to authenticated;
grant execute on function staff_touch_verified_session(uuid,text) to authenticated;
grant execute on function staff_revoke_my_sessions() to authenticated;
