-- TORVO V2 ACCOUNTANT -> ADMIN DEALER VERIFICATION GATE
-- PUBLIC REGISTRATION STAYS PENDING. ACCOUNTANT VERIFIES/EDITS/SUBMITS; OWNER/ADMIN GIVES FINAL APPROVAL.
alter table dealers add column if not exists accountant_verification_status text not null default 'pending_accountant';
alter table dealers add column if not exists accountant_verified_by uuid references app_users(id);
alter table dealers add column if not exists accountant_verified_at timestamptz;
alter table dealers add column if not exists accountant_verification_note text;

do $$ begin
 if not exists(select 1 from pg_constraint where conname='dealers_accountant_verification_status_check') then
  alter table dealers add constraint dealers_accountant_verification_status_check check(accountant_verification_status in('pending_accountant','submitted_to_admin','returned','rejected'));
 end if;
end $$;

create or replace function accountant_dealer_requests() returns setof dealers language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'NOT AUTHORIZED';end if;
 return query select * from dealers d where d.status<>'approved' order by d.created_at desc;
end$$;

create or replace function accountant_update_dealer_request(p_dealer uuid,p_shop_name text,p_contact_person text,p_mobile text,p_whatsapp text,p_address text,p_city text,p_district text,p_state text,p_pin_code text,p_note text default null) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;mob text;wa text;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin','accountant') then raise exception 'NOT AUTHORIZED';end if;
 select * into d from dealers where id=p_dealer for update;if not found or d.status='approved' then raise exception 'DEALER REQUEST NOT EDITABLE';end if;
 if a.role='accountant' and coalesce(d.accountant_verification_status,'pending_accountant')<>'pending_accountant' then raise exception 'REQUEST ALREADY SUBMITTED TO ADMIN';end if;
 mob:=regexp_replace(coalesce(p_mobile,''),'\D','','g');if length(mob)>10 then mob:=right(mob,10);end if;if length(mob)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;
 wa:=regexp_replace(coalesce(p_whatsapp,mob),'\D','','g');if length(wa)>10 then wa:=right(wa,10);end if;if length(wa)<>10 then raise exception 'VALID 10 DIGIT WHATSAPP REQUIRED';end if;
 if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 update dealers set shop_name=upper(btrim(p_shop_name)),contact_person=upper(btrim(p_contact_person)),mobile=mob,whatsapp=wa,address=nullif(upper(btrim(p_address)),''),city=nullif(upper(btrim(p_city)),''),district=nullif(upper(btrim(p_district)),''),state=nullif(upper(btrim(p_state)),''),pin_code=btrim(p_pin_code),accountant_verification_note=nullif(upper(btrim(p_note)),'') where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_REQUEST_EDITED','dealer',p_dealer::text,jsonb_build_object('stage','ACCOUNTANT_VERIFICATION'));
end$$;

create or replace function accountant_submit_dealer_to_admin(p_dealer uuid,p_note text default null) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin','accountant') then raise exception 'NOT AUTHORIZED';end if;
 select * into d from dealers where id=p_dealer for update;if not found or d.status='approved' then raise exception 'DEALER REQUEST NOT AVAILABLE';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'pending_accountant' then raise exception 'DEALER REQUEST ALREADY PROCESSED';end if;
 update dealers set accountant_verification_status='submitted_to_admin',accountant_verified_by=a.id,accountant_verified_at=now(),accountant_verification_note=coalesce(nullif(upper(btrim(p_note)),''),accountant_verification_note) where id=p_dealer;
 insert into notifications(user_id,title,body) select u.id,'DEALER READY FOR APPROVAL',coalesce(d.shop_name,'DEALER')||' VERIFIED BY ACCOUNTANT.' from app_users u where u.active=true and u.role in('owner','admin');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_SUBMITTED_TO_ADMIN','dealer',p_dealer::text,jsonb_build_object('note',p_note));
end$$;

create or replace function accountant_reject_dealer_request(p_dealer uuid,p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin','accountant') then raise exception 'NOT AUTHORIZED';end if;
 if nullif(btrim(p_reason),'') is null then raise exception 'REJECTION REASON REQUIRED';end if;
 update dealers set status='rejected',accountant_verification_status='rejected',accountant_verified_by=a.id,accountant_verified_at=now(),accountant_verification_note=upper(btrim(p_reason)) where id=p_dealer and status<>'approved';if not found then raise exception 'DEALER REQUEST NOT AVAILABLE';end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_REQUEST_REJECTED','dealer',p_dealer::text,jsonb_build_object('reason',upper(btrim(p_reason))));
end$$;

create or replace function admin_return_dealer_to_accountant(p_dealer uuid,p_reason text) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if nullif(btrim(p_reason),'') is null then raise exception 'RETURN REASON REQUIRED';end if;
 update dealers set accountant_verification_status='pending_accountant',accountant_verified_by=null,accountant_verified_at=null,accountant_verification_note=upper(btrim(p_reason)) where id=p_dealer and status<>'approved';if not found then raise exception 'DEALER REQUEST NOT AVAILABLE';end if;
 insert into notifications(user_id,title,body) select u.id,'DEALER RETURNED FOR VERIFICATION','ADMIN RETURNED A DEALER REQUEST: '||upper(btrim(p_reason)) from app_users u where u.active=true and u.role='accountant';
end$$;

revoke all on function accountant_dealer_requests() from public,anon;
revoke all on function accountant_update_dealer_request(uuid,text,text,text,text,text,text,text,text,text,text) from public,anon;
revoke all on function accountant_submit_dealer_to_admin(uuid,text) from public,anon;
revoke all on function accountant_reject_dealer_request(uuid,text) from public,anon;
revoke all on function admin_return_dealer_to_accountant(uuid,text) from public,anon;
grant execute on function accountant_dealer_requests() to authenticated;
grant execute on function accountant_update_dealer_request(uuid,text,text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function accountant_submit_dealer_to_admin(uuid,text) to authenticated;
grant execute on function accountant_reject_dealer_request(uuid,text) to authenticated;
grant execute on function admin_return_dealer_to_accountant(uuid,text) to authenticated;