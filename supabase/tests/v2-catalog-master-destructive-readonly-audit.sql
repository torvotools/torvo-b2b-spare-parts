-- TORVO V2 CATALOG MASTER DESTRUCTIVE-ACTION READ-ONLY STAGING AUDIT
-- STAGING ONLY. This file does not mutate catalog data and does not install missing functions.
-- A missing permanent-delete RPC is a FAIL/OPEN runtime gate, never a source-level PASS.

select
 to_regprocedure('public.catalog_master_usage(uuid)') as usage_rpc,
 to_regprocedure('public.save_catalog_master(uuid,text,text,boolean)') as save_rpc,
 to_regprocedure('public.delete_catalog_master(uuid,text)') as trash_rpc,
 to_regprocedure('public.restore_catalog_master(uuid)') as restore_rpc,
 to_regprocedure('public.permanently_delete_catalog_master(uuid,text)') as permanent_delete_rpc;

select p.proname,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       has_function_privilege('public',p.oid,'EXECUTE') as public_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in('catalog_master_usage','save_catalog_master','delete_catalog_master','restore_catalog_master','permanently_delete_catalog_master')
order by p.proname,arguments;

select c.relname,c.relrowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname='catalog_master_values';

select grantee,privilege_type
from information_schema.role_table_grants
where table_schema='public' and table_name='catalog_master_values'
  and grantee in('anon','authenticated')
order by grantee,privilege_type;

select count(*) filter(where deleted_at is null) as active_master_rows,
       count(*) filter(where deleted_at is not null) as trash_master_rows
from catalog_master_values;

-- REQUIRED INTERPRETATION:
-- 1) permanent_delete_rpc must be non-null.
-- 2) public_execute and anon_execute must be false for every private master RPC.
-- 3) authenticated_execute may be true; each mutating RPC must still derive Owner/Admin from auth.uid().
-- 4) catalog_master_values must have RLS enabled and browser roles must have no INSERT/UPDATE/DELETE/TRUNCATE grants.
-- 5) Runtime destructive behavior (wrong code, not-in-trash, in-use, valid zero-usage delete) requires an authorized real staging Owner/Admin test.
-- 6) This audit alone never marks permanent-delete runtime acceptance PASS.
