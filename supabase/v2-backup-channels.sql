-- TORVO V2 backup channels/settings + project-change restore package registry.
-- Run after v2-backup-control.sql. Actual artifacts/email delivery require a trusted worker.
alter table backup_runs add column if not exists backup_channel text;
alter table backup_runs add column if not exists delivery_email text;
alter table backup_runs add column if not exists restore_guide_included boolean not null default false;
alter table backup_runs add column if not exists project_change_id uuid;

create table if not exists backup_settings(
 id boolean primary key default true check(id=true),
 shutdown_email text,
 daily_email text,
 project_email text,
 daily_due_hours integer not null default 24 check(daily_due_hours between 1 and 168),
 shutdown_backup_required boolean not null default true,
 project_backup_required boolean not null default true,
 updated_by uuid references app_users(id),updated_at timestamptz not null default now()
);
insert into backup_settings(id) values(true) on conflict(id) do nothing;
alter table backup_settings enable row level security;revoke all on backup_settings from anon,authenticated;

create table if not exists project_backup_changes(
 id uuid primary key default gen_random_uuid(),
 code_branch text not null default 'torvo-v2-build',code_commit text not null,
 change_scope text[] not null default '{}',change_summary text not null,
 detected_at timestamptz not null default now(),backup_run_id uuid references backup_runs(id),backed_up_at timestamptz,
 unique(code_branch,code_commit)
);
create index if not exists idx_project_backup_changes_pending on project_backup_changes(detected_at desc) where backup_run_id is null;
alter table project_backup_changes enable row level security;revoke all on project_backup_changes from anon,authenticated;

create or replace function get_backup_settings()
returns table(shutdown_email text,daily_email text,project_email text,daily_due_hours integer,shutdown_backup_required boolean,project_backup_required boolean)
language plpgsql stable security definer set search_path=public as $$ declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;return query select s.shutdown_email,s.daily_email,s.project_email,s.daily_due_hours,s.shutdown_backup_required,s.project_backup_required from backup_settings s where s.id=true;end;$$;
revoke all on function get_backup_settings() from public,anon;grant execute on function get_backup_settings() to authenticated;

create or replace function save_backup_settings(p_shutdown_email text,p_daily_email text,p_project_email text,p_daily_due_hours integer default 24)
returns void language plpgsql security definer set search_path=public as $$ declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;if p_daily_due_hours<1 or p_daily_due_hours>168 then raise exception 'Invalid backup interval';end if;update backup_settings set shutdown_email=nullif(lower(trim(p_shutdown_email)),''),daily_email=nullif(lower(trim(p_daily_email)),''),project_email=nullif(lower(trim(p_project_email)),''),daily_due_hours=p_daily_due_hours,updated_by=a.id,updated_at=now() where id=true;insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'BACKUP_SETTINGS_UPDATED','backup_settings','global',jsonb_build_object('daily_due_hours',p_daily_due_hours));end;$$;
revoke all on function save_backup_settings(text,text,text,integer) from public,anon;grant execute on function save_backup_settings(text,text,text,integer) to authenticated;

create or replace function get_pending_project_backup_changes()
returns table(id uuid,code_branch text,code_commit text,change_scope text[],change_summary text,detected_at timestamptz)
language plpgsql stable security definer set search_path=public as $$ declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;return query select p.id,p.code_branch,p.code_commit,p.change_scope,p.change_summary,p.detected_at from project_backup_changes p where p.backup_run_id is null order by p.detected_at desc;end;$$;
revoke all on function get_pending_project_backup_changes() from public,anon;grant execute on function get_pending_project_backup_changes() to authenticated;

create or replace function request_channel_backup(p_channel text,p_project_change_id uuid default null,p_notes text default null)
returns uuid language plpgsql security definer set search_path=public as $$ declare a app_users%rowtype;s backup_settings%rowtype;bid uuid;btype text;mail text;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;if p_channel not in('shutdown','daily_24h','project_restore') then raise exception 'Invalid backup channel';end if;select * into s from backup_settings where id=true;btype:=case when p_channel='project_restore' then 'full_restore_point' else 'database' end;mail:=case p_channel when 'shutdown' then s.shutdown_email when 'daily_24h' then s.daily_email else s.project_email end;if p_channel='project_restore' and p_project_change_id is null then raise exception 'Project change is required';end if;if p_project_change_id is not null and not exists(select 1 from project_backup_changes where id=p_project_change_id and backup_run_id is null) then raise exception 'Project change unavailable or already backed up';end if;insert into backup_runs(backup_type,backup_channel,delivery_email,restore_guide_included,project_change_id,requested_by,notes,encrypted,includes_secrets) values(btype,p_channel,mail,p_channel='project_restore',p_project_change_id,a.id,nullif(trim(p_notes),''),true,false) returning id into bid;if p_project_change_id is not null then update project_backup_changes set backup_run_id=bid where id=p_project_change_id and backup_run_id is null;end if;insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'CHANNEL_BACKUP_REQUESTED','backup_run',bid::text,jsonb_build_object('channel',p_channel,'delivery_email',mail));return bid;end;$$;
revoke all on function request_channel_backup(text,uuid,text) from public,anon;grant execute on function request_channel_backup(text,uuid,text) to authenticated;
