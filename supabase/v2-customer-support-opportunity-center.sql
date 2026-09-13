-- TORVO V2 CUSTOMER SUPPORT + MISSING RANGE FOUNDATION
-- Run after core app_users, dealers and catalog_items migrations.
create extension if not exists pgcrypto;

create table if not exists public.customer_product_requirements(
 id uuid primary key default gen_random_uuid(),
 customer_name text not null,
 mobile_whatsapp text not null,
 state text,
 district text,
 city text,
 pin_code text not null,
 product_type text not null check(product_type in('MACHINE','SPARE PART','ACCESSORY')),
 brand text,
 machine_model text,
 required_item text not null,
 item_oem_no text,
 description text,
 quantity integer not null default 1 check(quantity>0),
 photo_url text,
 marketing_opt_in boolean not null default false,
 status text not null default 'OPEN' check(status in('OPEN','UNDER REVIEW','PRODUCT ADDED','FULFILLED','CLOSED')),
 linked_product_id uuid references public.catalog_items(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists customer_product_requirements_lookup on public.customer_product_requirements(status,product_type,brand,created_at desc);

create table if not exists public.customer_complaints(
 id uuid primary key default gen_random_uuid(),
 customer_name text not null,
 mobile_whatsapp text not null,
 dealer_id uuid references public.dealers(id) on delete set null,
 enquiry_id uuid references public.customer_product_enquiries(id) on delete set null,
 category text not null check(category in('BEHAVIOUR','WRONG INFORMATION','PRODUCT ISSUE','OVERCHARGING / COMMERCIAL ISSUE','SERVICE ISSUE','OTHER')),
 description text not null,
 attachment_url text,
 status text not null default 'OPEN' check(status in('OPEN','UNDER REVIEW','RESOLVED','REJECTED')),
 resolution_note text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists customer_complaints_admin_lookup on public.customer_complaints(status,dealer_id,created_at desc);

alter table public.customer_product_requirements enable row level security;
alter table public.customer_complaints enable row level security;
revoke all on public.customer_product_requirements from anon,authenticated;
revoke all on public.customer_complaints from anon,authenticated;

create or replace function public.public_create_product_requirement(p_customer_name text,p_mobile_whatsapp text,p_state text,p_district text,p_city text,p_pin_code text,p_product_type text,p_brand text,p_machine_model text,p_required_item text,p_item_oem_no text,p_description text,p_quantity integer default 1,p_photo_url text default null,p_marketing_opt_in boolean default false)
returns uuid language plpgsql security definer set search_path=public as $$declare v_id uuid;v_mobile text:=regexp_replace(coalesce(p_mobile_whatsapp,''),'\D','','g');v_pin text:=trim(coalesce(p_pin_code,''));v_type text:=upper(trim(coalesce(p_product_type,'')));begin
 if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'CUSTOMER NAME REQUIRED';end if;
 if length(v_mobile)<>10 then raise exception '10-DIGIT MOBILE / WHATSAPP REQUIRED';end if;
 if v_pin!~'^[0-9]{6}$' then raise exception '6-DIGIT PIN CODE REQUIRED';end if;
 if v_type not in('MACHINE','SPARE PART','ACCESSORY') then raise exception 'VALID PRODUCT TYPE REQUIRED';end if;
 if length(trim(coalesce(p_required_item,'')))<2 then raise exception 'REQUIRED PRODUCT / ITEM REQUIRED';end if;
 insert into customer_product_requirements(customer_name,mobile_whatsapp,state,district,city,pin_code,product_type,brand,machine_model,required_item,item_oem_no,description,quantity,photo_url,marketing_opt_in)
 values(upper(trim(p_customer_name)),right(v_mobile,10),upper(nullif(trim(p_state),'')),upper(nullif(trim(p_district),'')),upper(nullif(trim(p_city),'')),v_pin,v_type,upper(nullif(trim(p_brand),'')),upper(nullif(trim(p_machine_model),'')),upper(trim(p_required_item)),upper(nullif(trim(p_item_oem_no),'')),upper(nullif(trim(p_description),'')),greatest(coalesce(p_quantity,1),1),nullif(trim(p_photo_url),''),coalesce(p_marketing_opt_in,false)) returning id into v_id;return v_id;end$$;

create or replace function public.public_create_customer_complaint(p_customer_name text,p_mobile_whatsapp text,p_dealer_id uuid,p_enquiry_id uuid,p_category text,p_description text,p_attachment_url text default null)
returns uuid language plpgsql security definer set search_path=public as $$declare v_id uuid;v_mobile text:=regexp_replace(coalesce(p_mobile_whatsapp,''),'\D','','g');v_cat text:=upper(trim(coalesce(p_category,'')));begin
 if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'CUSTOMER NAME REQUIRED';end if;
 if length(v_mobile)<>10 then raise exception '10-DIGIT MOBILE / WHATSAPP REQUIRED';end if;
 if v_cat not in('BEHAVIOUR','WRONG INFORMATION','PRODUCT ISSUE','OVERCHARGING / COMMERCIAL ISSUE','SERVICE ISSUE','OTHER') then raise exception 'VALID COMPLAINT CATEGORY REQUIRED';end if;
 if length(trim(coalesce(p_description,'')))<5 then raise exception 'COMPLAINT DETAILS REQUIRED';end if;
 if p_dealer_id is not null and not exists(select 1 from dealers d where d.id=p_dealer_id and upper(coalesce(d.status,''))='APPROVED') then raise exception 'VALID APPROVED DEALER REQUIRED';end if;
 insert into customer_complaints(customer_name,mobile_whatsapp,dealer_id,enquiry_id,category,description,attachment_url) values(upper(trim(p_customer_name)),right(v_mobile,10),p_dealer_id,p_enquiry_id,v_cat,upper(trim(p_description)),nullif(trim(p_attachment_url),'')) returning id into v_id;return v_id;end$$;

grant execute on function public.public_create_product_requirement(text,text,text,text,text,text,text,text,text,text,text,text,integer,text,boolean) to anon,authenticated;
grant execute on function public.public_create_customer_complaint(text,text,uuid,uuid,text,text,text) to anon,authenticated;

create or replace function public.torvo_admin_customer_requirements(p_status text default null) returns setof public.customer_product_requirements language sql security definer set search_path=public as $$select r.* from customer_product_requirements r where exists(select 1 from app_users u where u.auth_user_id=auth.uid() and lower(u.role) in('owner','admin') and coalesce(u.active,true)) and (p_status is null or r.status=upper(p_status)) order by r.created_at desc$$;
create or replace function public.torvo_admin_customer_complaints(p_status text default null) returns setof public.customer_complaints language sql security definer set search_path=public as $$select c.* from customer_complaints c where exists(select 1 from app_users u where u.auth_user_id=auth.uid() and lower(u.role) in('owner','admin') and coalesce(u.active,true)) and (p_status is null or c.status=upper(p_status)) order by c.created_at desc$$;
grant execute on function public.torvo_admin_customer_requirements(text) to authenticated;
grant execute on function public.torvo_admin_customer_complaints(text) to authenticated;
