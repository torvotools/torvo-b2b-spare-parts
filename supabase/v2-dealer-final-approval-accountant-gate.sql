-- TORVO V2 FINAL DEALER APPROVAL MUST FOLLOW ACCOUNTANT VERIFICATION.
-- INSTALL AFTER v2-accountant-dealer-verification.sql AND v2-business-rpcs.sql.
create or replace function approve_dealer(p_dealer uuid,p_dealer_code text,p_rate_group text) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'OWNER OR ADMIN FINAL APPROVAL REQUIRED';end if;
 if p_rate_group not in('A','B','C') or nullif(trim(p_dealer_code),'') is null then raise exception 'DEALER CODE AND VALID RATE GROUP REQUIRED';end if;
 select * into d from dealers where id=p_dealer for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 if d.status='approved' then raise exception 'DEALER ALREADY APPROVED';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'submitted_to_admin' or d.accountant_verified_by is null or d.accountant_verified_at is null then raise exception 'ACCOUNTANT VERIFICATION AND SUBMISSION REQUIRED BEFORE FINAL APPROVAL';end if;
 if exists(select 1 from dealers x where x.id<>p_dealer and x.dealer_code=upper(trim(p_dealer_code))) then raise exception 'DEALER CODE ALREADY EXISTS';end if;
 update dealers set dealer_code=upper(trim(p_dealer_code)),rate_group=p_rate_group,status='approved',approved_by=a.id,approved_at=now() where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_FINAL_APPROVED','dealer',p_dealer::text,jsonb_build_object('dealer_code',upper(trim(p_dealer_code)),'rate_group',p_rate_group,'accountant_verified_by',d.accountant_verified_by,'accountant_verified_at',d.accountant_verified_at));
end$$;
revoke all on function approve_dealer(uuid,text,text) from public,anon;
grant execute on function approve_dealer(uuid,text,text) to authenticated;
