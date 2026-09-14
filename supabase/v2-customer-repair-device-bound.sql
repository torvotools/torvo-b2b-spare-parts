-- TORVO V2 CUSTOMER REPAIR — FINAL DEALER DEVICE BOUNDARY
-- Install in Step 18 after dealer_assert_my_device_session exists and after v2-customer-public-runtime-contract.sql.

-- Remove authenticated-only legacy signatures before exposing final device-bound versions.
drop function if exists public.dealer_repair_requirements(text,integer);
drop function if exists public.dealer_update_repair_requirement(uuid,text);

create or replace function dealer_repair_requirements(
  p_status text default null,
  p_limit integer default 100,
  p_device_id text default null,
  p_session_token text default null
) returns table(
  requirement_id uuid,
  customer_name text,
  mobile text,
  pin_code text,
  brand text,
  model_number text,
  problem_description text,
  status text,
  created_at timestamptz
) language plpgsql security definer set search_path=public as $$
declare
  did uuid;
begin
  did:=dealer_assert_my_device_session(p_device_id,p_session_token);
  if not exists(select 1 from dealers d where d.id=did and d.status='approved' and d.repair_service_available=true) then
    raise exception 'APPROVED REPAIR DEALER REQUIRED';
  end if;
  return query
  select r.id,c.full_name,c.mobile,r.pin_code,r.brand,r.model_number,r.problem_description,r.status,r.created_at
  from customer_repair_requirements r
  join customer_contacts c on c.id=r.customer_id
  where r.routed_dealer_id=did
    and (p_status is null or r.status=lower(btrim(p_status)))
  order by r.created_at desc
  limit greatest(1,least(coalesce(p_limit,100),500));
end$$;

create or replace function dealer_update_repair_requirement(
  p_requirement_id uuid,
  p_status text,
  p_device_id text,
  p_session_token text
) returns boolean language plpgsql security definer set search_path=public as $$
declare
  did uuid;
  u app_users%rowtype;
  r customer_repair_requirements%rowtype;
  s text:=lower(btrim(coalesce(p_status,'')));
begin
  did:=dealer_assert_my_device_session(p_device_id,p_session_token);
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if u.id is null or u.role<>'dealer' then raise exception 'ACTIVE DEALER REQUIRED'; end if;
  if not exists(select 1 from dealers d where d.id=did and d.status='approved' and d.repair_service_available=true) then
    raise exception 'APPROVED REPAIR DEALER REQUIRED';
  end if;
  if s not in('accepted','closed') then raise exception 'DEALER STATUS MUST BE ACCEPTED OR CLOSED'; end if;

  select * into r
  from customer_repair_requirements
  where id=p_requirement_id and routed_dealer_id=did
  for update;
  if r.id is null then raise exception 'ROUTED REPAIR REQUIREMENT NOT FOUND'; end if;
  if r.status in('closed','cancelled') then raise exception 'REPAIR REQUIREMENT ALREADY FINAL'; end if;
  if s='closed' and r.status<>'accepted' then raise exception 'ACCEPT REPAIR REQUIREMENT BEFORE CLOSING'; end if;

  update customer_repair_requirements set status=s,updated_at=now() where id=p_requirement_id;
  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(u.id,case when s='accepted' then 'REPAIR_REQUIREMENT_ACCEPTED' else 'REPAIR_REQUIREMENT_CLOSED' end,
         'CUSTOMER_REPAIR_REQUIREMENT',p_requirement_id::text,
         jsonb_build_object('dealer_id',did,'status',upper(s),'device_bound',true));
  return true;
end$$;

revoke all on function dealer_repair_requirements(text,integer,text,text),dealer_update_repair_requirement(uuid,text,text,text) from public,anon;
grant execute on function dealer_repair_requirements(text,integer,text,text),dealer_update_repair_requirement(uuid,text,text,text) to authenticated;
