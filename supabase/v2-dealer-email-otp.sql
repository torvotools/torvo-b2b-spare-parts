-- TORVO V2 Dealer email identity/auth contract. Apply after dealer device-session/current_dealer_id foundations.
create sequence if not exists public.dealer_code_seq start with 11 increment by 1 minvalue 11;
create unique index if not exists dealers_dealer_code_ci_uq on public.dealers(lower(dealer_code)) where dealer_code is not null;
create unique index if not exists dealers_email_ci_uq on public.dealers(lower(btrim(email))) where email is not null and btrim(email)<>'';
create or replace function public.next_dealer_code() returns text language plpgsql security definer set search_path=public as $$declare n bigint;c text;begin loop n:=nextval('public.dealer_code_seq');c:='DI@'||lpad(n::text,5,'0');exit when not exists(select 1 from public.dealers where upper(dealer_code)=upper(c));end loop;return c;end$$;
revoke all on function public.next_dealer_code() from public,anon,authenticated;grant execute on function public.next_dealer_code() to service_role;
create table if not exists public.dealer_email_otp_challenges(id uuid primary key default gen_random_uuid(),dealer_id uuid not null references public.dealers(id) on delete cascade,app_user_id uuid not null references public.app_users(id) on delete cascade,email_normalized text not null,device_id text not null,otp_hash text not null,created_at timestamptz not null default now(),expires_at timestamptz not null,used_at timestamptz,revoked_at timestamptz,failed_attempts integer not null default 0);
alter table public.dealer_email_otp_challenges enable row level security;revoke all on table public.dealer_email_otp_challenges from public,anon,authenticated;grant select,insert,update on table public.dealer_email_otp_challenges to service_role;
create or replace function public.dealer_email_otp_begin(p_email text,p_device_id text,p_otp text) returns uuid language plpgsql security definer set search_path=public as $$declare e text;d dealers%rowtype;u app_users%rowtype;cid uuid;begin e:=lower(btrim(coalesce(p_email,'')));if e!~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' or length(btrim(coalesce(p_device_id,'')))<8 or p_otp!~'^[0-9]{6}$' then raise exception 'LOGIN_FAILED';end if;select * into d from dealers where lower(btrim(coalesce(email,'')))=e and status='approved';if not found then raise exception 'LOGIN_FAILED';end if;select * into u from app_users where dealer_id=d.id and active=true and lower(role)='dealer';if not found or (select count(*) from app_users where dealer_id=d.id and active=true and lower(role)='dealer')<>1 then raise exception 'LOGIN_FAILED';end if;if exists(select 1 from dealer_email_otp_challenges where dealer_id=d.id and device_id=p_device_id and created_at>now()-interval '45 seconds' and revoked_at is null) then raise exception 'LOGIN_FAILED';end if;update dealer_email_otp_challenges set revoked_at=now() where dealer_id=d.id and used_at is null and revoked_at is null;insert into dealer_email_otp_challenges(dealer_id,app_user_id,email_normalized,device_id,otp_hash,expires_at) values(d.id,u.id,e,p_device_id,crypt(p_otp,gen_salt('bf')),now()+interval '10 minutes') returning id into cid;return cid;end$$;
create or replace function public.dealer_email_otp_verify(p_challenge_id uuid,p_email text,p_device_id text,p_otp text) returns uuid language plpgsql security definer set search_path=public as $$declare c dealer_email_otp_challenges%rowtype;e text;begin e:=lower(btrim(coalesce(p_email,'')));select * into c from dealer_email_otp_challenges where id=p_challenge_id for update;if not found or c.used_at is not null or c.revoked_at is not null or c.expires_at<=now() or c.email_normalized<>e or c.device_id<>p_device_id or c.failed_attempts>=5 then raise exception 'LOGIN_FAILED';end if;if crypt(p_otp,c.otp_hash)<>c.otp_hash then update dealer_email_otp_challenges set failed_attempts=failed_attempts+1,revoked_at=case when failed_attempts+1>=5 then now() else revoked_at end where id=c.id;return null;end if;update dealer_email_otp_challenges set used_at=now() where id=c.id;return c.app_user_id;end$$;
revoke all on function public.dealer_email_otp_begin(text,text,text) from public,anon,authenticated;revoke all on function public.dealer_email_otp_verify(uuid,text,text,text) from public,anon,authenticated;grant execute on function public.dealer_email_otp_begin(text,text,text) to service_role;grant execute on function public.dealer_email_otp_verify(uuid,text,text,text) to service_role;
-- Email-change requests are RPC-only for writes; dealers may read only their own rows through RLS.
create table if not exists public.dealer_email_change_requests(id uuid primary key default gen_random_uuid(),dealer_id uuid not null references public.dealers(id) on delete cascade,dealer_code text not null,old_email text not null,new_email text not null,status text not null default 'pending' check(status in('pending','approved','rejected','cancelled')),requested_at timestamptz not null default now(),decided_at timestamptz,decided_by uuid references public.app_users(id),decision_note text);
alter table public.dealer_email_change_requests enable row level security;revoke all on table public.dealer_email_change_requests from public,anon,authenticated;grant select on table public.dealer_email_change_requests to authenticated;
drop policy if exists dealer_email_change_select_own on public.dealer_email_change_requests;create policy dealer_email_change_select_own on public.dealer_email_change_requests for select to authenticated using(dealer_id=public.current_dealer_id());
create unique index if not exists dealer_email_change_one_pending_uq on public.dealer_email_change_requests(dealer_id) where status='pending';
create or replace function public.request_my_dealer_email_change(p_dealer_code text,p_new_email text) returns uuid language plpgsql security definer set search_path=public as $$
declare d public.dealers%rowtype;e text;rid uuid;
begin
 d.id:=public.current_dealer_id();
 if d.id is null then raise exception 'DEALER_ACCESS_REQUIRED'; end if;
 select * into d from public.dealers where id=d.id and lower(coalesce(status,''))='approved';
 if not found then raise exception 'APPROVED_DEALER_REQUIRED'; end if;
 if upper(btrim(coalesce(p_dealer_code,'')))<>upper(btrim(coalesce(d.dealer_code,''))) then raise exception 'DEALER_CODE_MISMATCH'; end if;
 e:=lower(btrim(coalesce(p_new_email,'')));
 if e!~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then raise exception 'INVALID_EMAIL'; end if;
 if lower(btrim(coalesce(d.email,'')))=e then raise exception 'EMAIL_UNCHANGED'; end if;
 if exists(select 1 from public.dealers x where x.id<>d.id and lower(btrim(coalesce(x.email,'')))=e) then raise exception 'EMAIL_ALREADY_IN_USE'; end if;
 insert into public.dealer_email_change_requests(dealer_id,dealer_code,old_email,new_email) values(d.id,d.dealer_code,d.email,e) returning id into rid;
 return rid;
end$$;
create or replace function public.admin_decide_dealer_email_change(p_request_id uuid,p_approve boolean,p_note text default null) returns boolean language plpgsql security definer set search_path=public as $$
declare actor public.app_users%rowtype;r public.dealer_email_change_requests%rowtype;
begin
 select * into actor from public.app_users where auth_user_id=auth.uid() and active=true;
 if not found or lower(coalesce(actor.role,'')) not in('owner','admin') then raise exception 'OWNER_OR_ADMIN_REQUIRED'; end if;
 select * into r from public.dealer_email_change_requests where id=p_request_id and status='pending' for update;
 if not found then raise exception 'PENDING_REQUEST_NOT_FOUND'; end if;
 if p_approve then
  if exists(select 1 from public.dealers x where x.id<>r.dealer_id and lower(btrim(coalesce(x.email,'')))=lower(btrim(r.new_email))) then raise exception 'EMAIL_ALREADY_IN_USE'; end if;
  update public.dealers set email=lower(btrim(r.new_email)) where id=r.dealer_id;
  update public.dealer_email_change_requests set status='approved',decided_at=now(),decided_by=actor.id,decision_note=nullif(btrim(coalesce(p_note,'')),'') where id=r.id;
  perform public.dealer_revoke_device_sessions(r.dealer_id,'DEALER_EMAIL_CHANGED');
 else
  update public.dealer_email_change_requests set status='rejected',decided_at=now(),decided_by=actor.id,decision_note=nullif(btrim(coalesce(p_note,'')),'') where id=r.id;
 end if;
 return true;
end$$;
revoke all on function public.request_my_dealer_email_change(text,text) from public,anon;
grant execute on function public.request_my_dealer_email_change(text,text) to authenticated;
revoke all on function public.admin_decide_dealer_email_change(uuid,boolean,text) from public,anon;
grant execute on function public.admin_decide_dealer_email_change(uuid,boolean,text) to authenticated;
