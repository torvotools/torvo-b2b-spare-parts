-- TORVO V2 DEALER INACTIVITY CONTROL
-- Three consecutive months without authoritative delivered billing/purchase activity creates a warning.
-- Suspension/reactivation is always OWNER/ADMIN controlled; this migration never auto-deletes or auto-suspends a Dealer.

alter table dealers add column if not exists inactivity_warning_at timestamptz;
alter table dealers add column if not exists inactivity_warning_reason text;
alter table dealers add column if not exists suspended_at timestamptz;
alter table dealers add column if not exists suspended_by uuid references app_users(id);
alter table dealers add column if not exists suspension_reason text;
alter table dealers add column if not exists reactivated_at timestamptz;
alter table dealers add column if not exists reactivated_by uuid references app_users(id);

create or replace function dealer_last_business_activity(p_dealer_id uuid)
returns timestamptz
language sql
security definer
set search_path=public
as $$
  select greatest(
    coalesce((select max(d.delivered_at) from dispatches d join sales_documents e on e.id=d.estimate_id where e.dealer_id=p_dealer_id and d.status='delivered'),'-infinity'::timestamptz),
    coalesce((select max(e.created_at) from sales_documents e where e.dealer_id=p_dealer_id and e.doc_type='estimate' and e.status in('delivered','completed')),'-infinity'::timestamptz)
  );
$$;
revoke all on function dealer_last_business_activity(uuid) from public,anon;
grant execute on function dealer_last_business_activity(uuid) to authenticated;

create or replace function dealer_inactivity_status(p_dealer_id uuid)
returns table(dealer_id uuid,last_activity_at timestamptz,inactive_three_months boolean,warning_required boolean,status text)
language plpgsql
security definer
set search_path=public
as $$
declare u app_users%rowtype; d dealers%rowtype; v_last timestamptz;begin
  select * into u from app_users where auth_user_id=auth.uid() and active=true;
  if not found then raise exception 'NOT AUTHORIZED'; end if;
  select * into d from dealers where id=p_dealer_id;
  if not found then raise exception 'DEALER NOT FOUND'; end if;
  if u.role='dealer' and u.dealer_id<>p_dealer_id then raise exception 'NOT AUTHORIZED'; end if;
  if u.role not in('owner','admin','accountant','dealer') then raise exception 'NOT AUTHORIZED'; end if;
  v_last:=dealer_last_business_activity(p_dealer_id);
  if v_last='-infinity'::timestamptz then v_last:=d.approved_at; end if;
  return query select d.id,v_last,(coalesce(v_last,d.approved_at,d.created_at)<=now()-interval '3 months'),(d.status='approved' and coalesce(v_last,d.approved_at,d.created_at)<=now()-interval '3 months'),d.status;
end$$;
revoke all on function dealer_inactivity_status(uuid) from public,anon;
grant execute on function dealer_inactivity_status(uuid) to authenticated;

create or replace function admin_refresh_dealer_inactivity_warning(p_dealer_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype; d dealers%rowtype; v_last timestamptz; v_warn boolean;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if not found or u.role not in('owner','admin') then raise exception 'OWNER/ADMIN REQUIRED'; end if;
 select * into d from dealers where id=p_dealer_id for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 v_last:=dealer_last_business_activity(p_dealer_id);if v_last='-infinity'::timestamptz then v_last:=coalesce(d.approved_at,d.created_at);end if;
 v_warn:=d.status='approved' and v_last<=now()-interval '3 months';
 update dealers set inactivity_warning_at=case when v_warn then coalesce(inactivity_warning_at,now()) else null end,inactivity_warning_reason=case when v_warn then 'NO BILLING/PURCHASE ACTIVITY FOR 3 CONSECUTIVE MONTHS' else null end where id=p_dealer_id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'DEALER_INACTIVITY_REVIEWED','dealer',p_dealer_id::text,jsonb_build_object('warning_required',v_warn,'last_activity_at',v_last));
 return v_warn;
end$$;
revoke all on function admin_refresh_dealer_inactivity_warning(uuid) from public,anon;grant execute on function admin_refresh_dealer_inactivity_warning(uuid) to authenticated;

create or replace function admin_set_dealer_suspension(p_dealer_id uuid,p_suspend boolean,p_reason text)
returns text language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype; d dealers%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if not found or u.role not in('owner','admin') then raise exception 'OWNER/ADMIN REQUIRED';end if;
 if nullif(btrim(p_reason),'') is null then raise exception 'REASON REQUIRED';end if;
 select * into d from dealers where id=p_dealer_id for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 if p_suspend then
   if d.status not in('approved','inactive','suspended') then raise exception 'DEALER STATUS CANNOT BE SUSPENDED';end if;
   update dealers set status='suspended',suspended_at=coalesce(suspended_at,now()),suspended_by=u.id,suspension_reason=btrim(p_reason) where id=p_dealer_id;
   update app_users set active=false where dealer_id=p_dealer_id and role='dealer';
   update dealer_active_sessions set forced_logout_at=coalesce(forced_logout_at,now()),forced_logout_by=u.id where dealer_id=p_dealer_id and forced_logout_at is null;
   insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'DEALER_SUSPENDED','dealer',p_dealer_id::text,jsonb_build_object('reason',btrim(p_reason)));
   return 'suspended';
 else
   if d.status<>'suspended' then raise exception 'SUSPENDED DEALER REQUIRED';end if;
   update dealers set status='approved',reactivated_at=now(),reactivated_by=u.id,suspension_reason=null where id=p_dealer_id;
   update app_users set active=true where dealer_id=p_dealer_id and role='dealer';
   insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'DEALER_REACTIVATED','dealer',p_dealer_id::text,jsonb_build_object('reason',btrim(p_reason)));
   return 'approved';
 end if;
end$$;
revoke all on function admin_set_dealer_suspension(uuid,boolean,text) from public,anon;grant execute on function admin_set_dealer_suspension(uuid,boolean,text) to authenticated;
