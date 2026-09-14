-- TORVO V2 MASTER SALESMAN ACCESS
-- OWNER/ADMIN explicitly grants/revokes all-dealer field visibility. Normal salesman remains mapped-only.
create table if not exists master_salesman_access(
 app_user_id uuid primary key references app_users(id) on delete cascade,
 active boolean not null default true,
 granted_by uuid not null references app_users(id),
 granted_at timestamptz not null default now(),
 revoked_at timestamptz,
 updated_at timestamptz not null default now()
);
alter table master_salesman_access enable row level security;
revoke all on master_salesman_access from anon,authenticated;

create or replace function admin_set_master_salesman(p_app_user_id uuid,p_enabled boolean)
returns void language plpgsql security definer set search_path=public as $$declare actor app_users%rowtype;target app_users%rowtype;begin
 select * into actor from app_users where auth_user_id=auth.uid() and active=true;
 if actor.id is null or actor.role not in('owner','admin') then raise exception 'ADMIN REQUIRED';end if;
 select * into target from app_users where id=p_app_user_id and active=true;
 if target.id is null or target.role not in('owner','salesman') then raise exception 'OWNER OR SALESMAN REQUIRED';end if;
 insert into master_salesman_access(app_user_id,active,granted_by,granted_at,revoked_at,updated_at)
 values(target.id,p_enabled,actor.id,now(),case when p_enabled then null else now() end,now())
 on conflict(app_user_id) do update set active=excluded.active,granted_by=actor.id,granted_at=case when p_enabled then now() else master_salesman_access.granted_at end,revoked_at=case when p_enabled then null else now() end,updated_at=now();
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(actor.id,case when p_enabled then 'MASTER_SALESMAN_GRANTED' else 'MASTER_SALESMAN_REVOKED' end,'app_user',target.id::text,jsonb_build_object('enabled',p_enabled));
end$$;

create or replace function is_master_salesman() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from app_users u join master_salesman_access m on m.app_user_id=u.id where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','salesman') and m.active=true and m.revoked_at is null)
$$;

create or replace function salesman_visible_dealers()
returns table(dealer_id uuid,shop_name text,mobile text,status text)
language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;master boolean;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','salesman') then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 master:=is_master_salesman();
 return query select d.id,d.shop_name,d.mobile,d.status from dealers d where d.status='approved' and (master or exists(select 1 from dealer_salesman_map x where x.dealer_id=d.id and x.salesman_user_id=u.id and x.active=true)) order by d.shop_name;
end$$;

revoke all on function admin_set_master_salesman(uuid,boolean) from public,anon;grant execute on function admin_set_master_salesman(uuid,boolean) to authenticated;
revoke all on function is_master_salesman() from public,anon;grant execute on function is_master_salesman() to authenticated;
revoke all on function salesman_visible_dealers() from public,anon;grant execute on function salesman_visible_dealers() to authenticated;
