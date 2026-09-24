-- TORVO V2 STAFF ACCESS IDENTITY + DEVICE FOUNDATION
-- NORMAL STAFF LOGIN USES SERVER-GENERATED MASTER-EMAIL OTP. THIS FILE ONLY OWNS STAFF IDENTITY, APPROVED DEVICE AND ADMIN REVOKE CONTROLS.
drop function if exists staff_verify_one_time_password(text,text,text,text);
drop function if exists admin_issue_staff_one_time_password(uuid,text,integer);
drop table if exists staff_one_time_passwords;

create table if not exists staff_access_identities(
 app_user_id uuid primary key references app_users(id) on delete cascade,
 username text not null unique,
 employee_name text not null,
 staff_role text not null check(staff_role in('salesman','store_keeper','accountant','admin')),
 active boolean not null default true,
 updated_at timestamptz not null default now(),
 updated_by uuid references app_users(id)
);
create unique index if not exists uq_staff_access_username_upper on staff_access_identities(upper(username));

create table if not exists staff_authorized_devices(
 id uuid primary key default gen_random_uuid(),app_user_id uuid not null references app_users(id) on delete cascade,
 device_id text not null,device_type text not null check(device_type in('mobile_app','desktop')),
 approved_by uuid not null references app_users(id),approved_at timestamptz not null default now(),revoked_at timestamptz,
 unique(app_user_id,device_id)
);
create unique index if not exists uq_staff_one_active_device on staff_authorized_devices(app_user_id) where revoked_at is null;

alter table staff_access_identities enable row level security;alter table staff_authorized_devices enable row level security;
revoke all on staff_access_identities,staff_authorized_devices from anon,authenticated;

create or replace function admin_upsert_staff_access(p_app_user_id uuid,p_username text,p_employee_name text,p_staff_role text)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;target app_users%rowtype;u text:=upper(btrim(coalesce(p_username,'')));n text:=upper(btrim(coalesce(p_employee_name,'')));begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into target from app_users where id=p_app_user_id and active=true;if target.id is null then raise exception 'ACTIVE STAFF REQUIRED';end if;
 if lower(coalesce(p_staff_role,'')) not in('salesman','store_keeper','accountant','admin') or lower(coalesce(target.role,''))<>lower(coalesce(p_staff_role,'')) then raise exception 'STAFF ROLE MISMATCH';end if;
 if u!~ '^[A-Z]{2,8}@[0-9]{2,6}$' then raise exception 'USERNAME FORMAT REQUIRED';end if;if length(n)<2 or length(n)>120 then raise exception 'EMPLOYEE NAME REQUIRED';end if;
 insert into staff_access_identities(app_user_id,username,employee_name,staff_role,updated_by) values(target.id,u,n,lower(p_staff_role),actor.id)
 on conflict(app_user_id) do update set username=excluded.username,employee_name=excluded.employee_name,staff_role=excluded.staff_role,active=true,updated_at=now(),updated_by=actor.id;
end$$;

create or replace function admin_approve_staff_device(p_app_user_id uuid,p_device_id text,p_device_type text)
returns uuid language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;i staff_access_identities%rowtype;rid uuid;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select i.* into i from staff_access_identities i join app_users u on u.id=i.app_user_id where i.app_user_id=p_app_user_id and i.active=true and u.active=true and lower(coalesce(u.role,''))=i.staff_role;if i.app_user_id is null then raise exception 'STAFF ACCESS ID REQUIRED';end if;
 if length(btrim(coalesce(p_device_id,'')))<8 or length(p_device_id)>180 then raise exception 'SECURE DEVICE ID REQUIRED';end if;
 if (i.staff_role in('admin','accountant') and p_device_type<>'desktop') or (i.staff_role in('salesman','store_keeper') and p_device_type<>'mobile_app') then raise exception 'DEVICE TYPE NOT ALLOWED FOR ROLE';end if;
 update staff_authorized_devices set revoked_at=now() where app_user_id=p_app_user_id and revoked_at is null;
 insert into staff_authorized_devices(app_user_id,device_id,device_type,approved_by) values(p_app_user_id,btrim(p_device_id),p_device_type,actor.id)
 on conflict(app_user_id,device_id) do update set device_type=excluded.device_type,approved_by=actor.id,approved_at=now(),revoked_at=null returning id into rid;return rid;
end$$;

create or replace function admin_revoke_staff_access(p_app_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 update staff_access_identities set active=false,updated_at=now(),updated_by=actor.id where app_user_id=p_app_user_id;
 update staff_authorized_devices set revoked_at=now() where app_user_id=p_app_user_id and revoked_at is null;
 update staff_auth_sessions set revoked_at=coalesce(revoked_at,now()),revoked_by=actor.id where app_user_id=p_app_user_id and revoked_at is null;
end$$;

revoke all on function admin_upsert_staff_access(uuid,text,text,text) from public,anon;grant execute on function admin_upsert_staff_access(uuid,text,text,text) to authenticated;
revoke all on function admin_approve_staff_device(uuid,text,text) from public,anon;grant execute on function admin_approve_staff_device(uuid,text,text) to authenticated;
revoke all on function admin_revoke_staff_access(uuid) from public,anon;grant execute on function admin_revoke_staff_access(uuid) to authenticated;
