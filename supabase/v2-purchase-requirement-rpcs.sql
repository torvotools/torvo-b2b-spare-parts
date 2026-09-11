-- TORVO V2 purchase requirement secure actions. Requires v2-purchase-requirements.sql.

create or replace function submit_purchase_requirement(p_item uuid,p_qty numeric,p_reason_type text,p_reason text,p_dealer uuid default null) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;rid uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('salesman','accountant','store_keeper','owner','admin') then raise exception 'Not authorized'; end if;
 if p_qty is null or p_qty<=0 then raise exception 'Valid required quantity required'; end if;
 if p_reason_type not in('out_of_stock','low_stock','fast_moving','more_qty_required','dealer_demand','other') then raise exception 'Invalid reason type'; end if;
 if not exists(select 1 from catalog_items where id=p_item and active=true) then raise exception 'Item not found'; end if;
 if a.role='salesman' and p_dealer is not null and not salesman_can_access_dealer(a.id,p_dealer) then raise exception 'Dealer is not mapped to this salesman'; end if;
 insert into purchase_requirements(request_type,existing_item_id,requested_qty,reason_type,reason,requested_by) values('existing_item',p_item,p_qty,p_reason_type,nullif(trim(p_reason),''),a.id) returning id into rid;
 if p_dealer is not null then insert into purchase_requirement_dealers(requirement_id,dealer_id,requested_qty,note) values(rid,p_dealer,p_qty,nullif(trim(p_reason),'')); end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REQUIREMENT_SUBMITTED','purchase_requirement',rid::text,jsonb_build_object('item_id',p_item,'qty',p_qty,'dealer_id',p_dealer,'reason_type',p_reason_type));
 return rid;
end;$$;
revoke all on function submit_purchase_requirement(uuid,numeric,text,text,uuid) from public,anon;grant execute on function submit_purchase_requirement(uuid,numeric,text,text,uuid) to authenticated;

create or replace function submit_new_item_requirement(p_qty numeric,p_brand text,p_machine_type text,p_model text,p_item_name text,p_oem text,p_category text,p_demand text,p_photo_url text,p_market_note text,p_dealer uuid default null) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;rid uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('salesman','accountant','store_keeper','owner','admin') then raise exception 'Not authorized'; end if;
 if p_qty is null or p_qty<=0 or nullif(trim(p_brand),'') is null or nullif(trim(p_item_name),'') is null then raise exception 'Brand, item name and quantity required'; end if;
 if a.role='salesman' and p_dealer is not null and not salesman_can_access_dealer(a.id,p_dealer) then raise exception 'Dealer is not mapped to this salesman'; end if;
 insert into purchase_requirements(request_type,requested_qty,reason_type,reason,requested_by) values('new_item',p_qty,'new_item_required',nullif(trim(p_market_note),''),a.id) returning id into rid;
 insert into purchase_requirement_new_items(requirement_id,company_brand,machine_type,model_no,item_part_name,oem_part_no,category,expected_market_demand,photo_url,market_note) values(rid,upper(trim(p_brand)),nullif(upper(trim(p_machine_type)),''),nullif(upper(trim(p_model)),''),upper(trim(p_item_name)),nullif(upper(trim(p_oem)),''),nullif(upper(trim(p_category)),''),nullif(trim(p_demand),''),nullif(trim(p_photo_url),''),nullif(trim(p_market_note),''));
 if p_dealer is not null then insert into purchase_requirement_dealers(requirement_id,dealer_id,requested_qty,note) values(rid,p_dealer,p_qty,'NEW ITEM DEALER DEMAND'); end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'NEW_ITEM_REQUIREMENT_SUBMITTED','purchase_requirement',rid::text,jsonb_build_object('brand',upper(trim(p_brand)),'item_name',upper(trim(p_item_name)),'qty',p_qty,'dealer_id',p_dealer));
 return rid;
end;$$;
revoke all on function submit_new_item_requirement(numeric,text,text,text,text,text,text,text,text,text,uuid) from public,anon;grant execute on function submit_new_item_requirement(numeric,text,text,text,text,text,text,text,text,text,uuid) to authenticated;

create or replace function review_purchase_requirement(p_requirement uuid,p_action text,p_approved_qty numeric,p_note text) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;old_status text;new_status text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if p_action not in('approve','hold','reject','purchasing') then raise exception 'Invalid action'; end if;
 if p_action in('approve','purchasing') and (p_approved_qty is null or p_approved_qty<=0) then raise exception 'Approved quantity required'; end if;
 if p_action in('hold','reject') and nullif(trim(p_note),'') is null then raise exception 'Reason required'; end if;
 select status into old_status from purchase_requirements where id=p_requirement for update;
 if not found then raise exception 'Requirement not found'; end if;
 if old_status in('completed','rejected') then raise exception 'Requirement is closed'; end if;
 new_status:=case p_action when 'approve' then 'approved' when 'hold' then 'hold' when 'reject' then 'rejected' else 'purchasing' end;
 update purchase_requirements set status=new_status,approved_qty=case when p_action in('approve','purchasing') then p_approved_qty else approved_qty end,reviewed_by=a.id,reviewed_at=now(),admin_note=nullif(trim(p_note),'') where id=p_requirement;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REQUIREMENT_REVIEWED','purchase_requirement',p_requirement::text,jsonb_build_object('old_status',old_status,'new_status',new_status,'approved_qty',p_approved_qty,'note',p_note));
end;$$;
revoke all on function review_purchase_requirement(uuid,text,numeric,text) from public,anon;grant execute on function review_purchase_requirement(uuid,text,numeric,text) to authenticated;
