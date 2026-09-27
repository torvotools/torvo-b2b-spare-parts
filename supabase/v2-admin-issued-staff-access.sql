-- TORVO V2 STAFF ACCESS IDENTITY FOUNDATION
-- FINAL: MASTER-EMAIL OTP + ONE ACTIVE SESSION. Manual staff device registration/approval is retired.
drop function if exists staff_verify_one_time_password(text,text,text,text);
drop function if exists admin_issue_staff_one_time_password(uuid,text,integer);
drop table if exists staff_one_time_passwords;

create table if not exists staff_access_identities(
 app_user_id uuid primary key references app_users(id) on delete cascade,
 username text not null unique,
 employee_name text not null,
 staff_role text not null check(staff_role in('owner','salesman','store_keeper','accountant','admin')),
 active boolean not null default true,
 updated_at timestamptz not null default now(),
 updated_by uuid references app_users(id)
);
create unique index if not exists uq_staff_access_username_upper on staff_access_identities(upper(username));

drop function if exists admin_approve_staff_device(uuid,text,text);
drop table if exists staff_authorized_devices;

alter table staff_access_identities enable row level security;
revoke all on staff_access_identities from anon,authenticated;

create or replace function admin_upsert_staff_access(p_app_user_id uuid,p_username text,p_employee_name text,p_staff_role text)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;target app_users%rowtype;u text:=upper(btrim(coalesce(p_username,'')));n text:=upper(btrim(coalesce(p_employee_name,'')));begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into target from app_users where id=p_app_user_id and active=true;if target.id is null then raise exception 'ACTIVE STAFF REQUIRED';end if;
 if lower(coalesce(p_staff_role,'')) not in('owner','salesman','store_keeper','accountant','admin') or lower(coalesce(target.role,''))<>lower(coalesce(p_staff_role,'')) then raise exception 'STAFF ROLE MISMATCH';end if;
 if u!~ '^[A-Z]{2,8}@[0-9]{2,6}$' then raise exception 'USERNAME FORMAT REQUIRED';end if;if length(n)<2 or length(n)>120 then raise exception 'EMPLOYEE NAME REQUIRED';end if;
 insert into staff_access_identities(app_user_id,username,employee_name,staff_role,updated_by) values(target.id,u,n,lower(p_staff_role),actor.id)
 on conflict(app_user_id) do update set username=excluded.username,employee_name=excluded.employee_name,staff_role=excluded.staff_role,active=true,updated_at=now(),updated_by=actor.id;
end$$;

create or replace function admin_revoke_staff_access(p_app_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 update staff_access_identities set active=false,updated_at=now(),updated_by=actor.id where app_user_id=p_app_user_id;
 update staff_auth_sessions set revoked_at=coalesce(revoked_at,now()),revoked_by=actor.id where app_user_id=p_app_user_id and revoked_at is null;
end$$;

create or replace function bootstrap_initial_owner_staff_access(p_username text,p_employee_name text)
returns uuid language sql security definer set search_path=public as $owner_bootstrap$
with actor as (
 select id from app_users
 where auth_user_id=auth.uid() and active=true and lower(coalesce(role,''))='owner'
   and upper(btrim(coalesce(p_username,'')))='OR@000'
   and length(upper(btrim(coalesce(p_employee_name,'')))) between 2 and 120
   and not exists(select 1 from staff_access_identities)
), identity_row as (
 insert into staff_access_identities(app_user_id,username,employee_name,staff_role,active,updated_by)
 select id,'OR@000',upper(btrim(p_employee_name)),'owner',true,id from actor
 returning app_user_id
)
select app_user_id from identity_row
$owner_bootstrap$;

drop function if exists bootstrap_initial_owner_staff_access(text,text,text);
revoke all on function bootstrap_initial_owner_staff_access(text,text) from public,anon;
grant execute on function bootstrap_initial_owner_staff_access(text,text) to authenticated;

revoke all on function admin_upsert_staff_access(uuid,text,text,text) from public,anon;grant execute on function admin_upsert_staff_access(uuid,text,text,text) to authenticated;
revoke all on function admin_revoke_staff_access(uuid) from public,anon;grant execute on function admin_revoke_staff_access(uuid) to authenticated;
