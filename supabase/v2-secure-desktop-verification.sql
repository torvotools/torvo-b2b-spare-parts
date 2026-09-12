-- TORVO V2 SECURE DESKTOP VERIFICATION
-- Run after v2-schema.sql. Owner/Admin/Accountant require a second verification after normal auth.
-- This migration stores only hashes. Never store or log raw verification codes.

create extension if not exists pgcrypto;

create table if not exists secure_desktop_verification_challenges(
 id uuid primary key default gen_random_uuid(),
 app_user_id uuid not null references app_users(id) on delete cascade,
 code_hash text not null,
 expires_at timestamptz not null,
 attempts integer not null default 0 check(attempts>=0),
 max_attempts integer not null default 5 check(max_attempts between 1 and 10),
 consumed_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists idx_secure_desktop_challenge_user on secure_desktop_verification_challenges(app_user_id,created_at desc);

create table if not exists secure_desktop_verified_sessions(
 id uuid primary key default gen_random_uuid(),
 app_user_id uuid not null references app_users(id) on delete cascade,
 auth_session_id text not null,
 verified_at timestamptz not null default now(),
 expires_at timestamptz not null,
 revoked_at timestamptz,
 unique(app_user_id,auth_session_id)
);
create index if not exists idx_secure_desktop_session_expiry on secure_desktop_verified_sessions(app_user_id,expires_at);

-- Audit has no raw code.
create table if not exists secure_desktop_verification_audit(
 id bigint generated always as identity primary key,
 app_user_id uuid references app_users(id) on delete set null,
 event_type text not null check(event_type in('challenge_created','verify_success','verify_failed','session_revoked')),
 challenge_id uuid,
 created_at timestamptz not null default now()
);

create or replace function secure_desktop_is_verified(p_auth_session_id text)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role not in('owner','admin','accountant') then return false; end if;
 return exists(select 1 from secure_desktop_verified_sessions s where s.app_user_id=v_user.id and s.auth_session_id=p_auth_session_id and s.revoked_at is null and s.expires_at>now());
end$$;

-- Challenge creation deliberately accepts a code only from a trusted server/provider worker.
-- Do NOT expose this RPC to browser roles. Provider worker generates/delivers the code then calls this function with service credentials.
create or replace function secure_desktop_create_challenge(p_app_user_id uuid,p_plain_code text,p_minutes integer default 10)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
 if p_plain_code is null or length(p_plain_code)<4 then raise exception 'INVALID CODE';end if;
 insert into secure_desktop_verification_challenges(app_user_id,code_hash,expires_at)
 values(p_app_user_id,crypt(p_plain_code,gen_salt('bf')),now()+make_interval(mins=>greatest(2,least(coalesce(p_minutes,10),15)))) returning id into v_id;
 insert into secure_desktop_verification_audit(app_user_id,event_type,challenge_id) values(p_app_user_id,'challenge_created',v_id);
 return v_id;
end$$;
revoke all on function secure_desktop_create_challenge(uuid,text,integer) from public,anon,authenticated;

create or replace function secure_desktop_verify_code(p_challenge_id uuid,p_code text,p_auth_session_id text)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_ch secure_desktop_verification_challenges%rowtype;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role not in('owner','admin','accountant') then raise exception 'SECURE DESKTOP ROLE REQUIRED';end if;
 select * into v_ch from secure_desktop_verification_challenges where id=p_challenge_id and app_user_id=v_user.id for update;
 if v_ch.id is null or v_ch.consumed_at is not null or v_ch.expires_at<=now() or v_ch.attempts>=v_ch.max_attempts then raise exception 'CHALLENGE EXPIRED OR CLOSED';end if;
 update secure_desktop_verification_challenges set attempts=attempts+1 where id=v_ch.id;
 if crypt(coalesce(p_code,''),v_ch.code_hash)<>v_ch.code_hash then
  insert into secure_desktop_verification_audit(app_user_id,event_type,challenge_id) values(v_user.id,'verify_failed',v_ch.id);return false;
 end if;
 update secure_desktop_verification_challenges set consumed_at=now() where id=v_ch.id;
 insert into secure_desktop_verified_sessions(app_user_id,auth_session_id,verified_at,expires_at,revoked_at)
 values(v_user.id,p_auth_session_id,now(),now()+interval '8 hours',null)
 on conflict(app_user_id,auth_session_id) do update set verified_at=excluded.verified_at,expires_at=excluded.expires_at,revoked_at=null;
 insert into secure_desktop_verification_audit(app_user_id,event_type,challenge_id) values(v_user.id,'verify_success',v_ch.id);return true;
end$$;

create or replace function secure_desktop_revoke(p_auth_session_id text)
returns void language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;
begin
 select * into v_user from app_users where auth_user_id=auth.uid();
 if v_user.id is null then return;end if;
 update secure_desktop_verified_sessions set revoked_at=coalesce(revoked_at,now()) where app_user_id=v_user.id and auth_session_id=p_auth_session_id and revoked_at is null;
 insert into secure_desktop_verification_audit(app_user_id,event_type) values(v_user.id,'session_revoked');
end$$;

grant execute on function secure_desktop_is_verified(text) to authenticated;
grant execute on function secure_desktop_verify_code(uuid,text,text) to authenticated;
grant execute on function secure_desktop_revoke(text) to authenticated;

alter table secure_desktop_verification_challenges enable row level security;
alter table secure_desktop_verified_sessions enable row level security;
alter table secure_desktop_verification_audit enable row level security;
revoke all on secure_desktop_verification_challenges,secure_desktop_verified_sessions,secure_desktop_verification_audit from anon,authenticated;
