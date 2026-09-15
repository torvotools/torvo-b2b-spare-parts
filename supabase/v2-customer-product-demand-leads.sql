-- TORVO V2 CUSTOMER PRODUCT DEMAND / MISSING RANGE FOUNDATION
-- SEARCH -> CONFIRMED REQUIREMENT -> TORVO OPPORTUNITY DATA.
-- CUSTOMER CONTACT IS PRIVATE. DEALERS MUST NOT RECEIVE CONTACT DATA FROM THIS PUBLIC RPC.

create table if not exists customer_product_demands(
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customer_contacts(id) on delete restrict,
  product_id uuid references catalog_items(id) on delete restrict,
  search_text text not null,
  pin_code text not null check(pin_code ~ '^[0-9]{6}$'),
  brand text,
  model_number text,
  requirement_note text,
  source text not null default 'PUBLIC SEARCH' check(source in('PUBLIC SEARCH','PUBLIC PRODUCT','PUBLIC MISSING PRODUCT')),
  product_found boolean not null default false,
  status text not null default 'submitted' check(status in('submitted','sourcing','available','closed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_customer_product_demands_status on customer_product_demands(status,created_at desc);
create index if not exists idx_customer_product_demands_pin on customer_product_demands(pin_code,created_at desc);
create index if not exists idx_customer_product_demands_search on customer_product_demands(upper(search_text),created_at desc);
alter table customer_product_demands enable row level security;
revoke all on customer_product_demands from anon,authenticated;

create or replace function public_create_product_demand(
  p_full_name text,
  p_mobile text,
  p_pin_code text,
  p_search_text text,
  p_product_id uuid default null,
  p_brand text default null,
  p_model_number text default null,
  p_requirement_note text default null,
  p_marketing_opt_in boolean default false
) returns table(demand_id uuid,status text)
language plpgsql security definer set search_path=public as $$
declare
  m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
  q text:=upper(btrim(coalesce(p_search_text,'')));
  c customer_contacts%rowtype;
  rid uuid;
  found_product boolean:=false;
begin
  if length(m)<>10 then raise exception '10-DIGIT MOBILE REQUIRED'; end if;
  if coalesce(p_pin_code,'')!~'^[0-9]{6}$' then raise exception '6-DIGIT PIN CODE REQUIRED'; end if;
  if nullif(btrim(p_full_name),'') is null then raise exception 'CUSTOMER NAME REQUIRED'; end if;
  if length(q)<2 or length(q)>180 then raise exception 'PRODUCT SEARCH REQUIRED'; end if;
  if length(coalesce(p_requirement_note,''))>500 then raise exception 'REQUIREMENT NOTE TOO LONG'; end if;
  if p_product_id is not null then
    select exists(select 1 from catalog_items i where i.id=p_product_id and coalesce(i.active,true)=true) into found_product;
    if not found_product then raise exception 'ACTIVE PRODUCT REQUIRED'; end if;
  end if;

  insert into customer_contacts(full_name,mobile,whatsapp,pin_code,marketing_opt_in,marketing_opt_in_at,marketing_opt_in_source,marketing_opt_out_at,consent_updated_at,updated_at)
  values(upper(btrim(p_full_name)),m,m,btrim(p_pin_code),p_marketing_opt_in,case when p_marketing_opt_in then now() end,'PUBLIC PRODUCT REQUIREMENT',case when not p_marketing_opt_in then now() end,now(),now())
  on conflict(mobile) do update set
    full_name=excluded.full_name,whatsapp=excluded.whatsapp,pin_code=excluded.pin_code,
    marketing_opt_in=excluded.marketing_opt_in,
    marketing_opt_in_at=case when excluded.marketing_opt_in then coalesce(customer_contacts.marketing_opt_in_at,now()) else null end,
    marketing_opt_in_source='PUBLIC PRODUCT REQUIREMENT',
    marketing_opt_out_at=case when excluded.marketing_opt_in then null else now() end,
    consent_updated_at=now(),updated_at=now()
  returning * into c;
  insert into customer_marketing_consent_events(customer_id,opted_in,source) values(c.id,p_marketing_opt_in,'PUBLIC PRODUCT REQUIREMENT');

  insert into customer_product_demands(customer_id,product_id,search_text,pin_code,brand,model_number,requirement_note,source,product_found)
  values(c.id,p_product_id,q,btrim(p_pin_code),upper(nullif(btrim(p_brand),'')),upper(nullif(btrim(p_model_number),'')),upper(nullif(btrim(p_requirement_note),'')),case when found_product then 'PUBLIC PRODUCT' else 'PUBLIC MISSING PRODUCT' end,found_product)
  returning id into rid;
  return query select rid,'submitted'::text;
end$$;
revoke all on function public_create_product_demand(text,text,text,text,uuid,text,text,text,boolean) from public;
grant execute on function public_create_product_demand(text,text,text,text,uuid,text,text,text,boolean) to anon,authenticated;

-- OWNER/ADMIN opportunity inbox. Contact details remain privileged and are never exposed by the public demand RPC.
create or replace function admin_customer_product_demands(p_status text default null,p_limit integer default 100)
returns table(demand_id uuid,customer_name text,mobile text,pin_code text,product_id uuid,search_text text,brand text,model_number text,requirement_note text,product_found boolean,status text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED'; end if;
  return query select d.id,c.full_name,c.mobile,d.pin_code,d.product_id,d.search_text,d.brand,d.model_number,d.requirement_note,d.product_found,d.status,d.created_at
  from customer_product_demands d join customer_contacts c on c.id=d.customer_id
  where p_status is null or d.status=lower(btrim(p_status))
  order by d.created_at desc limit greatest(1,least(coalesce(p_limit,100),500));
end$$;
revoke all on function admin_customer_product_demands(text,integer) from public,anon;
grant execute on function admin_customer_product_demands(text,integer) to authenticated;

create or replace function admin_product_demand_summary(p_days integer default 90,p_limit integer default 100)
returns table(search_text text,request_count bigint,unique_customers bigint,last_requested_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;
begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED'; end if;
  return query select d.search_text,count(*)::bigint,count(distinct d.customer_id)::bigint,max(d.created_at)
  from customer_product_demands d
  where d.created_at>=now()-make_interval(days=>greatest(1,least(coalesce(p_days,90),730))) and d.status<>'cancelled'
  group by d.search_text order by count(*) desc,max(d.created_at) desc limit greatest(1,least(coalesce(p_limit,100),500));
end$$;
revoke all on function admin_product_demand_summary(integer,integer) from public,anon;
grant execute on function admin_product_demand_summary(integer,integer) to authenticated;
