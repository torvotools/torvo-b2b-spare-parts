-- TORVO V2 backup control registry. Metadata/control only: database dump creation must run in a trusted server/backup worker, never the browser.
-- Staging test required before production.
create table if not exists backup_runs(
 id uuid primary key default gen_random_uuid(),
 backup_type text not null check(backup_type in('database','full_restore_point','configuration')),
 status text not null default 'requested' check(status in('requested','running','completed','verified','failed')),
 requested_by uuid references app_users(id),
 requested_at timestamptz not null default now(),started_at timestamptz,completed_at timestamptz,verified_at timestamptz,
 storage_provider text,storage_reference text,checksum_sha256 text,code_branch text,code_commit text,database_version text,
 encrypted boolean not null default true,includes_secrets boolean not null default false,
 file_size_bytes bigint,notes text,error_message text,
 constraint backup_runs_no_secrets check(includes_secrets=false)
);
create index if not exists idx_backup_runs_recent on backup_runs(requested_at desc);
alter table backup_runs enable row level security;revoke all on backup_runs from anon,authenticated;

create or replace function get_backup_control_status()
returns table(id uuid,backup_type text,status text,requested_at timestamptz,completed_at timestamptz,verified_at timestamptz,storage_provider text,checksum_sha256 text,code_branch text,code_commit text,encrypted boolean,file_size_bytes bigint,error_message text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;return query select b.id,b.backup_type,b.status,b.requested_at,b.completed_at,b.verified_at,b.storage_provider,b.checksum_sha256,b.code_branch,b.code_commit,b.encrypted,b.file_size_bytes,b.error_message from backup_runs b order by b.requested_at desc limit 100;end;$$;
revoke all on function get_backup_control_status() from public,anon;grant execute on function get_backup_control_status() to authenticated;

create or replace function request_backup_run(p_type text,p_notes text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;bid uuid;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;if p_type not in('database','full_restore_point','configuration') then raise exception 'Invalid backup type';end if;insert into backup_runs(backup_type,requested_by,notes,encrypted,includes_secrets) values(p_type,a.id,nullif(trim(p_notes),''),true,false) returning id into bid;insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'BACKUP_REQUESTED','backup_run',bid::text,jsonb_build_object('backup_type',p_type));return bid;end;$$;
revoke all on function request_backup_run(text,text) from public,anon;grant execute on function request_backup_run(text,text) to authenticated;

-- Trusted backup worker/service updates status using server credentials. Browser roles intentionally receive no direct UPDATE/INSERT/DELETE table grant.
