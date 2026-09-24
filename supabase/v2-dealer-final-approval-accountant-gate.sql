-- TORVO V2 FINAL DEALER APPROVAL: ACCOUNTANT GATE + REGISTERED EMAIL IDENTITY + SYSTEM DEALER CODE.
-- Dealer code is generated only at final approval: DI@00011, DI@00012, ...
create or replace function approve_dealer(p_dealer uuid,p_rate_group text) returns text language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;linked_count integer;code text;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'OWNER OR ADMIN FINAL APPROVAL REQUIRED';end if;
 if p_rate_group not in('A','B','C') then raise exception 'VALID RATE GROUP REQUIRED';end if;
 select * into d from dealers where id=p_dealer for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 if d.status='approved' then raise exception 'DEALER ALREADY APPROVED';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'submitted_to_admin' or d.accountant_verified_by is null or d.accountant_verified_at is null then raise exception 'ACCOUNTANT VERIFICATION REQUIRED BEFORE FINAL APPROVAL';end if;
 if lower(btrim(coalesce(d.email,'')))!~ '^[a-z0-9._%+\\-]+@[a-z0-9.\\-]+\\.[a-z]{2,}$' then raise exception 'VALID REGISTERED EMAIL REQUIRED';end if;
 perform 1 from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer for update;
 select count(*) into linked_count from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer;
 if linked_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;
 if linked_count=0 then insert into app_users(full_name,mobile,role,active,dealer_id) values(coalesce(nullif(btrim(d.contact_person),''),nullif(btrim(d.shop_name),''),'DEALER'),nullif(right(regexp_replace(coalesce(d.mobile,''),'\\D','','g'),10),''),'dealer',true,p_dealer);end if;
 code:=next_dealer_code();
 update dealers set dealer_code=code,rate_group=p_rate_group,status='approved',approved_by=a.id,approved_at=now(),email=lower(btrim(d.email)) where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_FINAL_APPROVED','dealer',p_dealer::text,jsonb_build_object('dealer_code',code,'rate_group',p_rate_group,'accountant_verified_by',d.accountant_verified_by,'login_identity','REGISTERED_EMAIL','canonical_identity_bound',true));
 return code;
end$$;
revoke all on function approve_dealer(uuid,text) from public,anon;grant execute on function approve_dealer(uuid,text) to authenticated;
revoke all on function approve_dealer(uuid,text,text) from public,anon,authenticated;
