-- TORVO V2 DEALER PUBLIC PROFILE + SHOP MEDIA
-- ADMIN CONTROLS PUBLIC CONTACT/LOCATION/PHOTOS. PRIVATE DEALER DATA IS NEVER RETURNED.

alter table public.dealers add column if not exists public_mobile text;
alter table public.dealers add column if not exists public_whatsapp text;
alter table public.dealers add column if not exists public_city text;
alter table public.dealers add column if not exists public_district text;
alter table public.dealers add column if not exists public_state text;
alter table public.dealers add column if not exists public_profile_note text;

create table if not exists public.dealer_public_media(
 id uuid primary key default gen_random_uuid(),
 dealer_id uuid not null references public.dealers(id) on delete cascade,
 image_url text not null,
 sort_order smallint not null default 1 check(sort_order between 1 and 3),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 created_by uuid references public.app_users(id),
 unique(dealer_id,sort_order)
);
alter table public.dealer_public_media enable row level security;
revoke all on public.dealer_public_media from anon,authenticated;

create or replace function public.public_dealer_profile(p_dealer_id uuid)
returns table(dealer_id uuid,shop_name text,address text,city text,district text,state text,pin_code text,public_mobile text,public_whatsapp text,map_url text,latitude numeric,longitude numeric,product_sales_available boolean,repair_service_available boolean,authorized_service_center boolean,authorized_service_note text,profile_note text,shop_photos jsonb)
language sql security definer set search_path=public as $$
 select d.id,d.shop_name,coalesce(nullif(d.public_address,''),d.address),d.public_city,d.public_district,d.public_state,coalesce(nullif(d.public_pin_code,''),d.pin_code),d.public_mobile,d.public_whatsapp,d.map_url,d.latitude,d.longitude,d.product_sales_available,d.repair_service_available,d.authorized_service_center,d.authorized_service_note,d.public_profile_note,
 coalesce((select jsonb_agg(m.image_url order by m.sort_order) from public.dealer_public_media m where m.dealer_id=d.id and m.active=true),'[]'::jsonb)
 from public.dealers d
 where d.id=p_dealer_id and upper(coalesce(d.status,''))='APPROVED' and coalesce(d.customer_referral_enabled,false)=true and d.referral_profile_verified_at is not null;
$$;
revoke all on function public.public_dealer_profile(uuid) from public;
grant execute on function public.public_dealer_profile(uuid) to anon,authenticated;

create or replace function public.admin_update_dealer_public_profile(p_dealer_id uuid,p_public_mobile text,p_public_whatsapp text,p_address text,p_city text,p_district text,p_state text,p_pin text,p_map_url text,p_latitude numeric,p_longitude numeric,p_profile_note text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 if not exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and upper(u.role) in('OWNER','ADMIN') and coalesce(u.is_active,u.active,true)=true) then raise exception 'ADMIN ACCESS REQUIRED'; end if;
 if p_public_mobile is not null and regexp_replace(p_public_mobile,'[^0-9]','','g') !~ '^[0-9]{10}$' then raise exception 'VALID 10-DIGIT PUBLIC MOBILE REQUIRED'; end if;
 if p_public_whatsapp is not null and regexp_replace(p_public_whatsapp,'[^0-9]','','g') !~ '^[0-9]{10}$' then raise exception 'VALID 10-DIGIT WHATSAPP REQUIRED'; end if;
 if p_pin is not null and trim(p_pin) !~ '^[0-9]{6}$' then raise exception 'VALID 6-DIGIT PIN REQUIRED'; end if;
 update public.dealers set public_mobile=regexp_replace(coalesce(p_public_mobile,''),'[^0-9]','','g'),public_whatsapp=regexp_replace(coalesce(p_public_whatsapp,''),'[^0-9]','','g'),public_address=upper(nullif(trim(p_address),'')),public_city=upper(nullif(trim(p_city),'')),public_district=upper(nullif(trim(p_district),'')),public_state=upper(nullif(trim(p_state),'')),public_pin_code=nullif(trim(p_pin),''),map_url=nullif(trim(p_map_url),''),latitude=p_latitude,longitude=p_longitude,public_profile_note=upper(nullif(trim(p_profile_note),'')),referral_profile_verified_at=now() where id=p_dealer_id;
 if not found then raise exception 'DEALER NOT FOUND'; end if;
 return true;
end $$;
revoke all on function public.admin_update_dealer_public_profile(uuid,text,text,text,text,text,text,text,text,numeric,numeric,text) from public;
grant execute on function public.admin_update_dealer_public_profile(uuid,text,text,text,text,text,text,text,text,numeric,numeric,text) to authenticated;

create or replace function public.admin_set_dealer_public_photo(p_dealer_id uuid,p_image_url text,p_sort_order smallint,p_active boolean default true)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_user uuid;v_id uuid;
begin
 select u.id into v_user from public.app_users u where u.auth_user_id=auth.uid() and upper(u.role) in('OWNER','ADMIN') and coalesce(u.is_active,u.active,true)=true limit 1;
 if v_user is null then raise exception 'ADMIN ACCESS REQUIRED'; end if;
 if p_sort_order not between 1 and 3 then raise exception 'SHOP PHOTO POSITION MUST BE 1 TO 3'; end if;
 if trim(coalesce(p_image_url,''))='' then raise exception 'SHOP PHOTO REQUIRED'; end if;
 insert into public.dealer_public_media(dealer_id,image_url,sort_order,active,created_by) values(p_dealer_id,trim(p_image_url),p_sort_order,p_active,v_user)
 on conflict(dealer_id,sort_order) do update set image_url=excluded.image_url,active=excluded.active,created_by=v_user returning id into v_id;
 return v_id;
end $$;
revoke all on function public.admin_set_dealer_public_photo(uuid,text,smallint,boolean) from public;
grant execute on function public.admin_set_dealer_public_photo(uuid,text,smallint,boolean) to authenticated;
