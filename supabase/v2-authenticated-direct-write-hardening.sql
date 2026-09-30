-- TORVO V2 AUTHENTICATED DIRECT-WRITE LEAST PRIVILEGE
-- Authoritative mutations are RPC-only. These tables have RLS and no direct authenticated write policies.
do $$
declare r record;
begin
 for r in
  select c.relname
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind='r' and c.relrowsecurity=true
    and not exists (
      select 1 from pg_policy p where p.polrelid=c.oid and p.polcmd in ('a','w','d','*')
    )
 loop
   execute format('revoke insert, update, delete, truncate on table public.%I from authenticated',r.relname);
 end loop;
end$$;
