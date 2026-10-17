-- TORVO V2: revoke every unrevoked grant for the selected staff/permission pair.
-- Preserves existing RPC signature and Owner-only authorization.
create or replace function public.owner_revoke_staff_permission(p_grant_id uuid,p_reason text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare actor public.app_users%rowtype; selected_grant public.owner_staff_permission_grants%rowtype; revoked_count integer;
begin
 select * into actor from public.app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role<>'owner' then raise exception 'OWNER REQUIRED'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 then raise exception 'CHANGE REASON REQUIRED'; end if;
 select * into selected_grant from public.owner_staff_permission_grants where id=p_grant_id;
 if selected_grant.id is null then return false; end if;
 perform pg_advisory_xact_lock(hashtextextended(selected_grant.staff_user_id::text || ':' || selected_grant.permission_key,0));
 update public.owner_staff_permission_grants
 set revoked_at=now(),revoked_by=actor.id
 where staff_user_id=selected_grant.staff_user_id and permission_key=selected_grant.permission_key
 and revoked_at is null;
 get diagnostics revoked_count=row_count;
 if revoked_count=0 then return false; end if;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
 values(actor.id,'STAFF_PERMISSION_REVOKED','STAFF_PERMISSION',p_grant_id::text,
 jsonb_build_object('reason',btrim(p_reason),'target',selected_grant.staff_user_id,
 'permission',selected_grant.permission_key,'revoked_grants',revoked_count));
 return true;
end$$;
revoke all on function public.owner_revoke_staff_permission(uuid,text) from public,anon;
grant execute on function public.owner_revoke_staff_permission(uuid,text) to authenticated;
