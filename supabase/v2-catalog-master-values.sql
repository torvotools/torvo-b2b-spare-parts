-- TORVO V2 protected catalog masters: BRAND / CATEGORY / MODEL.
-- Apply after v2-schema.sql. Runtime-test on staging before production.
create table if not exists catalog_master_values (
 id uuid primary key default gen_random_uuid(),
 master_type text not null check(master_type in ('brand','category','model')),
 name text not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(master_type,name)
);

-- One canonical business-text normalizer: trim edges, collapse repeated whitespace, uppercase.
create or replace function torvo_normalize_business_text(p_value text)
returns text language sql immutable as $$ select upper(regexp_replace(btrim(coalesce(p_value,'')),'\s+',' ','g')) $$;

drop index if exists catalog_master_values_upper_uq;
create unique index if not exists catalog_master_values_normalized_uq on catalog_master_values(master_type,torvo_normalize_business_text(name));

-- Existing authenticated V2 screens need read access, but writes stay behind secured RPCs.
alter table catalog_master_values enable row level security;
drop policy if exists catalog_master_values_authenticated_read on catalog_master_values;
create policy catalog_master_values_authenticated_read on catalog_master_values for select to authenticated using (true);
revoke insert,update,delete on catalog_master_values from anon,authenticated;
grant select on catalog_master_values to authenticated;

create or replace function catalog_master_usage(p_master uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m catalog_master_values; n bigint:=0;
begin
 select * into m from catalog_master_values where id=p_master;
 if m.id is null then raise exception 'MASTER VALUE NOT FOUND'; end if;
 if m.master_type='brand' then select count(*) into n from catalog_items where torvo_normalize_business_text(brand)=torvo_normalize_business_text(m.name);
 elsif m.master_type='category' then select count(*) into n from catalog_items where torvo_normalize_business_text(category)=torvo_normalize_business_text(m.name);
 else select count(*) into n from catalog_items where torvo_normalize_business_text(model)=torvo_normalize_business_text(m.name); end if;
 return jsonb_build_object('master_type',m.master_type,'name',m.name,'catalog_items',n,'total',n,'active',m.active);
end $$;

create or replace function save_catalog_master(p_id uuid,p_type text,p_name text,p_active boolean default true)
returns uuid language plpgsql security definer set search_path=public as $$
declare uid uuid; r text; nm text:=torvo_normalize_business_text(p_name); old catalog_master_values; usage_count bigint:=0;
begin
 select role into r from app_users where auth_user_id=auth.uid() and active=true;
 if r not in ('owner','admin') then raise exception 'NOT AUTHORIZED'; end if;
 if p_type not in ('brand','category','model') or nm='' then raise exception 'INVALID MASTER VALUE'; end if;
 if exists(select 1 from catalog_master_values x where x.master_type=p_type and torvo_normalize_business_text(x.name)=nm and (p_id is null or x.id<>p_id)) then raise exception '% ALREADY EXISTS',nm; end if;
 if p_id is null then
  insert into catalog_master_values(master_type,name,active) values(p_type,nm,p_active) returning id into uid;
 else
  select * into old from catalog_master_values where id=p_id for update;
  if old.id is null then raise exception 'MASTER VALUE NOT FOUND'; end if;
  if old.master_type<>p_type then raise exception 'MASTER TYPE CANNOT BE CHANGED'; end if;
  if torvo_normalize_business_text(old.name)<>nm then
   select coalesce((catalog_master_usage(p_id)->>'total')::bigint,0) into usage_count;
   if usage_count>0 then raise exception '% IS USED IN % CATALOG ITEM(S). REASSIGN THOSE ITEMS BEFORE RENAMING.',old.name,usage_count; end if;
  end if;
  update catalog_master_values set name=nm,active=p_active,updated_at=now() where id=p_id returning id into uid;
 end if;
 return uid;
end $$;

create or replace function delete_catalog_master(p_id uuid,p_confirmation text)
returns void language plpgsql security definer set search_path=public as $$
declare r text; u jsonb;
begin
 select role into r from app_users where auth_user_id=auth.uid() and active=true;
 if r not in ('owner','admin') then raise exception 'NOT AUTHORIZED'; end if;
 if p_confirmation<>'1122' then raise exception 'INVALID DELETE CONFIRMATION CODE'; end if;
 u:=catalog_master_usage(p_id);
 if coalesce((u->>'total')::bigint,0)>0 then raise exception 'MASTER IS IN USE: %',u::text; end if;
 delete from catalog_master_values where id=p_id;
end $$;

revoke all on function catalog_master_usage(uuid) from public,anon;
revoke all on function save_catalog_master(uuid,text,text,boolean) from public,anon;
revoke all on function delete_catalog_master(uuid,text) from public,anon;
grant execute on function catalog_master_usage(uuid) to authenticated;
grant execute on function save_catalog_master(uuid,text,text,boolean) to authenticated;
grant execute on function delete_catalog_master(uuid,text) to authenticated;
