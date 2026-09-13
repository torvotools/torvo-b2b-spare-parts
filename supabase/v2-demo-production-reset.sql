-- TORVO V2 — SAFE DEMO -> FRESH PRODUCTION RESET CONTROL
-- INSTALL ONLY AFTER BACKUP/AUDIT FOUNDATIONS. OWNER ONLY.
-- This migration intentionally does NOT contain a generic DELETE-ALL RPC.

create table if not exists public.demo_reset_runs (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'DRAFT' check (status in ('DRAFT','READY','EXECUTED','CANCELLED')),
  requested_by uuid not null default auth.uid(),
  requested_at timestamptz not null default now(),
  executed_at timestamptz,
  backup_reference text,
  confirmation_hash text,
  scope jsonb not null default '{}'::jsonb,
  dry_run_report jsonb not null default '{}'::jsonb,
  preserved_config jsonb not null default '{}'::jsonb,
  notes text,
  constraint demo_reset_backup_before_ready check (status = 'DRAFT' or backup_reference is not null)
);

alter table public.demo_reset_runs enable row level security;
revoke all on public.demo_reset_runs from anon, authenticated;

-- Explicit registry: a table is never reset merely because it looks transactional.
-- Each table must be reviewed and deliberately registered before production reset.
create table if not exists public.demo_reset_registry (
  table_schema text not null default 'public',
  table_name text primary key,
  demo_marker_column text not null default 'is_demo',
  enabled boolean not null default false,
  delete_order integer not null,
  preserve_reason text,
  reviewed_at timestamptz,
  reviewed_by uuid
);

alter table public.demo_reset_registry enable row level security;
revoke all on public.demo_reset_registry from anon, authenticated;

comment on table public.demo_reset_runs is
'OWNER-controlled one-time demo reset audit. READY requires a backup reference. EXECUTION must use only explicitly reviewed demo_reset_registry rows and demo-tagged records.';
comment on table public.demo_reset_registry is
'Allowlist for demo cleanup. Disabled by default. Never infer reset scope from table names.';

-- Masters/config/auth/audit are deliberately not registered here.
-- Examples that must be preserved unless an OWNER explicitly chooses otherwise:
-- PRODUCT/BRAND/MACHINE/CATEGORY MASTERS, APPROVED RATES, PORTAL SETTINGS,
-- APP USERS/AUTH, MIGRATION HISTORY, AUDIT HISTORY, BACKUP HISTORY.

create or replace function public.demo_reset_dry_run()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  n bigint;
  report jsonb := '{}'::jsonb;
begin
  -- Supabase auth.uid() is the Auth identity. app_users.id is TORVO's internal user ID.
  -- Always authorize through app_users.auth_user_id; comparing app_users.id to auth.uid()
  -- would incorrectly reject a valid OWNER (or accidentally couple unrelated UUID domains).
  if not exists (
    select 1 from public.app_users u
    where u.auth_user_id = auth.uid()
      and lower(coalesce(u.role,'')) = 'owner'
      and coalesce(u.active,true)
  ) then
    raise exception 'OWNER ONLY';
  end if;

  for r in
    select table_schema, table_name, demo_marker_column
    from public.demo_reset_registry
    where enabled = true and reviewed_at is not null
    order by delete_order
  loop
    execute format('select count(*) from %I.%I where %I = true',
      r.table_schema, r.table_name, r.demo_marker_column) into n;
    report := report || jsonb_build_object(r.table_schema || '.' || r.table_name, n);
  end loop;
  return report;
end;
$$;

revoke all on function public.demo_reset_dry_run() from public, anon, authenticated;
grant execute on function public.demo_reset_dry_run() to authenticated;

-- IMPORTANT: destructive execution RPC is intentionally withheld until staging proves:
-- 1) every deletable table has deterministic is_demo tagging,
-- 2) FK-safe delete order is reviewed,
-- 3) backup + restore drill passes,
-- 4) dry-run counts are OWNER approved.
-- This prevents accidental deletion of real market data or approved masters.
