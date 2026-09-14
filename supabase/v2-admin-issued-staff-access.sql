-- TORVO V2 ADMIN-ISSUED STAFF ACCESS
-- LOCKED MODEL: SALESMAN / STORE KEEPER / ACCOUNTANT USE USERNAME + ONE-TIME ADMIN PASSWORD.
-- NO STAFF MOBILE NUMBER IS REQUIRED FOR THIS LOGIN MODEL. PASSWORD IS HASHED AND CONSUMED ON FIRST SUCCESSFUL LOGIN.
create extension if not exists pgcrypto;

create table if not exists staff_access_identities(
 app_user_id uuid primary key references app_users(id) on delete cascade,
 username text not null unique,
 employee_name text not null,
 staff_role text not null check(staff_role in('salesman','store_keeper','accountant')),
 active boolean not null default true,
 updated_at timestamptz not null default now(),
 updated_by uuid references app_users(id)
);
create unique index if not exists uq_staff_access_username_upper on staff_access_identities(upper(username));

create table if not exists staff_one_time_passwords(
 id uuid primary key default gen_random_uuid(),app_user_id uuid not null references app_users(id) on delete cascade,
 password_hash text not null,created_by uuid not null references app_users(id),created_at timestamptz not null default now(),
 expires_at timestamptz not null,used_at timestamptz,revoked_at timestamptz
);
create index if not exists idx_staff_otp_access_active on staff_one_time_passwords(app_user_id,created_at desc);

create table if not exists staff_authorized_devices(
 id uuid primary key default gen_random_uuid(),app_user_id uuid not null references app_users(id) on delete cascade,
 device_id text not null,device_type text not null check(device_type in('mobile_app','desktop')),
 approved_by uuid not null references app_users(id),approved_at timestamptz not null default now(),revoked_at timestamptz,
 unique(app_user_id,device_id)
);
create unique index if not exists uq_staff_one_active_device on staff_authorized_devices(app_user_id) where revoked_at is null;

alter table staff_access_identities enable row level security;alter table staff_one_time_passwords enable row level security;alter table staff_authorized_devices enable row level security;
revoke all on staff_access_identities,staff_one_time_passwords,staff_authorized_devices from anon,authenticated;

create or replace function admin_upsert_staff_access(p_app_user_id uuid,p_username text,p_employee_name text,p_staff_role text)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;target app_users%rowtype;u text:=upper(btrim(coalesce(p_username,'')));n text:=upper(btrim(coalesce(p_employee_name,'')));begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or actor.role not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into target from app_users where id=p_app_user_id and active=true;if target.id is null then raise exception 'ACTIVE STAFF REQUIRED';end if;
 if p_staff_role not in('salesman','store_keeper','accountant') or target.role<>p_staff_role then raise exception 'STAFF ROLE MISMATCH';end if;
 if u!~ '^[A-Z]{2,8}@[0-9]{2,6}$' then raise exception 'USERNAME FORMAT REQUIRED';end if;if length(n)<2 or length(n)>120 then raise exception 'EMPLOYEE NAME REQUIRED';end if;
 insert into staff_access_identities(app_user_id,username,employee_name,staff_role,updated_by) values(target.id,u,n,p_staff_role,actor.id)
 on conflict(app_user_id) do update set username=excluded.username,employee_name=excluded.employee_name,staff_role=excluded.staff_role,active=true,updated_at=now(),updated_by=actor.id;
end$$;

create or replace function admin_issue_staff_one_time_password(p_app_user_id uuid,p_password text,p_minutes integer default 30)
returns uuid language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;i staff_access_identities%rowtype;rid uuid;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or actor.role not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into i from staff_access_identities where app_user_id=p_app_user_id and active=true;if i.app_user_id is null then raise exception 'STAFF ACCESS ID REQUIRED';end if;
 if length(coalesce(p_password,''))<10 or length(p_password)>80 then raise exception 'STRONG TEMPORARY PASSWORD REQUIRED';end if;if p_minutes<5 or p_minutes>120 then raise exception 'PASSWORD EXPIRY MUST BE 5 TO 120 MINUTES';end if;
 update staff_one_time_passwords set revoked_at=now() where app_user_id=p_app_user_id and used_at is null and revoked_at is null;
 insert into staff_one_time_passwords(app_user_id,password_hash,created_by,expires_at) values(p_app_user_id,crypt(p_password,gen_salt('bf')),actor.id,now()+make_interval(mins=>p_minutes)) returning id into rid;return rid;
end$$;

create or replace function admin_approve_staff_device(p_app_user_id uuid,p_device_id text,p_device_type text)
returns uuid language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;i staff_access_identities%rowtype;rid uuid;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or actor.role not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into i from staff_access_identities where app_user_id=p_app_user_id and active=true;if i.app_user_id is null then raise exception 'STAFF ACCESS ID REQUIRED';end if;
 if length(btrim(coalesce(p_device_id,'')))<8 or length(p_device_id)>180 then raise exception 'SECURE DEVICE ID REQUIRED';end if;
 if (i.staff_role='accountant' and p_device_type<>'desktop') or (i.staff_role in('salesman','store_keeper') and p_device_type<>'mobile_app') then raise exception 'DEVICE TYPE NOT ALLOWED FOR ROLE';end if;
 update staff_authorized_devices set revoked_at=now() where app_user_id=p_app_user_id and revoked_at is null;
 insert into staff_authorized_devices(app_user_id,device_id,device_type,approved_by) values(p_app_user_id,btrim(p_device_id),p_device_type,actor.id)
 on conflict(app_user_id,device_id) do update set device_type=excluded.device_type,approved_by=actor.id,approved_at=now(),revoked_at=null returning id into rid;return rid;
end$$;

create or replace function admin_revoke_staff_access(p_app_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or actor.role not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 update staff_one_time_passwords set revoked_at=now() where app_user_id=p_app_user_id and used_at is null and revoked_at is null;
 update staff_authorized_devices set revoked_at=now() where app_user_id=p_app_user_id and revoked_at is null;
 update staff_auth_sessions set revoked_at=coalesce(revoked_at,now()),revoked_by=actor.id where app_user_id=p_app_user_id and revoked_at is null;
end$$;

-- TRUSTED SERVER ONLY: consumes password atomically and verifies the already Admin-approved device.
create or replace function staff_verify_one_time_password(p_username text,p_password text,p_device_id text,p_device_type text)
returns uuid language plpgsql security definer set search_path=public as $$declare i staff_access_identities%rowtype;p staff_one_time_passwords%rowtype;begin
 select * into i from staff_access_identities where upper(username)=upper(btrim(coalesce(p_username,''))) and active=true;if i.app_user_id is null then raise exception 'INVALID STAFF LOGIN';end if;
 if (i.staff_role='accountant' and p_device_type<>'desktop') or (i.staff_role in('salesman','store_keeper') and p_device_type<>'mobile_app') then raise exception 'DEVICE NOT ALLOWED';end if;
 perform 1 from staff_authorized_devices where app_user_id=i.app_user_id and device_id=btrim(coalesce(p_device_id,'')) and device_type=p_device_type and revoked_at is null;if not found then raise exception 'DEVICE APPROVAL REQUIRED';end if;
 select * into p from staff_one_time_passwords where app_user_id=i.app_user_id and used_at is null and revoked_at is null and expires_at>now() order by created_at desc limit 1 for update;
 if p.id is null or crypt(coalesce(p_password,''),p.password_hash)<>p.password_hash then raise exception 'INVALID OR EXPIRED PASSWORD';end if;
 update staff_one_time_passwords set used_at=now() where id=p.id;return i.app_user_id;
end$$;

revoke all on function admin_upsert_staff_access(uuid,text,text,text) from public,anon;grant execute on function admin_upsert_staff_access(uuid,text,text,text) to authenticated;
revoke all on function admin_issue_staff_one_time_password(uuid,text,integer) from public,anon;grant execute on function admin_issue_staff_one_time_password(uuid,text,integer) to authenticated;
revoke all on function admin_approve_staff_device(uuid,text,text) from public,anon;grant execute on function admin_approve_staff_device(uuid,text,text) to authenticated;
revoke all on function admin_revoke_staff_access(uuid) from public,anon;grant execute on function admin_revoke_staff_access(uuid) to authenticated;
revoke all on function staff_verify_one_time_password(text,text,text,text) from public,anon,authenticated;
