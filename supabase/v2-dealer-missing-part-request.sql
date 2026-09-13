-- TORVO V2 secure Dealer Missing Spare Part request creation.
-- Install after v2-schema.sql and authenticated Dealer identity/link foundations.
-- Photo upload remains separate/private media work; this RPC accepts only an already-approved URL.

create or replace function public.dealer_create_missing_part_request(
  p_machine_brand text default null,
  p_machine_model text default null,
  p_part_name text default null,
  p_requested_qty numeric default null,
  p_dealer_message text default null,
  p_photo_url text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user app_users%rowtype;
  v_dealer dealers%rowtype;
  v_id uuid;
  v_brand text := nullif(upper(btrim(coalesce(p_machine_brand,''))), '');
  v_model text := nullif(upper(btrim(coalesce(p_machine_model,''))), '');
  v_part text := nullif(upper(btrim(coalesce(p_part_name,''))), '');
  v_message text := nullif(btrim(coalesce(p_dealer_message,'')), '');
  v_photo text := nullif(btrim(coalesce(p_photo_url,'')), '');
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION REQUIRED'; end if;

  select * into v_user
  from app_users
  where auth_user_id = auth.uid() and active = true
  limit 1;

  if not found or lower(v_user.role) <> 'dealer' then
    raise exception 'ACTIVE DEALER LOGIN REQUIRED';
  end if;

  select d.* into v_dealer
  from dealers d
  where d.id = (
    select dealer_id from app_users where id = v_user.id
  )
  limit 1;

  if not found then
    -- Compatibility fallback for deployments where Dealer linkage is held by the canonical mobile.
    select d.* into v_dealer
    from dealers d
    where d.mobile = v_user.mobile
    order by d.created_at desc
    limit 1;
  end if;

  if not found or v_dealer.status <> 'approved' then
    raise exception 'APPROVED DEALER LINK REQUIRED';
  end if;

  if v_part is null and v_message is null then
    raise exception 'PART NAME OR REQUIREMENT DESCRIPTION REQUIRED';
  end if;
  if p_requested_qty is not null and p_requested_qty <= 0 then
    raise exception 'REQUESTED QUANTITY MUST BE GREATER THAN ZERO';
  end if;

  insert into missing_part_requests(
    dealer_id, photo_url, machine_brand, machine_model, part_name,
    requested_qty, dealer_message, status
  ) values (
    v_dealer.id, coalesce(v_photo,''), v_brand, v_model, v_part,
    p_requested_qty, v_message, 'new'
  ) returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.dealer_create_missing_part_request(text,text,text,numeric,text,text) from public, anon;
grant execute on function public.dealer_create_missing_part_request(text,text,text,numeric,text,text) to authenticated;
