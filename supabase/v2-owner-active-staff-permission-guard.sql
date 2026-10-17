-- TORVO V2: Only active staff roles may consume delegated permissions.
-- Owner retains master authority. Inactive/dealer accounts cannot inherit staff grants.
create or replace function public.owner_has_staff_permission(p_permission text)
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
 select exists (
  select 1 from public.app_users u
  where u.auth_user_id=auth.uid() and u.active=true
  and (u.role='owner' or
   (u.role in ('admin','salesman','accountant','store_keeper')
    and exists (
     select 1 from public.owner_staff_permission_grants g
     join public.owner_delegable_permission_catalog pc on pc.permission_key=g.permission_key
     where g.staff_user_id=u.id and g.permission_key=p_permission and pc.active=true
     and g.revoked_at is null and g.valid_from<=now()
     and (g.valid_until is null or g.valid_until>now())
    )
   )
  )
 )
$$;
revoke all on function public.owner_has_staff_permission(text) from public,anon;
grant execute on function public.owner_has_staff_permission(text) to authenticated;
