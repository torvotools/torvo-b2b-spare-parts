-- TORVO V2 ADMIN / ACCOUNTANT EMAIL OTP AUTH
-- Trusted-worker only. Plain OTP is never stored.
create extension if not exists pgcrypto;

create table if not exists staff_email_otp_challenges(
 id uuid primary key default gen_random_uuid(),
 app_user_id uuid not null references app_users(id) on delete cascade,
 email_normalized text not null,
 otp_hash text not null,
 device_id text not null,
 created_at timestamptz not null default now(),
 expires_at timestamptz not null,
 resend_after timestamptz not null,
 consumed_at timestamptz,
 revoked_at timestamptz,
 failed_attempts integer not null default 0 check(failed_attempts between 0 and 5)
);
create index if not exists idx_staff_email_otp_active on staff_email_otp_challenges(app_user_id,created_at desc);
alter table staff_email_otp_challenges enable row level security;
revoke all on staff_email_otp_challenges from public,anon,authenticated;

alter table staff_access_identities add column if not exists login_email text;
create unique index if not exists uq_staff_access_login_email_username
 on staff_access_identities(lower(login_email),upper(username))
 where login_email is not null and active=true;

create or replace function admin_set_staff_login_email(p_app_user_id uuid,p_email text)
returns void language plpgsql security definer set search_path=public,pg_catalog as $$
declare actor app_users%rowtype;e text:=lower(btrim(coalesce(p_email,'')));
begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'ADMIN REQUIRED'; end if;
 if e !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then raise exception 'VALID EMAIL REQUIRED'; end if;
 if not exists(
   select 1 from staff_access_identities i join app_users a on a.id=i.app_user_id
   where i.app_user_id=p_app_user_id and i.active=true and a.active=true
   and lower(coalesce(a.role,'')) in('admin','accountant')
   and lower(coalesce(i.staff_role,''))=lower(a.role)
 ) then raise exception 'ELIGIBLE STAFF ACCESS REQUIRED'; end if;
 update staff_access_identities set login_email=e,updated_at=now(),updated_by=actor.id where app_user_id=p_app_user_id;
end$$;
revoke all on function admin_set_staff_login_email(uuid,text) from public,anon;
grant execute on function admin_set_staff_login_email(uuid,text) to authenticated;

create or replace function staff_email_otp_begin(p_email text,p_username text,p_device_id text,p_otp text)
returns uuid language plpgsql security definer set search_path=public,pg_catalog as $$
declare i staff_access_identities%rowtype;rid uuid;e text:=lower(btrim(coalesce(p_email,'')));d text:=btrim(coalesce(p_device_id,''));
begin
 if e !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' or length(d)<8 or length(d)>180 or p_otp !~ '^[0-9]{6}$' then raise exception 'INVALID LOGIN'; end if;
 select sai.* into i from staff_access_identities sai join app_users a on a.id=sai.app_user_id
 where upper(sai.username)=upper(btrim(coalesce(p_username,''))) and sai.active=true and a.active=true
 and lower(coalesce(a.role,'')) in('admin','accountant') and lower(coalesce(sai.staff_role,''))=lower(a.role)
 and lower(coalesce(sai.login_email,''))=e
 for update of sai;
 if i.app_user_id is null then raise exception 'INVALID LOGIN'; end if;
 perform 1 from staff_authorized_devices where app_user_id=i.app_user_id and device_id=d and device_type='desktop' and revoked_at is null;
 if not found then raise exception 'DEVICE APPROVAL REQUIRED'; end if;
 if exists(select 1 from staff_email_otp_challenges c where c.app_user_id=i.app_user_id and c.device_id=d and c.revoked_at is null and c.consumed_at is null and c.resend_after>now()) then raise exception 'RESEND WAIT REQUIRED'; end if;
 update staff_email_otp_challenges set revoked_at=now() where app_user_id=i.app_user_id and consumed_at is null and revoked_at is null;
 insert into staff_email_otp_challenges(app_user_id,email_normalized,otp_hash,device_id,expires_at,resend_after)
 values(i.app_user_id,e,crypt(p_otp,gen_salt('bf')),d,now()+interval '10 minutes',now()+interval '45 seconds') returning id into rid;
 return rid;
end$$;

create or replace function staff_email_otp_verify(p_challenge_id uuid,p_email text,p_username text,p_device_id text,p_otp text)
returns uuid language plpgsql security definer set search_path=public,pg_catalog as $$
declare c staff_email_otp_challenges%rowtype;i staff_access_identities%rowtype;
begin
 select * into c from staff_email_otp_challenges where id=p_challenge_id for update;
 if c.id is null or c.consumed_at is not null or c.revoked_at is not null or c.expires_at<=now() or c.failed_attempts>=5
 or c.device_id<>btrim(coalesce(p_device_id,'')) or c.email_normalized<>lower(btrim(coalesce(p_email,''))) then raise exception 'INVALID OR EXPIRED OTP'; end if;
 select i.* into i from staff_access_identities i join app_users a on a.id=i.app_user_id
 where i.app_user_id=c.app_user_id and upper(i.username)=upper(btrim(coalesce(p_username,'')))
 and lower(coalesce(i.login_email,''))=lower(btrim(coalesce(p_email,''))) and i.active=true and a.active=true
 and lower(coalesce(a.role,'')) in('admin','accountant') and lower(coalesce(i.staff_role,''))=lower(a.role);
 if i.app_user_id is null then raise exception 'INVALID OR EXPIRED OTP'; end if;
 perform 1 from staff_authorized_devices where app_user_id=i.app_user_id and device_id=c.device_id and device_type='desktop' and revoked_at is null;
 if not found then raise exception 'INVALID OR EXPIRED OTP'; end if;
 if crypt(coalesce(p_otp,''),c.otp_hash)<>c.otp_hash then
   update staff_email_otp_challenges
   set failed_attempts=least(5,failed_attempts+1),
       revoked_at=case when failed_attempts+1>=5 then now() else revoked_at end
   where id=c.id;
   return null;
 end if;
 update staff_email_otp_challenges set consumed_at=now() where id=c.id;
 return c.app_user_id;
end$$;

revoke all on function staff_email_otp_begin(text,text,text,text) from public,anon,authenticated;
revoke all on function staff_email_otp_verify(uuid,text,text,text,text) from public,anon,authenticated;
grant execute on function staff_email_otp_begin(text,text,text,text) to service_role;
grant execute on function staff_email_otp_verify(uuid,text,text,text,text) to service_role;
