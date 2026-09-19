-- TORVO V2 FINAL DELIVERY CHARGE BOUNDARY
-- Server-authoritative Estimate delivery policy. STAGING verify before production.
-- Spare Parts subtotal >= configured threshold qualifies the SPARE PARTS portion for free delivery.
-- MACHINE / ACCESSORY lines never contribute to the free-delivery threshold.
-- Actual charge is staff-entered; no freight amount is invented by the database.

create or replace function public.set_estimate_delivery_details(
  p_estimate uuid,
  p_method text,
  p_delivery_charge numeric,
  p_provider_name text default null,
  p_lr_awb_receipt_no text default null,
  p_delivery_person text default null,
  p_remarks text default null
) returns void
language plpgsql security definer set search_path=public as $$
declare
  a app_users%rowtype;
  e sales_documents%rowtype;
  enabled boolean;
  threshold numeric;
  spare_sub numeric:=0;
  non_spare_sub numeric:=0;
  free_spare boolean:=false;
  charge numeric;
begin
  select * into a from app_users where auth_user_id=auth.uid() and active=true;
  if not found or a.role not in('owner','admin','accountant') then raise exception 'Owner/Admin/Accountant required'; end if;
  if nullif(trim(coalesce(p_method,'')),'') is null then raise exception 'Delivery method required'; end if;
  charge:=coalesce(p_delivery_charge,0);
  if charge<0 then raise exception 'Delivery charge cannot be negative'; end if;

  select * into e from sales_documents where id=p_estimate and doc_type='estimate' for update;
  if not found then raise exception 'Estimate not found'; end if;
  if e.status='delivered' or exists(select 1 from delivery_stock_finalizations f where f.estimate_id=e.id) then
    raise exception 'Delivered Estimate cannot be changed';
  end if;
  if exists(select 1 from payments p where p.estimate_id=e.id)
     or exists(select 1 from approval_requests ar where ar.module='payment' and ar.entity_type='estimate' and ar.entity_id=e.id::text and ar.status in('pending_approval','approved')) then
    raise exception 'Delivery charge is locked after payment activity starts';
  end if;

  select coalesce(ds.spare_free_delivery_enabled,false),coalesce(ds.spare_free_delivery_threshold,10000)
    into enabled,threshold from delivery_settings ds where ds.id=true;
  threshold:=coalesce(threshold,10000);

  select
    coalesce(sum(case when upper(replace(ci.item_type,'_',' ')) in ('SPARE PART','SPARE PARTS') then l.amount else 0 end),0),
    coalesce(sum(case when upper(replace(ci.item_type,'_',' ')) not in ('SPARE PART','SPARE PARTS') then l.amount else 0 end),0)
  into spare_sub,non_spare_sub
  from sales_document_lines l join catalog_items ci on ci.id=l.item_id
  where l.document_id=e.id;

  free_spare:=enabled and spare_sub>=threshold;

  -- A pure qualifying Spare Parts Estimate must be free. Mixed/Machine/Accessory Estimates
  -- may still carry the truthful staff-entered charge for the non-spare delivery component.
  if free_spare and non_spare_sub=0 then charge:=0; end if;

  insert into estimate_delivery_details(
    estimate_id,method,provider_name,lr_awb_receipt_no,delivery_person,delivery_charge,
    spare_parts_subtotal,spare_free_delivery_applied,free_delivery_threshold_snapshot,
    remarks,updated_by,updated_at
  ) values(
    e.id,upper(trim(p_method)),nullif(trim(p_provider_name),''),nullif(trim(p_lr_awb_receipt_no),''),
    nullif(trim(p_delivery_person),''),charge,spare_sub,free_spare,threshold,
    nullif(trim(p_remarks),''),a.id,now()
  )
  on conflict (estimate_id) do update set
    method=excluded.method,provider_name=excluded.provider_name,lr_awb_receipt_no=excluded.lr_awb_receipt_no,
    delivery_person=excluded.delivery_person,delivery_charge=excluded.delivery_charge,
    spare_parts_subtotal=excluded.spare_parts_subtotal,spare_free_delivery_applied=excluded.spare_free_delivery_applied,
    free_delivery_threshold_snapshot=excluded.free_delivery_threshold_snapshot,remarks=excluded.remarks,
    updated_by=excluded.updated_by,updated_at=now();

  update sales_documents
  set freight=charge,final_payable=subtotal+charge+coalesce(other_charges,0)
  where id=e.id;

  insert into audit_log(actor_id,action,entity_type,entity_id,details)
  values(a.id,'ESTIMATE_DELIVERY_DETAILS_SET','estimate',e.id::text,
    jsonb_build_object('delivery_charge',charge,'spare_parts_subtotal',spare_sub,
      'spare_free_delivery_applied',free_spare,'threshold_snapshot',threshold,
      'non_spare_subtotal',non_spare_sub,'method',upper(trim(p_method))));
end;$$;

revoke all on function public.set_estimate_delivery_details(uuid,text,numeric,text,text,text,text) from public,anon;
grant execute on function public.set_estimate_delivery_details(uuid,text,numeric,text,text,text,text) to authenticated;


-- RPC-only table boundary: these delivery financial/configuration tables are deny-by-default under RLS.
-- SECURITY DEFINER RPCs above / existing setting RPCs are the only supported mutation path.
revoke all on table public.estimate_delivery_details from anon, authenticated;
revoke all on table public.delivery_settings from anon, authenticated;
revoke all on table public.delivery_setting_history from anon, authenticated;


-- Payment must start only after delivery/freight has been finalized for the Estimate.
-- This prevents final_payable from changing after a payment request or receipt exists.
create or replace function public.assert_estimate_delivery_finalized_for_payment(p_estimate uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from estimate_delivery_details d where d.estimate_id=p_estimate) then
    raise exception 'Finalize Estimate delivery details before payment';
  end if;
end;$$;
revoke all on function public.assert_estimate_delivery_finalized_for_payment(uuid) from public,anon,authenticated;
