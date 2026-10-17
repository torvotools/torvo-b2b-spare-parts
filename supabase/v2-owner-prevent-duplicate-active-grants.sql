-- TORVO V2 STAGING: block duplicate active permission grants.
-- Apply AFTER v2-owner-delegated-permissions.sql.
-- Replaces the owner grant RPC only; never grants privileges to non-owners.
create or replace function public.owner_grant_staff_permission(
 p_staff_user_id uuid,p_permission text,p_reason text,p_valid_until timestamptz default null
) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare actor public.app_users%rowtype; target public.app_users%rowtype; new_id uuid; existing_id uuid;
begin
 select * into actor from public.app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role<>'owner' then raise exception 'OWNER REQUIRED'; end if;
 select * into target from public.app_users where id=p_staff_user_id and active=true;
 if target.id is null or target.role not in ('admin','salesman','accountant','store_keeper') then raise exception 'ACTIVE STAFF REQUIRED'; end if;
 if p_permission is null or p_permission !~ '^[a-z][a-z0-9_]*([.][a-z][a-z0-9_]*)+$'
 or p_permission like 'owner.%' or p_permission like 'permissions.%' then raise exception 'INVALID OR RESERVED PERMISSION'; end if;
 if not exists(select 1 from public.owner_delegable_permission_catalog pc where pc.permission_key=p_permission and pc.active=true) then raise exception 'PERMISSION NOT DELEGABLE'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 then raise exception 'CHANGE REASON REQUIRED'; end if;
 if p_valid_until is not null and p_valid_until<=now() then raise exception 'FUTURE EXPIRY REQUIRED'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_staff_user_id::text || ':' || p_permission,0));
 select id into existing_id from public.owner_staff_permission_grants
 where staff_user_id=p_staff_user_id and permission_key=p_permission and revoked_at is null
 and (valid_until is null or valid_until>now()) limit 1;
 if existing_id is not null then raise exception 'PERMISSION ALREADY GRANTED: REVOKE EXISTING GRANT FIRST'; end if;
 insert into public.owner_staff_permission_grants(staff_user_id,permission_key,valid_until,granted_by,reason)
 values(target.id,p_permission,p_valid_until,actor.id,btrim(p_reason)) returning id into new_id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(actor.id,'STAFF_PERMISSION_GRANTED','STAFF_PERMISSION',new_id::text,
 jsonb_build_object('target',target.id,'permission',p_permission,'expiry',p_valid_until));
 return new_id;
end$$;
revoke all on function public.owner_grant_staff_permission(uuid,text,text,timestamptz) from public,anon;
grant execute on function public.owner_grant_staff_permission(uuid,text,text,timestamptz) to authenticated;
