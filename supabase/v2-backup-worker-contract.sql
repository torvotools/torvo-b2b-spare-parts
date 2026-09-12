-- TORVO V2 trusted backup worker contract + restore manifest registry.
-- Run after v2-backup-control.sql and v2-backup-channels.sql.
-- Browser/authenticated roles must never receive execute permission on worker completion functions.

alter table backup_runs add column if not exists worker_job_id text;
alter table backup_runs add column if not exists artifact_reference text;
alter table backup_runs add column if not exists artifact_expires_at timestamptz;
alter table backup_runs add column if not exists verification_details jsonb not null default '{}'::jsonb;
alter table backup_runs add column if not exists worker_completed_at timestamptz;

create unique index if not exists idx_backup_runs_worker_job on backup_runs(worker_job_id) where worker_job_id is not null;

create table if not exists backup_restore_manifests(
 id uuid primary key default gen_random_uuid(),
 backup_run_id uuid not null unique references backup_runs(id) on delete restrict,
 schema_version text not null,
 database_version text not null,
 code_branch text not null,
 code_commit text not null,
 checksum_sha256 text not null check(checksum_sha256 ~ '^[A-Fa-f0-9]{64}$'),
 artifact_reference text not null,
 encrypted boolean not null default true check(encrypted=true),
 includes_secrets boolean not null default false check(includes_secrets=false),
 manifest jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 verified_at timestamptz
);
alter table backup_restore_manifests enable row level security;
revoke all on backup_restore_manifests from anon,authenticated;

create or replace function get_backup_health()
returns table(health text,last_verified_at timestamptz,age_hours numeric,pending_requests bigint,failed_runs bigint)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;v_last timestamptz;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;
 select max(verified_at) into v_last from backup_runs where status='verified' and verified_at is not null;
 return query select
  case when v_last is null then 'critical' when now()-v_last>=interval '48 hours' then 'critical' when now()-v_last>=interval '24 hours' then 'warning' else 'healthy' end,
  v_last,
  case when v_last is null then null else round(extract(epoch from (now()-v_last))/3600.0,1) end,
  (select count(*) from backup_runs where status in('requested','running')),
  (select count(*) from backup_runs where status='failed' and requested_at>=now()-interval '7 days');
end;$$;
revoke all on function get_backup_health() from public,anon;grant execute on function get_backup_health() to authenticated;

-- Service-role/trusted-worker only. Do not grant these functions to authenticated/anon.
create or replace function worker_start_backup(p_backup_id uuid,p_worker_job_id text)
returns void language plpgsql security definer set search_path=public as $$
begin
 if nullif(trim(p_worker_job_id),'') is null then raise exception 'Worker job id required';end if;
 update backup_runs set status='running',started_at=coalesce(started_at,now()),worker_job_id=coalesce(worker_job_id,trim(p_worker_job_id))
 where id=p_backup_id and status in('requested','running') and (worker_job_id is null or worker_job_id=trim(p_worker_job_id));
 if not found then raise exception 'Backup unavailable or worker mismatch';end if;
end;$$;
revoke all on function worker_start_backup(uuid,text) from public,anon,authenticated;

create or replace function worker_complete_backup(
 p_backup_id uuid,p_worker_job_id text,p_storage_provider text,p_artifact_reference text,p_checksum_sha256 text,
 p_file_size_bytes bigint,p_database_version text,p_schema_version text,p_code_branch text,p_code_commit text,
 p_manifest jsonb default '{}'::jsonb,p_verification_details jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path=public as $$
declare b backup_runs%rowtype;begin
 if p_checksum_sha256 !~ '^[A-Fa-f0-9]{64}$' then raise exception 'Invalid SHA256 checksum';end if;
 if coalesce(p_file_size_bytes,0)<=0 then raise exception 'Invalid artifact size';end if;
 if nullif(trim(p_artifact_reference),'') is null then raise exception 'Artifact reference required';end if;
 select * into b from backup_runs where id=p_backup_id for update;
 if not found then raise exception 'Backup not found';end if;
 if b.status='verified' then
  if b.worker_job_id=trim(p_worker_job_id) and lower(b.checksum_sha256)=lower(p_checksum_sha256) then return;end if;
  raise exception 'Verified backup cannot be replaced';
 end if;
 if b.status not in('requested','running','completed') then raise exception 'Backup cannot be completed from current state';end if;
 if b.worker_job_id is not null and b.worker_job_id<>trim(p_worker_job_id) then raise exception 'Worker mismatch';end if;
 update backup_runs set status='verified',worker_job_id=trim(p_worker_job_id),storage_provider=nullif(trim(p_storage_provider),''),
  storage_reference=trim(p_artifact_reference),artifact_reference=trim(p_artifact_reference),checksum_sha256=lower(p_checksum_sha256),
  code_branch=trim(p_code_branch),code_commit=trim(p_code_commit),database_version=trim(p_database_version),file_size_bytes=p_file_size_bytes,
  encrypted=true,includes_secrets=false,completed_at=coalesce(completed_at,now()),worker_completed_at=now(),verified_at=now(),verification_details=coalesce(p_verification_details,'{}'::jsonb),error_message=null
 where id=p_backup_id;
 if b.backup_type='full_restore_point' then
  insert into backup_restore_manifests(backup_run_id,schema_version,database_version,code_branch,code_commit,checksum_sha256,artifact_reference,encrypted,includes_secrets,manifest,verified_at)
  values(p_backup_id,trim(p_schema_version),trim(p_database_version),trim(p_code_branch),trim(p_code_commit),lower(p_checksum_sha256),trim(p_artifact_reference),true,false,coalesce(p_manifest,'{}'::jsonb),now())
  on conflict(backup_run_id) do nothing;
 end if;
 if b.project_change_id is not null then update project_backup_changes set backed_up_at=now() where id=b.project_change_id and backup_run_id=p_backup_id;end if;
end;$$;
revoke all on function worker_complete_backup(uuid,text,text,text,text,bigint,text,text,text,text,jsonb,jsonb) from public,anon,authenticated;

create or replace function worker_fail_backup(p_backup_id uuid,p_worker_job_id text,p_error text)
returns void language plpgsql security definer set search_path=public as $$
begin
 update backup_runs set status='failed',worker_job_id=coalesce(worker_job_id,trim(p_worker_job_id)),completed_at=now(),worker_completed_at=now(),error_message=left(coalesce(p_error,'Backup worker failed'),2000)
 where id=p_backup_id and status in('requested','running','completed') and (worker_job_id is null or worker_job_id=trim(p_worker_job_id));
 if not found then raise exception 'Backup unavailable or worker mismatch';end if;
end;$$;
revoke all on function worker_fail_backup(uuid,text,text) from public,anon,authenticated;
