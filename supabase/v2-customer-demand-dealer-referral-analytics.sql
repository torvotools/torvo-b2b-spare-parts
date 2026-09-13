-- TORVO V2 CUSTOMER DEMAND + DEALER REFERRAL ANALYTICS
-- PRICE-FREE CUSTOMER ENQUIRY. SERVER-AUTHORITATIVE BUSINESS DATA.

create table if not exists public.customer_product_enquiries (
  id uuid primary key default gen_random_uuid(),
  enquiry_no bigint generated always as identity unique,
  customer_name text not null,
  mobile_whatsapp text not null,
  state_name text,
  district_name text,
  city_name text,
  pin_code text not null,
  marketing_opt_in boolean not null default false,
  status text not null default 'OPEN' check (status in ('OPEN','DEALER_REFERRED','FULFILLED','CLOSED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_product_enquiry_items (
  id uuid primary key default gen_random_uuid(),
  enquiry_id uuid not null references public.customer_product_enquiries(id) on delete cascade,
  product_id uuid not null references public.catalog_items(id),
  quantity integer not null default 1 check(quantity > 0),
  created_at timestamptz not null default now(),
  unique(enquiry_id,product_id)
);

create table if not exists public.dealer_referral_events (
  id uuid primary key default gen_random_uuid(),
  enquiry_id uuid references public.customer_product_enquiries(id) on delete set null,
  dealer_id uuid not null references public.dealers(id),
  event_type text not null check(event_type in ('PROFILE_VIEW','DEALER_SELECTED','CALL_CLICK','WHATSAPP_CLICK','DIRECTIONS_CLICK','CONFIRMED_CONVERSION')),
  product_id uuid references public.catalog_items(id),
  event_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists dealer_referral_events_dealer_created_idx on public.dealer_referral_events(dealer_id,created_at desc);
create index if not exists customer_product_enquiries_pin_created_idx on public.customer_product_enquiries(pin_code,created_at desc);

alter table public.customer_product_enquiries enable row level security;
alter table public.customer_product_enquiry_items enable row level security;
alter table public.dealer_referral_events enable row level security;

create or replace function public.public_create_product_enquiry(
 p_customer_name text,p_mobile_whatsapp text,p_state text,p_district text,p_city text,p_pin_code text,p_product_ids uuid[],p_marketing_opt_in boolean default false
) returns table(enquiry_id uuid,enquiry_number bigint)
language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_no bigint; v_product uuid;
begin
 if length(trim(coalesce(p_customer_name,''))) < 2 then raise exception 'CUSTOMER NAME REQUIRED'; end if;
 if trim(coalesce(p_mobile_whatsapp,'')) !~ '^[0-9]{10}$' then raise exception 'VALID 10-DIGIT MOBILE REQUIRED'; end if;
 if trim(coalesce(p_pin_code,'')) !~ '^[0-9]{6}$' then raise exception 'VALID 6-DIGIT PIN REQUIRED'; end if;
 if coalesce(array_length(p_product_ids,1),0)=0 then raise exception 'SELECT AT LEAST ONE PRODUCT'; end if;
 insert into public.customer_product_enquiries(customer_name,mobile_whatsapp,state_name,district_name,city_name,pin_code,marketing_opt_in)
 values(upper(trim(p_customer_name)),trim(p_mobile_whatsapp),upper(nullif(trim(p_state),'')),upper(nullif(trim(p_district),'')),upper(nullif(trim(p_city),'')),trim(p_pin_code),coalesce(p_marketing_opt_in,false)) returning id,enquiry_no into v_id,v_no;
 foreach v_product in array p_product_ids loop
  if exists(select 1 from public.catalog_items c where c.id=v_product and coalesce(c.is_active,true)=true) then
   insert into public.customer_product_enquiry_items(enquiry_id,product_id) values(v_id,v_product) on conflict do nothing;
  end if;
 end loop;
 if not exists(select 1 from public.customer_product_enquiry_items where enquiry_id=v_id) then raise exception 'NO VALID PRODUCT SELECTED'; end if;
 return query select v_id,v_no;
end $$;

create or replace function public.public_track_dealer_referral_event(p_enquiry_id uuid,p_dealer_id uuid,p_event_type text,p_product_id uuid default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_event text:=upper(trim(coalesce(p_event_type,'')));
begin
 if v_event not in ('PROFILE_VIEW','DEALER_SELECTED','CALL_CLICK','WHATSAPP_CLICK','DIRECTIONS_CLICK') then raise exception 'INVALID PUBLIC REFERRAL EVENT'; end if;
 if not exists(select 1 from public.dealers d where d.id=p_dealer_id and upper(coalesce(d.status,''))='APPROVED') then raise exception 'DEALER NOT AVAILABLE'; end if;
 insert into public.dealer_referral_events(enquiry_id,dealer_id,event_type,product_id) values(p_enquiry_id,p_dealer_id,v_event,p_product_id);
 if v_event='DEALER_SELECTED' and p_enquiry_id is not null then update public.customer_product_enquiries set status='DEALER_REFERRED',updated_at=now() where id=p_enquiry_id; end if;
 return true;
end $$;

create or replace function public.admin_dealer_referral_performance(p_from timestamptz default now()-interval '30 days',p_to timestamptz default now())
returns table(dealer_id uuid,shop_name text,total_customers bigint,profile_views bigint,dealer_selections bigint,call_clicks bigint,whatsapp_clicks bigint,directions_clicks bigint,confirmed_conversions bigint)
language sql security definer set search_path=public as $$
 select d.id,d.shop_name,
 count(distinct e.enquiry_id) filter(where e.enquiry_id is not null),
 count(*) filter(where e.event_type='PROFILE_VIEW'),count(*) filter(where e.event_type='DEALER_SELECTED'),
 count(*) filter(where e.event_type='CALL_CLICK'),count(*) filter(where e.event_type='WHATSAPP_CLICK'),
 count(*) filter(where e.event_type='DIRECTIONS_CLICK'),count(*) filter(where e.event_type='CONFIRMED_CONVERSION')
 from public.dealers d left join public.dealer_referral_events e on e.dealer_id=d.id and e.created_at>=p_from and e.created_at<p_to
 where exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and upper(u.role) in ('OWNER','ADMIN') and coalesce(u.is_active,true)=true)
 group by d.id,d.shop_name order by count(distinct e.enquiry_id) filter(where e.enquiry_id is not null) desc,d.shop_name;
$$;

revoke all on function public.public_create_product_enquiry(text,text,text,text,text,text,uuid[],boolean) from public;
grant execute on function public.public_create_product_enquiry(text,text,text,text,text,text,uuid[],boolean) to anon,authenticated;
revoke all on function public.public_track_dealer_referral_event(uuid,uuid,text,uuid) from public;
grant execute on function public.public_track_dealer_referral_event(uuid,uuid,text,uuid) to anon,authenticated;
revoke all on function public.admin_dealer_referral_performance(timestamptz,timestamptz) from public;
grant execute on function public.admin_dealer_referral_performance(timestamptz,timestamptz) to authenticated;
