-- TORVO V2 owner-controlled read of central business settings.
-- Apply after v2-owner-delegated-permissions.sql.
create or replace function admin_control_snapshot() returns jsonb language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v jsonb;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or not public.owner_has_staff_permission('website.edit') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 select jsonb_build_object('delivery',to_jsonb(d),'public',to_jsonb(p),'portal',to_jsonb(pc),'tax',to_jsonb(t)) into v from delivery_settings d cross join business_public_settings p cross join portal_content_settings pc cross join tax_settings t where d.id=true and p.id=true and pc.id=true and t.id=true;return v;end$$;
revoke all on function admin_control_snapshot() from public,anon;grant execute on function admin_control_snapshot() to authenticated;

