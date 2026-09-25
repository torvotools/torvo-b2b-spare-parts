-- TORVO V2 DEALER DEVICE SESSION FOUNDATION
-- Authentication credential is registered-email OTP. This file contains no PIN/mobile login.
create table if not exists dealer_device_sessions(
 id uuid primary key default gen_random_uuid(),
 dealer_id uuid not null references dealers(id) on delete cascade,
 device_id text not null,
 session_token_hash text not null,
 created_at timestamptz not null default now(),
 last_seen_at timestamptz not null default now(),
 expires_at timestamptz not null,
 revoked_at timestamptz,
 revoke_reason text
);
alter table dealer_device_sessions enable row level security;
revoke all on table dealer_device_sessions from public,anon,authenticated;
create unique index if not exists uq_dealer_one_active_device on dealer_device_sessions(dealer_id) where revoked_at is null;
create index if not exists idx_dealer_device_session_token on dealer_device_sessions(session_token_hash) where revoked_at is null;

create or replace function dealer_start_device_session(p_dealer_id uuid,p_device_id text,p_minutes integer default 43200)
returns table(session_token text,expires_at timestamptz) language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;raw text;exp timestamptz;
begin
 if length(btrim(coalesce(p_device_id,'')))<8 or length(p_device_id)>180 then raise exception 'SECURE_DEVICE_ID_REQUIRED';end if;
 if p_minutes<60 or p_minutes>43200 then raise exception 'INVALID_SESSION_DURATION';end if;
 select * into d from dealers where id=p_dealer_id and lower(coalesce(status,''))='approved' for update;
 if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;
 perform pg_advisory_xact_lock(hashtext(p_dealer_id::text));
 update dealer_device_sessions set revoked_at=now(),revoke_reason='NEW_DEVICE_LOGIN' where dealer_id=p_dealer_id and revoked_at is null;
 raw:=encode(gen_random_bytes(32),'hex');exp:=now()+make_interval(mins=>p_minutes);
 insert into dealer_device_sessions(dealer_id,device_id,session_token_hash,expires_at) values(p_dealer_id,btrim(p_device_id),encode(digest(raw,'sha256'),'hex'),exp);
 return query select raw,exp;
end$$;

create or replace function dealer_validate_device_session(p_dealer_id uuid,p_device_id text,p_session_token text)
returns boolean language plpgsql security definer set search_path=public as $$
declare sid uuid;
begin
 if length(btrim(coalesce(p_device_id,'')))<8 or length(coalesce(p_device_id,''))>180 or length(coalesce(p_session_token,''))<32 then return false;end if;
 select s.id into sid from dealer_device_sessions s join dealers d on d.id=s.dealer_id where s.dealer_id=p_dealer_id and s.device_id=btrim(coalesce(p_device_id,'')) and s.session_token_hash=encode(digest(coalesce(p_session_token,''),'sha256'),'hex') and s.revoked_at is null and s.expires_at>now() and lower(coalesce(d.status,''))='approved' limit 1;
 if sid is null then return false;end if;
 update dealer_device_sessions set last_seen_at=now() where id=sid;return true;
end$$;

create or replace function dealer_revoke_device_sessions(p_dealer_id uuid,p_reason text default 'LOGOUT')
returns void language plpgsql security definer set search_path=public as $$
begin update dealer_device_sessions set revoked_at=now(),revoke_reason=left(coalesce(nullif(btrim(p_reason),''),'LOGOUT'),80) where dealer_id=p_dealer_id and revoked_at is null;end$$;

revoke all on function dealer_start_device_session(uuid,text,integer) from public,anon,authenticated;
revoke all on function dealer_validate_device_session(uuid,text,text) from public,anon,authenticated;
revoke all on function dealer_revoke_device_sessions(uuid,text) from public,anon,authenticated;
grant execute on function dealer_start_device_session(uuid,text,integer) to service_role;
grant execute on function dealer_validate_device_session(uuid,text,text) to service_role;
grant execute on function dealer_revoke_device_sessions(uuid,text) to service_role;
