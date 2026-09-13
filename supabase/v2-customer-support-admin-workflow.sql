-- TORVO V2 CUSTOMER SUPPORT ADMIN WORKFLOW
-- Run after v2-customer-support-opportunity-center.sql and catalog_items/app_users.
-- Adds server-authoritative status transitions and verified product linkage.

create or replace function public.torvo_admin_update_customer_requirement(
  p_requirement_id uuid,
  p_status text,
  p_linked_product_id uuid default null
) returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_status text:=upper(trim(coalesce(p_status,'')));
  v_current public.customer_product_requirements%rowtype;
begin
  if not exists(
    select 1 from app_users u
    where u.auth_user_id=auth.uid()
      and lower(u.role) in('owner','admin')
      and coalesce(u.active,true)
  ) then raise exception 'AUTHORIZED OWNER / ADMIN REQUIRED'; end if;

  select * into v_current from customer_product_requirements where id=p_requirement_id for update;
  if not found then raise exception 'REQUIREMENT NOT FOUND'; end if;
  if v_status not in('OPEN','UNDER REVIEW','PRODUCT ADDED','FULFILLED','CLOSED') then raise exception 'VALID REQUIREMENT STATUS REQUIRED'; end if;

  if p_linked_product_id is not null and not exists(select 1 from catalog_items c where c.id=p_linked_product_id) then
    raise exception 'LINKED PRODUCT NOT FOUND';
  end if;
  if v_status in('PRODUCT ADDED','FULFILLED') and coalesce(p_linked_product_id,v_current.linked_product_id) is null then
    raise exception 'LINK PRODUCT BEFORE PRODUCT ADDED / FULFILLED';
  end if;

  update customer_product_requirements
     set status=v_status,
         linked_product_id=coalesce(p_linked_product_id,linked_product_id),
         updated_at=now()
   where id=p_requirement_id;
  return true;
end$$;

create or replace function public.torvo_admin_update_customer_complaint(
  p_complaint_id uuid,
  p_status text,
  p_resolution_note text default null
) returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_status text:=upper(trim(coalesce(p_status,'')));
  v_note text:=nullif(trim(coalesce(p_resolution_note,'')),'');
begin
  if not exists(
    select 1 from app_users u
    where u.auth_user_id=auth.uid()
      and lower(u.role) in('owner','admin')
      and coalesce(u.active,true)
  ) then raise exception 'AUTHORIZED OWNER / ADMIN REQUIRED'; end if;

  if not exists(select 1 from customer_complaints where id=p_complaint_id) then raise exception 'COMPLAINT NOT FOUND'; end if;
  if v_status not in('OPEN','UNDER REVIEW','RESOLVED','REJECTED') then raise exception 'VALID COMPLAINT STATUS REQUIRED'; end if;
  if v_status in('RESOLVED','REJECTED') and length(coalesce(v_note,''))<3 then raise exception 'RESOLUTION NOTE REQUIRED'; end if;

  update customer_complaints
     set status=v_status,
         resolution_note=case when v_status in('RESOLVED','REJECTED') then upper(v_note) else resolution_note end,
         updated_at=now()
   where id=p_complaint_id;
  return true;
end$$;

revoke all on function public.torvo_admin_update_customer_requirement(uuid,text,uuid) from public,anon;
revoke all on function public.torvo_admin_update_customer_complaint(uuid,text,text) from public,anon;
grant execute on function public.torvo_admin_update_customer_requirement(uuid,text,uuid) to authenticated;
grant execute on function public.torvo_admin_update_customer_complaint(uuid,text,text) to authenticated;
