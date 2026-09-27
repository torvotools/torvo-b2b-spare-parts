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


-- Owner/Admin receives only short-lived signed media access; raw bucket is never made public.
create or replace function admin_customer_demand_media_paths(p_demand_id uuid)
returns table(media_id uuid,storage_path text,mime_type text,byte_size bigint)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 return query select m.id,m.storage_path,m.mime_type,m.byte_size from customer_demand_media m where m.demand_id=p_demand_id order by m.created_at,m.id;
end$$;
revoke all on function admin_customer_demand_media_paths(uuid) from public,anon;
grant execute on function admin_customer_demand_media_paths(uuid) to authenticated;

-- Accepted Dealer may discover only media belonging to its own accepted, still-active lead.
create or replace function dealer_customer_demand_media_paths(p_lead_id uuid,p_device_id text,p_session_token text)
returns table(media_id uuid,storage_path text,mime_type text,byte_size bigint)
language plpgsql security definer set search_path=public as $$
declare did uuid;l customer_demand_dealer_leads%rowtype;d customer_product_demands%rowtype;x dealers%rowtype;
begin
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 select * into l from customer_demand_dealer_leads where id=p_lead_id and dealer_id=did and status='accepted';
 if l.id is null then raise exception 'ACCEPTED ASSIGNED CUSTOMER LEAD REQUIRED';end if;
 select * into d from customer_product_demands where id=l.demand_id and status not in('closed','cancelled');
 if d.id is null then raise exception 'ACTIVE CUSTOMER REQUIREMENT REQUIRED';end if;
 select * into x from dealers where id=did;
 if x.id is null or lower(coalesce(x.status,''))<>'approved' or x.customer_referral_enabled<>true or x.referral_profile_verified_at is null or x.product_sales_available<>true then raise exception 'APPROVED VERIFIED SALES DEALER REQUIRED';end if;
 return query select m.id,m.storage_path,m.mime_type,m.byte_size from customer_demand_media m where m.demand_id=d.id order by m.created_at,m.id;
end$$;
revoke all on function dealer_customer_demand_media_paths(uuid,text,text) from public,anon;
grant execute on function dealer_customer_demand_media_paths(uuid,text,text) to authenticated;

-- Trusted service-only helpers for the requirement-media Edge Function.
create or replace function service_customer_demand_media_upload_proof(p_demand_id uuid,p_mobile text)
returns table(allowed boolean) language sql security definer set search_path=public as $$
 select exists(select 1 from customer_product_demands d join customer_contacts c on c.id=d.customer_id
 where d.id=p_demand_id and d.status not in('closed','cancelled')
 and right(regexp_replace(coalesce(c.mobile,''),'\D','','g'),10)=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10)
 and length(right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10))=10);
$$;
revoke all on function service_customer_demand_media_upload_proof(uuid,text) from public,anon,authenticated;
grant execute on function service_customer_demand_media_upload_proof(uuid,text) to service_role;

create or replace function service_register_customer_demand_media(p_demand_id uuid,p_storage_path text,p_mime_type text,p_byte_size bigint)
returns uuid language plpgsql security definer set search_path=public as $$
declare mid uuid;
begin
 if p_mime_type not in('image/jpeg','image/png','image/webp') or p_byte_size<1 or p_byte_size>8388608 then raise exception 'INVALID REQUIREMENT MEDIA';end if;
 if p_storage_path !~ ('^'||p_demand_id::text||'/[0-9a-f-]{36}\\.(jpg|png|webp)$') then raise exception 'INVALID REQUIREMENT MEDIA PATH';end if;
 if not exists(select 1 from customer_product_demands where id=p_demand_id and status not in('closed','cancelled')) then raise exception 'ACTIVE CUSTOMER REQUIREMENT REQUIRED';end if;
 if (select count(*) from customer_demand_media where demand_id=p_demand_id)>=5 then raise exception 'MAXIMUM 5 REQUIREMENT PHOTOS';end if;
 insert into customer_demand_media(demand_id,storage_path,mime_type,byte_size) values(p_demand_id,p_storage_path,p_mime_type,p_byte_size) returning id into mid;return mid;
end$$;
revoke all on function service_register_customer_demand_media(uuid,text,text,bigint) from public,anon,authenticated;
grant execute on function service_register_customer_demand_media(uuid,text,text,bigint) to service_role;
