-- TORVO V2 PRIVATE CUSTOMER REQUIREMENT MEDIA FOUNDATION
-- Requirement photos are private evidence. Never expose this bucket with getPublicUrl or public Storage policies.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('torvo-customer-requirement-media','torvo-customer-requirement-media',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create table if not exists customer_demand_media(
  id uuid primary key default gen_random_uuid(),
  demand_id uuid not null references customer_product_demands(id) on delete cascade,
  storage_path text not null unique check(length(storage_path) between 10 and 500),
  mime_type text not null check(mime_type in('image/jpeg','image/png','image/webp')),
  byte_size bigint not null check(byte_size between 1 and 8388608),
  created_at timestamptz not null default now()
);
create index if not exists idx_customer_demand_media_demand on customer_demand_media(demand_id,created_at);
alter table customer_demand_media enable row level security;
revoke all on customer_demand_media from anon,authenticated;

-- Storage objects remain private. Owner/Admin may inspect/manage them after authentication.
drop policy if exists torvo_customer_requirement_media_staff_select on storage.objects;
create policy torvo_customer_requirement_media_staff_select on storage.objects for select to authenticated
using(bucket_id='torvo-customer-requirement-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin')));
drop policy if exists torvo_customer_requirement_media_staff_insert on storage.objects;
create policy torvo_customer_requirement_media_staff_insert on storage.objects for insert to authenticated
with check(bucket_id='torvo-customer-requirement-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin')));
drop policy if exists torvo_customer_requirement_media_staff_delete on storage.objects;
create policy torvo_customer_requirement_media_staff_delete on storage.objects for delete to authenticated
using(bucket_id='torvo-customer-requirement-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin')));

-- Metadata is exposed only through an Owner/Admin RPC. Public/customer upload must later use a server-mediated one-time upload boundary.
create or replace function admin_customer_demand_media(p_demand_id uuid)
returns table(media_id uuid,storage_path text,mime_type text,byte_size bigint,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if not exists(select 1 from customer_product_demands d where d.id=p_demand_id) then raise exception 'CUSTOMER REQUIREMENT NOT FOUND';end if;
 return query select m.id,m.storage_path,m.mime_type,m.byte_size,m.created_at from customer_demand_media m where m.demand_id=p_demand_id order by m.created_at,m.id;
end$$;
revoke all on function admin_customer_demand_media(uuid) from public,anon;
grant execute on function admin_customer_demand_media(uuid) to authenticated;

-- Intentionally no anon/authenticated INSERT policy on customer_demand_media and no anon Storage policy.
-- A later trusted server/Edge Function will validate demand+customer proof, generate the object path and write metadata atomically.
