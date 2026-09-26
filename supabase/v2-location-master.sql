-- TORVO V2 AUTHORITATIVE LOCATION MASTER
-- Dropdown-first foundation for STATE -> DISTRICT -> CITY across Website/App/Desktop/Admin.
create extension if not exists pgcrypto;

create table if not exists public.location_states(
 id uuid primary key default gen_random_uuid(),
 name text not null,
 active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists location_states_name_uq on public.location_states(upper(trim(name)));

create table if not exists public.location_districts(
 id uuid primary key default gen_random_uuid(),
 state_id uuid not null references public.location_states(id) on delete restrict,
 name text not null,
 active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists location_districts_state_name_uq on public.location_districts(state_id,upper(trim(name)));
create index if not exists location_districts_state_active_idx on public.location_districts(state_id,active,sort_order,name);

create table if not exists public.location_cities(
 id uuid primary key default gen_random_uuid(),
 district_id uuid not null references public.location_districts(id) on delete restrict,
 name text not null,
 active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists location_cities_district_name_uq on public.location_cities(district_id,upper(trim(name)));
create index if not exists location_cities_district_active_idx on public.location_cities(district_id,active,sort_order,name);

alter table public.location_states enable row level security;
alter table public.location_districts enable row level security;
alter table public.location_cities enable row level security;
revoke all on public.location_states from anon,authenticated;
revoke all on public.location_districts from anon,authenticated;
revoke all on public.location_cities from anon,authenticated;

create or replace function public.public_location_states()
returns table(id uuid,name text) language sql stable security definer set search_path=public as $$
 select s.id,upper(trim(s.name)) from location_states s where s.active order by s.sort_order,upper(trim(s.name));
$$;

create or replace function public.public_location_districts(p_state_id uuid)
returns table(id uuid,name text) language plpgsql stable security definer set search_path=public as $$begin
 if p_state_id is null then raise exception 'STATE REQUIRED';end if;
 if not exists(select 1 from location_states s where s.id=p_state_id and s.active) then raise exception 'VALID ACTIVE STATE REQUIRED';end if;
 return query select d.id,upper(trim(d.name)) from location_districts d where d.state_id=p_state_id and d.active order by d.sort_order,upper(trim(d.name));
end$$;

create or replace function public.public_location_cities(p_district_id uuid)
returns table(id uuid,name text) language plpgsql stable security definer set search_path=public as $$begin
 if p_district_id is null then raise exception 'DISTRICT REQUIRED';end if;
 if not exists(select 1 from location_districts d join location_states s on s.id=d.state_id where d.id=p_district_id and d.active and s.active) then raise exception 'VALID ACTIVE DISTRICT REQUIRED';end if;
 return query select c.id,upper(trim(c.name)) from location_cities c where c.district_id=p_district_id and c.active order by c.sort_order,upper(trim(c.name));
end$$;

grant execute on function public.public_location_states() to anon,authenticated;
grant execute on function public.public_location_districts(uuid) to anon,authenticated;
grant execute on function public.public_location_cities(uuid) to anon,authenticated;

create or replace function public.torvo_admin_upsert_location_state(p_id uuid,p_name text,p_active boolean default true,p_sort_order integer default 0)
returns uuid language plpgsql security definer set search_path=public as $$declare v_user uuid;v_id uuid;begin
 select id into v_user from app_users where auth_user_id=auth.uid() and lower(role) in('owner','admin') and coalesce(active,true) limit 1;
 if v_user is null then raise exception 'OWNER / ADMIN ACCESS REQUIRED';end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'STATE NAME REQUIRED';end if;
 if p_id is null then insert into location_states(name,active,sort_order) values(upper(trim(p_name)),coalesce(p_active,true),coalesce(p_sort_order,0)) returning id into v_id;
 else update location_states set name=upper(trim(p_name)),active=coalesce(p_active,true),sort_order=coalesce(p_sort_order,0),updated_at=now() where id=p_id returning id into v_id;if v_id is null then raise exception 'STATE NOT FOUND';end if;end if;
 return v_id;end$$;

create or replace function public.torvo_admin_upsert_location_district(p_id uuid,p_state_id uuid,p_name text,p_active boolean default true,p_sort_order integer default 0)
returns uuid language plpgsql security definer set search_path=public as $$declare v_user uuid;v_id uuid;begin
 select id into v_user from app_users where auth_user_id=auth.uid() and lower(role) in('owner','admin') and coalesce(active,true) limit 1;
 if v_user is null then raise exception 'OWNER / ADMIN ACCESS REQUIRED';end if;
 if not exists(select 1 from location_states where id=p_state_id) then raise exception 'VALID STATE REQUIRED';end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'DISTRICT NAME REQUIRED';end if;
 if p_id is null then insert into location_districts(state_id,name,active,sort_order) values(p_state_id,upper(trim(p_name)),coalesce(p_active,true),coalesce(p_sort_order,0)) returning id into v_id;
 else update location_districts set state_id=p_state_id,name=upper(trim(p_name)),active=coalesce(p_active,true),sort_order=coalesce(p_sort_order,0),updated_at=now() where id=p_id returning id into v_id;if v_id is null then raise exception 'DISTRICT NOT FOUND';end if;end if;
 return v_id;end$$;

create or replace function public.torvo_admin_upsert_location_city(p_id uuid,p_district_id uuid,p_name text,p_active boolean default true,p_sort_order integer default 0)
returns uuid language plpgsql security definer set search_path=public as $$declare v_user uuid;v_id uuid;begin
 select id into v_user from app_users where auth_user_id=auth.uid() and lower(role) in('owner','admin') and coalesce(active,true) limit 1;
 if v_user is null then raise exception 'OWNER / ADMIN ACCESS REQUIRED';end if;
 if not exists(select 1 from location_districts where id=p_district_id) then raise exception 'VALID DISTRICT REQUIRED';end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'CITY NAME REQUIRED';end if;
 if p_id is null then insert into location_cities(district_id,name,active,sort_order) values(p_district_id,upper(trim(p_name)),coalesce(p_active,true),coalesce(p_sort_order,0)) returning id into v_id;
 else update location_cities set district_id=p_district_id,name=upper(trim(p_name)),active=coalesce(p_active,true),sort_order=coalesce(p_sort_order,0),updated_at=now() where id=p_id returning id into v_id;if v_id is null then raise exception 'CITY NOT FOUND';end if;end if;
 return v_id;end$$;

grant execute on function public.torvo_admin_upsert_location_state(uuid,text,boolean,integer) to authenticated;
grant execute on function public.torvo_admin_upsert_location_district(uuid,uuid,text,boolean,integer) to authenticated;
grant execute on function public.torvo_admin_upsert_location_city(uuid,uuid,text,boolean,integer) to authenticated;

-- OFFICIAL LOCATION PROVENANCE / IMPORT CONTRACT
-- Trusted import workers may populate LGD codes and PIN metadata from Government of India datasets.
-- Public OTHER city/town text must never be promoted into this authoritative master automatically.
alter table public.location_states add column if not exists lgd_code text;
alter table public.location_districts add column if not exists lgd_code text;
alter table public.location_cities add column if not exists lgd_code text;
alter table public.location_cities add column if not exists pincode text;
alter table public.location_cities add column if not exists source_kind text not null default 'LGD_LOCAL_BODY';
alter table public.location_cities add column if not exists source_updated_on date;

create unique index if not exists location_states_lgd_code_uq on public.location_states(lgd_code) where lgd_code is not null;
create unique index if not exists location_districts_lgd_code_uq on public.location_districts(lgd_code) where lgd_code is not null;
create index if not exists location_cities_pincode_idx on public.location_cities(pincode) where pincode is not null;

alter table public.location_cities drop constraint if exists location_cities_pincode_ck;
alter table public.location_cities add constraint location_cities_pincode_ck
 check (pincode is null or pincode ~ '^[1-9][0-9]{5}$');
alter table public.location_cities drop constraint if exists location_cities_source_kind_ck;
alter table public.location_cities add constraint location_cities_source_kind_ck
 check (source_kind in ('LGD_LOCAL_BODY','MANUAL_VERIFIED'));

comment on column public.location_states.lgd_code is 'Government of India Local Government Directory code; trusted import/admin only.';
comment on column public.location_districts.lgd_code is 'Government of India Local Government Directory code; trusted import/admin only.';
comment on column public.location_cities.lgd_code is 'LGD local-body code when available.';
comment on column public.location_cities.pincode is 'Official mapped PIN where available; null is allowed.';
comment on column public.location_cities.source_kind is 'Authoritative provenance; public OTHER free text is never auto-promoted.';
