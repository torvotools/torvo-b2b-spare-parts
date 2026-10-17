-- TORVO V2: Owner-only listing must not leak full staff permission history
-- when the owner panel has not selected a staff member.
create or replace function public.owner_list_staff_permissions(p_staff_user_id uuid default null)
returns table(grant_id uuid,staff_user_id uuid,permission_key text,valid_from timestamptz,valid_until timestamptz,revoked_at timestamptz,granted_by uuid,reason text)
language plpgsql security definer set search_path=public,pg_temp as $$
declare actor_id uuid;
begin
 select id into actor_id from public.app_users
 where auth_user_id=auth.uid() and active=true and role='owner';
 if actor_id is null then raise exception 'OWNER REQUIRED'; end if;
 if p_staff_user_id is null then return; end if;
 return query select g.id,g.staff_user_id,g.permission_key,g.valid_from,g.valid_until,g.revoked_at,g.granted_by,g.reason
 from public.owner_staff_permission_grants g
 where g.staff_user_id=p_staff_user_id order by g.created_at desc;
end$$;
revoke all on function public.owner_list_staff_permissions(uuid) from public,anon;
grant execute on function public.owner_list_staff_permissions(uuid) to authenticated;
