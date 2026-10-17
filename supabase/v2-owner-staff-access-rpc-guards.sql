-- Owner-delegated staff.manage guards for staff identity administration.
create or replace function admin_upsert_staff_access(p_app_user_id uuid,p_username text,p_employee_name text,p_staff_role text)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;target app_users%rowtype;u text:=upper(btrim(coalesce(p_username,'')));n text:=upper(btrim(coalesce(p_employee_name,'')));begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or not public.owner_has_staff_permission('staff.manage') then raise exception 'ADMIN REQUIRED';end if;
 select * into target from app_users where id=p_app_user_id and active=true;if target.id is null then raise exception 'ACTIVE STAFF REQUIRED';end if;
 if (lower(coalesce(p_staff_role,''))='owner' or lower(coalesce(target.role,''))='owner') and actor.role<>'owner' then raise exception 'OWNER ROLE PROTECTED';end if;
 if lower(coalesce(p_staff_role,'')) not in('owner','salesman','store_keeper','accountant','admin') or lower(coalesce(target.role,''))<>lower(coalesce(p_staff_role,'')) then raise exception 'STAFF ROLE MISMATCH';end if;
 if u!~ '^[A-Z]{2,8}@[0-9]{2,6}$' then raise exception 'USERNAME FORMAT REQUIRED';end if;if length(n)<2 or length(n)>120 then raise exception 'EMPLOYEE NAME REQUIRED';end if;
 insert into staff_access_identities(app_user_id,username,employee_name,staff_role,updated_by) values(target.id,u,n,lower(p_staff_role),actor.id)
 on conflict(app_user_id) do update set username=excluded.username,employee_name=excluded.employee_name,staff_role=excluded.staff_role,active=true,updated_at=now(),updated_by=actor.id;
end$$;

create or replace function admin_revoke_staff_access(p_app_user_id uuid)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;if actor.id is null or not public.owner_has_staff_permission('staff.manage') then raise exception 'ADMIN REQUIRED';end if;
 if actor.role<>'owner' and exists(select 1 from public.app_users where id=p_app_user_id and role='owner') then raise exception 'OWNER ROLE PROTECTED';end if;
 update staff_access_identities set active=false,updated_at=now(),updated_by=actor.id where app_user_id=p_app_user_id;
 update staff_auth_sessions set revoked_at=coalesce(revoked_at,now()),revoked_by=actor.id where app_user_id=p_app_user_id and revoked_at is null;
end$$;

