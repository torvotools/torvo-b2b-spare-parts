-- Staff master OTP delivery email is Owner-only; staff.manage must not permit changing the destination.
create or replace function admin_set_staff_otp_email(p_email text)
returns void language plpgsql security definer set search_path=public,pg_catalog as $$
declare actor app_users%rowtype;e text:=lower(btrim(coalesce(p_email,'')));
begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role<>'owner' then raise exception 'ADMIN REQUIRED'; end if;
 if e !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then raise exception 'VALID EMAIL REQUIRED'; end if;
 update staff_email_otp_challenges set revoked_at=now() where consumed_at is null and revoked_at is null;
 insert into staff_otp_settings(singleton,master_email,updated_by) values(true,e,actor.id)
 on conflict(singleton) do update set master_email=excluded.master_email,updated_at=now(),updated_by=actor.id;
end$$;
revoke all on function admin_set_staff_otp_email(text) from public,anon;
grant execute on function admin_set_staff_otp_email(text) to authenticated;

