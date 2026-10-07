-- TORVO V2 DEALER ACCOUNTANT GATE HARDENING
-- Additive final boundary: Accountant alone verifies/submits; Owner/Admin only final-approve or return.
create or replace function public.accountant_submit_dealer_to_admin(p_dealer uuid,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;e text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or lower(coalesce(a.role,''))<>'accountant' then raise exception 'ACTIVE ACCOUNTANT REQUIRED';end if;
 select * into d from dealers where id=p_dealer for update;
 if not found or d.status='approved' then raise exception 'DEALER REQUEST NOT AVAILABLE';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'pending_accountant' then raise exception 'DEALER REQUEST ALREADY PROCESSED';end if;
 e:=lower(btrim(coalesce(d.email,'')));
 if length(btrim(coalesce(d.shop_name,'')))<2 or length(btrim(coalesce(d.contact_person,'')))<2 or coalesce(d.mobile,'')!~'^[0-9]{10}$' or coalesce(d.pin_code,'')!~'^[0-9]{6}$' or e!~'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$' then raise exception 'COMPLETE VERIFIED DEALER DETAILS INCLUDING EMAIL REQUIRED';end if;
 if exists(select 1 from dealers x where x.id<>p_dealer and lower(btrim(coalesce(x.email,'')))=e and x.status in('pending','approved','hold')) then raise exception 'EMAIL ID ALREADY USED BY ANOTHER DEALER';end if;
 update dealers set email=e,accountant_verification_status='submitted_to_admin',accountant_verified_by=a.id,accountant_verified_at=now(),accountant_verification_note=coalesce(nullif(upper(btrim(p_note)),''),accountant_verification_note) where id=p_dealer;
 insert into notifications(user_id,title,body) select u.id,'DEALER READY FOR APPROVAL',coalesce(d.shop_name,'DEALER')||' VERIFIED BY ACCOUNTANT.' from app_users u where u.active=true and u.role in('owner','admin');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_SUBMITTED_TO_ADMIN','dealer',p_dealer::text,jsonb_build_object('email_verified_for_login',true,'note',p_note));
end$$;
revoke all on function public.accountant_submit_dealer_to_admin(uuid,text) from public,anon;
grant execute on function public.accountant_submit_dealer_to_admin(uuid,text) to authenticated;

create or replace function public.approve_dealer(p_dealer uuid,p_rate_group text)
returns text language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;linked_count integer;code text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'OWNER OR ADMIN FINAL APPROVAL REQUIRED';end if;
 if p_rate_group not in('A','B','C') then raise exception 'VALID RATE GROUP REQUIRED';end if;
 select * into d from dealers where id=p_dealer for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 if d.status='approved' then raise exception 'DEALER ALREADY APPROVED';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'submitted_to_admin' or d.accountant_verified_by is null or d.accountant_verified_at is null then raise exception 'ACCOUNTANT VERIFICATION REQUIRED BEFORE FINAL APPROVAL';end if;
 if not exists(select 1 from app_users v where v.id=d.accountant_verified_by and v.active=true and lower(coalesce(v.role,''))='accountant') then raise exception 'ACTIVE ACCOUNTANT VERIFICATION REQUIRED BEFORE FINAL APPROVAL';end if;
 if lower(btrim(coalesce(d.email,'')))!~'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$' then raise exception 'VALID REGISTERED EMAIL REQUIRED';end if;
 perform 1 from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer for update;
 select count(*) into linked_count from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer;
 if linked_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;
 if linked_count=0 then insert into app_users(full_name,mobile,role,active,dealer_id) values(coalesce(nullif(btrim(d.contact_person),''),nullif(btrim(d.shop_name),''),'DEALER'),nullif(right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10),''),'dealer',true,p_dealer);end if;
 code:=next_dealer_code();
 update dealers set dealer_code=code,rate_group=p_rate_group,status='approved',approved_by=a.id,approved_at=now(),email=lower(btrim(d.email)) where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_FINAL_APPROVED','dealer',p_dealer::text,jsonb_build_object('dealer_code',code,'rate_group',p_rate_group,'accountant_verified_by',d.accountant_verified_by,'login_identity','REGISTERED_EMAIL','canonical_identity_bound',true));
 return code;
end$$;
revoke all on function public.approve_dealer(uuid,text) from public,anon;
grant execute on function public.approve_dealer(uuid,text) to authenticated;
revoke all on function public.approve_dealer(uuid,text,text) from public,anon,authenticated;
