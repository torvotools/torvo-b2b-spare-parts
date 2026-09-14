-- TORVO V2 DEALER PIN AUTH FOUNDATION
-- ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION AT A TIME.
-- A SUCCESSFUL LOGIN ON A NEW DEVICE REVOKES THE PREVIOUS DEALER DEVICE SESSION.
-- DEALER LOGIN IS SEPARATE FROM STAFF WHATSAPP OTP. PIN IS NEVER STORED IN PLAINTEXT.
create extension if not exists pgcrypto;

create table if not exists dealer_login_credentials(
 dealer_id uuid primary key references dealers(id) on delete cascade,
 pin_hash text,pin_set_at timestamptz,failed_attempts integer not null default 0 check(failed_attempts>=0),locked_until timestamptz,updated_at timestamptz not null default now()
);alter table dealer_login_credentials enable row level security;

create table if not exists dealer_device_sessions(
 id uuid primary key default gen_random_uuid(),dealer_id uuid not null references dealers(id) on delete cascade,device_id text not null,
 session_token_hash text not null,created_at timestamptz not null default now(),last_seen_at timestamptz not null default now(),expires_at timestamptz not null,revoked_at timestamptz,revoke_reason text
);alter table dealer_device_sessions enable row level security;
create unique index if not exists uq_dealer_one_active_device on dealer_device_sessions(dealer_id) where revoked_at is null;
create index if not exists idx_dealer_device_session_token on dealer_device_sessions(session_token_hash) where revoked_at is null;

create table if not exists dealer_pin_recovery_challenges(
 id uuid primary key default gen_random_uuid(),dealer_id uuid not null references dealers(id) on delete cascade,verified_by text not null check(verified_by in('whatsapp_otp','admin_verified')),created_at timestamptz not null default now(),expires_at timestamptz not null,used_at timestamptz
);alter table dealer_pin_recovery_challenges enable row level security;create index if not exists idx_dealer_pin_recovery on dealer_pin_recovery_challenges(dealer_id,expires_at desc);

create or replace function dealer_set_pin(p_dealer_id uuid,p_pin text,p_recovery_challenge_id uuid default null)
returns void language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;c dealer_pin_recovery_challenges%rowtype;begin
 if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN_MUST_BE_4_DIGITS';end if;select * into d from dealers where id=p_dealer_id and status='approved';if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;
 if p_recovery_challenge_id is not null then select * into c from dealer_pin_recovery_challenges where id=p_recovery_challenge_id and dealer_id=d.id and used_at is null and expires_at>now() for update;if c.id is null then raise exception 'VERIFIED_RECOVERY_REQUIRED';end if;update dealer_pin_recovery_challenges set used_at=now() where id=c.id;end if;
 insert into dealer_login_credentials(dealer_id,pin_hash,pin_set_at,failed_attempts,locked_until,updated_at) values(d.id,crypt(p_pin,gen_salt('bf')),now(),0,null,now()) on conflict(dealer_id) do update set pin_hash=excluded.pin_hash,pin_set_at=now(),failed_attempts=0,locked_until=null,updated_at=now();
 update dealer_device_sessions set revoked_at=now(),revoke_reason='PIN_CHANGED' where dealer_id=d.id and revoked_at is null;
end$$;

create or replace function dealer_verify_pin(p_mobile text,p_pin text)
returns uuid language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;c dealer_login_credentials%rowtype;m text;v_count integer;begin
 m:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);if length(m)<>10 or p_pin !~ '^[0-9]{4}$' then raise exception 'INVALID_LOGIN';end if;
 select count(*) into v_count from dealers where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and status='approved';if v_count<>1 then raise exception 'INVALID_LOGIN';end if;
 select * into d from dealers where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and status='approved' limit 1;select * into c from dealer_login_credentials where dealer_id=d.id for update;
 if c.dealer_id is null or c.pin_hash is null then raise exception 'PIN_SETUP_REQUIRED';end if;if c.locked_until is not null and c.locked_until>now() then raise exception 'LOGIN_TEMPORARILY_LOCKED';end if;
 if crypt(p_pin,c.pin_hash)<>c.pin_hash then update dealer_login_credentials set failed_attempts=failed_attempts+1,locked_until=case when failed_attempts+1>=5 then now()+interval '15 minutes' else null end,updated_at=now() where dealer_id=d.id;raise exception 'INVALID_LOGIN';end if;
 update dealer_login_credentials set failed_attempts=0,locked_until=null,updated_at=now() where dealer_id=d.id;return d.id;
end$$;

-- TRUSTED SERVER ONLY: call after dealer_verify_pin. Raw token is returned once; only its hash is stored.
create or replace function dealer_start_device_session(p_dealer_id uuid,p_device_id text,p_minutes integer default 43200)
returns table(session_token text,expires_at timestamptz) language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;raw text;exp timestamptz;begin
 if length(btrim(coalesce(p_device_id,'')))<8 or length(p_device_id)>180 then raise exception 'SECURE_DEVICE_ID_REQUIRED';end if;if p_minutes<60 or p_minutes>43200 then raise exception 'INVALID_SESSION_DURATION';end if;
 select * into d from dealers where id=p_dealer_id and status='approved';if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;
 perform pg_advisory_xact_lock(hashtext(p_dealer_id::text));update dealer_device_sessions set revoked_at=now(),revoke_reason='NEW_DEVICE_LOGIN' where dealer_id=p_dealer_id and revoked_at is null;
 raw:=encode(gen_random_bytes(32),'hex');exp:=now()+make_interval(mins=>p_minutes);insert into dealer_device_sessions(dealer_id,device_id,session_token_hash,expires_at) values(p_dealer_id,btrim(p_device_id),encode(digest(raw,'sha256'),'hex'),exp);return query select raw,exp;
end$$;

-- TRUSTED SERVER ONLY: validates that this exact dealer/device session is still the single active session.
create or replace function dealer_validate_device_session(p_dealer_id uuid,p_device_id text,p_session_token text)
returns boolean language plpgsql security definer set search_path=public as $$
declare sid uuid;begin
 select id into sid from dealer_device_sessions where dealer_id=p_dealer_id and device_id=btrim(coalesce(p_device_id,'')) and session_token_hash=encode(digest(coalesce(p_session_token,''),'sha256'),'hex') and revoked_at is null and expires_at>now() limit 1;
 if sid is null then return false;end if;update dealer_device_sessions set last_seen_at=now() where id=sid;return true;
end$$;

create or replace function dealer_revoke_device_sessions(p_dealer_id uuid,p_reason text default 'LOGOUT')
returns void language plpgsql security definer set search_path=public as $$begin update dealer_device_sessions set revoked_at=now(),revoke_reason=left(coalesce(nullif(btrim(p_reason),''),'LOGOUT'),80) where dealer_id=p_dealer_id and revoked_at is null;end$$;

create or replace function dealer_create_recovery_challenge(p_dealer_id uuid,p_verified_by text,p_minutes integer default 10)
returns uuid language plpgsql security definer set search_path=public as $$
declare d dealers%rowtype;rid uuid;begin if p_verified_by not in('whatsapp_otp','admin_verified') then raise exception 'VERIFICATION_REQUIRED';end if;if p_minutes<5 or p_minutes>30 then raise exception 'EXPIRY_MUST_BE_5_TO_30_MINUTES';end if;select * into d from dealers where id=p_dealer_id and status='approved';if d.id is null then raise exception 'APPROVED_DEALER_REQUIRED';end if;insert into dealer_pin_recovery_challenges(dealer_id,verified_by,expires_at) values(d.id,p_verified_by,now()+make_interval(mins=>p_minutes)) returning id into rid;return rid;end$$;

revoke all on function dealer_set_pin(uuid,text,uuid) from public,anon,authenticated;
revoke all on function dealer_verify_pin(text,text) from public,anon,authenticated;
revoke all on function dealer_start_device_session(uuid,text,integer) from public,anon,authenticated;
revoke all on function dealer_validate_device_session(uuid,text,text) from public,anon,authenticated;
revoke all on function dealer_revoke_device_sessions(uuid,text) from public,anon,authenticated;
revoke all on function dealer_create_recovery_challenge(uuid,text,integer) from public,anon,authenticated;
-- TRUSTED WORKER CONTRACT: verify PIN -> start device session -> establish real Supabase Dealer identity.
-- Every private Dealer request must validate the current device session. New-device login revokes the previous session.
