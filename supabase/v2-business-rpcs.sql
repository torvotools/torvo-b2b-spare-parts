-- TORVO V2 reviewed business-action RPCs.
-- All actors come from auth.uid(); callers cannot spoof employee identity.

create or replace function approve_dealer(p_dealer uuid,p_dealer_code text,p_rate_group text)
returns void language plpgsql security definer set search_path=public as $$
declare v_actor app_users%rowtype; v_status text;
begin
 select * into v_actor from app_users where auth_user_id=auth.uid() and active=true;
 if not found or v_actor.role not in ('owner','admin') then raise exception 'Not authorized'; end if;
 if p_rate_group not in ('A','B','C') then raise exception 'Invalid rate group'; end if;
 if nullif(trim(p_dealer_code),'') is null then raise exception 'Dealer code required'; end if;
 select status into v_status from dealers where id=p_dealer for update;
 if not found then raise exception 'Dealer not found'; end if;
 if v_status='approved' then raise exception 'Dealer already approved'; end if;
 update dealers set dealer_code=upper(trim(p_dealer_code)),rate_group=p_rate_group,status='approved',approved_by=v_actor.id,approved_at=now() where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(v_actor.id,'DEALER_APPROVED','dealer',p_dealer::text,jsonb_build_object('dealer_code',upper(trim(p_dealer_code)),'rate_group',p_rate_group));
end;$$;
revoke all on function approve_dealer(uuid,text,text) from public,anon; grant execute on function approve_dealer(uuid,text,text) to authenticated;

create or replace function set_dealer_request_status(p_dealer uuid,p_status text,p_reason text)
returns void language plpgsql security definer set search_path=public as $$
declare v_actor app_users%rowtype;
begin
 select * into v_actor from app_users where auth_user_id=auth.uid() and active=true;
 if not found or v_actor.role not in ('owner','admin') then raise exception 'Not authorized'; end if;
 if p_status not in ('hold','rejected','inactive','suspended') then raise exception 'Invalid dealer status'; end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Reason required'; end if;
 perform 1 from dealers where id=p_dealer for update; if not found then raise exception 'Dealer not found'; end if;
 update dealers set status=p_status where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(v_actor.id,'DEALER_STATUS_CHANGED','dealer',p_dealer::text,jsonb_build_object('status',p_status,'reason',trim(p_reason)));
end;$$;
revoke all on function set_dealer_request_status(uuid,text,text) from public,anon; grant execute on function set_dealer_request_status(uuid,text,text) to authenticated;

create or replace function record_payment(p_estimate uuid,p_status text,p_amount numeric)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_actor app_users%rowtype; v_id uuid; v_final numeric;
begin
 select * into v_actor from app_users where auth_user_id=auth.uid() and active=true;
 if not found or v_actor.role not in ('owner','admin','accountant') then raise exception 'Not authorized'; end if;
 if p_status not in ('cash','pending','received') or p_amount<0 then raise exception 'Invalid payment'; end if;
 select final_payable into v_final from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found'; end if;
 insert into payments(estimate_id,status,amount,received_at,recorded_by) values(p_estimate,p_status,p_amount,case when p_status in ('cash','received') then now() else null end,v_actor.id) returning id into v_id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(v_actor.id,'PAYMENT_RECORDED','estimate',p_estimate::text,jsonb_build_object('payment_id',v_id,'status',p_status,'amount',p_amount,'final_payable',v_final));
 return v_id;
end;$$;
revoke all on function record_payment(uuid,text,numeric) from public,anon; grant execute on function record_payment(uuid,text,numeric) to authenticated;

create or replace function advance_dispatch(p_estimate uuid,p_status text,p_tracking_code text default null)
returns void language plpgsql security definer set search_path=public as $$
declare v_actor app_users%rowtype; v_current text; v_next text;
begin
 select * into v_actor from app_users where auth_user_id=auth.uid() and active=true;
 if not found or v_actor.role not in ('owner','admin','store_keeper') then raise exception 'Not authorized'; end if;
 if p_status='delivered' then raise exception 'Use deliver_estimate for delivery'; end if;
 select status into v_current from dispatches where estimate_id=p_estimate for update;
 if not found then raise exception 'Dispatch not found'; end if;
 v_next:=case v_current when 'pick_list' then 'picked' when 'picked' then 'packed' when 'packed' then 'ready_for_dispatch' else null end;
 if p_status<>v_next then raise exception 'Invalid dispatch transition from % to %',v_current,p_status; end if;
 update dispatches set status=p_status,tracking_code=coalesce(nullif(trim(p_tracking_code),''),tracking_code),updated_by=v_actor.id where estimate_id=p_estimate;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(v_actor.id,'DISPATCH_STATUS_CHANGED','estimate',p_estimate::text,jsonb_build_object('from',v_current,'to',p_status));
end;$$;
revoke all on function advance_dispatch(uuid,text,text) from public,anon; grant execute on function advance_dispatch(uuid,text,text) to authenticated;
