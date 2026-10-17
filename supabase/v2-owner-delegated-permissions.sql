-- TORVO V2 OWNER-ONLY DELEGATED PERMISSIONS
-- STAGING CANDIDATE ONLY: do not run in production.
-- Requires public.app_users and public.audit_log.

create table if not exists public.owner_delegable_permission_catalog (
 permission_key text primary key,
 description text not null,
 active boolean not null default true,
 check (permission_key ~ '^[a-z][a-z0-9_]*([.][a-z][a-z0-9_]*)+$')
);
insert into public.owner_delegable_permission_catalog(permission_key,description) values
 ('catalog.view','View catalog'),('catalog.create','Create catalog items'),
 ('catalog.edit','Edit catalog items'),('dealer.view','View dealers'),
 ('dealer.approve','Approve dealers'),('inventory.view','View inventory'),
 ('inventory.manage','Manage inventory'),('dispatch.manage','Manage dispatch'),
 ('report.view','View reports'),('sales.manage','Manage sales'),
 ('staff.manage','Manage non-owner staff'),('website.edit','Edit website')
on conflict(permission_key) do nothing;
alter table public.owner_delegable_permission_catalog enable row level security;
revoke all on public.owner_delegable_permission_catalog from public,anon,authenticated;

create table if not exists public.owner_staff_permission_grants (
  id uuid primary key default gen_random_uuid(),
  staff_user_id uuid not null references public.app_users(id),
  permission_key text not null references public.owner_delegable_permission_catalog(permission_key),
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  revoked_at timestamptz,
  granted_by uuid not null references public.app_users(id),
  revoked_by uuid references public.app_users(id),
  reason text not null check (length(btrim(reason)) between 5 and 500),
  created_at timestamptz not null default now(),
  check (valid_until is null or valid_until > valid_from)
);
create index if not exists owner_staff_permission_grants_lookup
 on public.owner_staff_permission_grants(staff_user_id,permission_key)
 where revoked_at is null;
alter table public.owner_staff_permission_grants enable row level security;
revoke all on public.owner_staff_permission_grants from public,anon,authenticated;

create or replace function public.owner_has_staff_permission(p_permission text)
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists (
    select 1 from public.app_users u
    where u.auth_user_id=auth.uid() and u.active=true
      and (
        u.role='owner'
        or exists (
          select 1 from public.owner_staff_permission_grants g
          where g.staff_user_id=u.id and g.permission_key=p_permission
            and exists(select 1 from public.owner_delegable_permission_catalog pc where pc.permission_key=g.permission_key and pc.active=true)
            and g.revoked_at is null and g.valid_from<=now()
            and (g.valid_until is null or g.valid_until>now())
        )
      )
  )
$$;
revoke all on function public.owner_has_staff_permission(text) from public,anon;
grant execute on function public.owner_has_staff_permission(text) to authenticated;

-- Owner-only listing API: never expose the underlying grant table.
create or replace function public.owner_list_staff_permissions(p_staff_user_id uuid default null)
returns table(grant_id uuid,staff_user_id uuid,permission_key text,valid_from timestamptz,valid_until timestamptz,revoked_at timestamptz,granted_by uuid,reason text)
language plpgsql security definer set search_path=public,pg_temp as $$
declare actor_id uuid;
begin
 select id into actor_id from public.app_users
 where auth_user_id=auth.uid() and active=true and role='owner';
 if actor_id is null then raise exception 'OWNER REQUIRED'; end if;
 return query select g.id,g.staff_user_id,g.permission_key,g.valid_from,g.valid_until,g.revoked_at,g.granted_by,g.reason
 from public.owner_staff_permission_grants g
 where p_staff_user_id is null or g.staff_user_id=p_staff_user_id
 order by g.created_at desc;
end$$;
revoke all on function public.owner_list_staff_permissions(uuid) from public,anon;
grant execute on function public.owner_list_staff_permissions(uuid) to authenticated;

create or replace function public.owner_grant_staff_permission(
 p_staff_user_id uuid,p_permission text,p_reason text,
 p_valid_until timestamptz default null
) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare actor public.app_users%rowtype; target public.app_users%rowtype; new_id uuid;
begin
 select * into actor from public.app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role<>'owner' then raise exception 'OWNER REQUIRED'; end if;
 select * into target from public.app_users where id=p_staff_user_id and active=true;
 if target.id is null or target.role not in ('admin','salesman','accountant','store_keeper') then raise exception 'ACTIVE STAFF REQUIRED'; end if;
 if p_permission is null or p_permission !~ '^[a-z][a-z0-9_]*([.][a-z][a-z0-9_]*)+$'
    or p_permission like 'owner.%' or p_permission like 'permissions.%'
 then raise exception 'INVALID OR RESERVED PERMISSION'; end if;
 if not exists(select 1 from public.owner_delegable_permission_catalog pc where pc.permission_key=p_permission and pc.active=true) then raise exception 'PERMISSION NOT DELEGABLE'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 then raise exception 'CHANGE REASON REQUIRED'; end if;
 if p_valid_until is not null and p_valid_until<=now() then raise exception 'FUTURE EXPIRY REQUIRED'; end if;
 insert into public.owner_staff_permission_grants
  (staff_user_id,permission_key,valid_until,granted_by,reason)
 values (target.id,p_permission,p_valid_until,actor.id,btrim(p_reason))
 returning id into new_id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(actor.id,'STAFF_PERMISSION_GRANTED','STAFF_PERMISSION',new_id::text,
 jsonb_build_object('target',target.id,'permission',p_permission,'expiry',p_valid_until));
 return new_id;
end$$;
revoke all on function public.owner_grant_staff_permission(uuid,text,text,timestamptz) from public,anon;
grant execute on function public.owner_grant_staff_permission(uuid,text,text,timestamptz) to authenticated;

create or replace function public.owner_revoke_staff_permission(p_grant_id uuid,p_reason text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare actor public.app_users%rowtype; changed_id uuid;
begin
 select * into actor from public.app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role<>'owner' then raise exception 'OWNER REQUIRED'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 then raise exception 'CHANGE REASON REQUIRED'; end if;
 update public.owner_staff_permission_grants
 set revoked_at=now(),revoked_by=actor.id where id=p_grant_id and revoked_at is null
 returning id into changed_id;
 if changed_id is null then return false; end if;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(actor.id,'STAFF_PERMISSION_REVOKED','STAFF_PERMISSION',changed_id::text,
 jsonb_build_object('reason',btrim(p_reason)));
 return true;
end$$;
revoke all on function public.owner_revoke_staff_permission(uuid,text) from public,anon;
grant execute on function public.owner_revoke_staff_permission(uuid,text) to authenticated;

-- NOTE: Existing owner/admin RPCs and RLS policies must be migrated to check
-- owner_has_staff_permission() BEFORE delegated permissions can authorize actions.
-- Until that happens this table is non-authoritative and cannot grant extra access.
