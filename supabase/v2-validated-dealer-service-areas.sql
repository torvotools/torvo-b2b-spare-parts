-- TORVO V2 VALIDATED DEALER SERVICE AREAS
-- REPLACES FAKE OTHER_AREA NEARBY SEMANTICS WITH ADMIN-VERIFIED PIN COVERAGE.
create table if not exists dealer_service_areas(
 id uuid primary key default gen_random_uuid(),
 dealer_id uuid not null references dealers(id) on delete cascade,
 pin_code text not null check(pin_code ~ '^[0-9]{6}$'),
 service_type text not null default 'both' check(service_type in('product_sales','repair_service','both')),
 active boolean not null default true,
 verified_at timestamptz,
 verified_by uuid references app_users(id),
 created_at timestamptz not null default now(),
 unique(dealer_id,pin_code,service_type)
);
create index if not exists idx_dealer_service_areas_pin on dealer_service_areas(pin_code,service_type) where active=true and verified_at is not null;
alter table dealer_service_areas enable row level security;revoke all on dealer_service_areas from anon,authenticated;

create or replace function public_find_torvo_dealers_expanded(p_pin_code text,p_repair_only boolean default false,p_limit integer default 12)
returns table(dealer_id uuid,shop_name text,address text,pin_code text,map_url text,latitude numeric,longitude numeric,product_sales_available boolean,repair_service_available boolean,authorized_service_center boolean,authorized_service_note text,match_type text)
language sql security definer set search_path=public as $$
with eligible as(
 select d.*,coalesce(nullif(d.public_pin_code,''),d.pin_code) effective_pin
 from dealers d
 where d.status='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null
 and (not p_repair_only or d.repair_service_available=true)
), ranked as(
 select e.*,
 case when e.effective_pin=btrim(p_pin_code) then 0
 when exists(select 1 from dealer_service_areas a where a.dealer_id=e.id and a.pin_code=btrim(p_pin_code) and a.active=true and a.verified_at is not null and (a.service_type='both' or (p_repair_only and a.service_type='repair_service') or (not p_repair_only and a.service_type='product_sales'))) then 1
 else 9 end match_rank
 from eligible e
)
select r.id,r.shop_name,coalesce(nullif(r.public_address,''),r.address),r.effective_pin,r.map_url,r.latitude,r.longitude,r.product_sales_available,r.repair_service_available,r.authorized_service_center,r.authorized_service_note,
case when r.match_rank=0 then 'EXACT_PIN' else 'VERIFIED_SERVICE_AREA' end
from ranked r where r.match_rank<9 order by r.match_rank,r.shop_name limit greatest(1,least(coalesce(p_limit,12),30));
$$;
revoke all on function public_find_torvo_dealers_expanded(text,boolean,integer) from public;grant execute on function public_find_torvo_dealers_expanded(text,boolean,integer) to anon,authenticated;

create or replace function admin_set_dealer_service_area(p_dealer_id uuid,p_pin_code text,p_service_type text,p_active boolean default true)
returns uuid language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v_id uuid;v_type text:=lower(btrim(p_service_type));begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;if v_type not in('product_sales','repair_service','both') then raise exception 'INVALID SERVICE TYPE';end if;
 perform 1 from dealers where id=p_dealer_id and status='approved';if not found then raise exception 'APPROVED DEALER REQUIRED';end if;
 insert into dealer_service_areas(dealer_id,pin_code,service_type,active,verified_at,verified_by) values(p_dealer_id,btrim(p_pin_code),v_type,p_active,case when p_active then now() end,u.id)
 on conflict(dealer_id,pin_code,service_type) do update set active=excluded.active,verified_at=case when excluded.active then now() else dealer_service_areas.verified_at end,verified_by=u.id returning id into v_id;
 return v_id;end$$;
revoke all on function admin_set_dealer_service_area(uuid,text,text,boolean) from public,anon;grant execute on function admin_set_dealer_service_area(uuid,text,text,boolean) to authenticated;
