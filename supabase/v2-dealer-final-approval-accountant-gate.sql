-- TORVO V2 FINAL DEALER APPROVAL MUST FOLLOW ACCOUNTANT VERIFICATION.
-- INSTALL AFTER v2-accountant-dealer-verification.sql AND v2-business-rpcs.sql.
-- THIS IS THE FINAL approve_dealer DEFINITION, SO IT MUST PRESERVE THE CANONICAL app_users.dealer_id BINDING.
create or replace function approve_dealer(p_dealer uuid,p_dealer_code text,p_rate_group text) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;mob text;linked_count integer;legacy_count integer;legacy_id uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'OWNER OR ADMIN FINAL APPROVAL REQUIRED';end if;
 if p_rate_group not in('A','B','C') or nullif(trim(p_dealer_code),'') is null then raise exception 'DEALER CODE AND VALID RATE GROUP REQUIRED';end if;
 select * into d from dealers where id=p_dealer for update;if not found then raise exception 'DEALER NOT FOUND';end if;
 if d.status='approved' then raise exception 'DEALER ALREADY APPROVED';end if;
 if coalesce(d.accountant_verification_status,'pending_accountant')<>'submitted_to_admin' or d.accountant_verified_by is null or d.accountant_verified_at is null then raise exception 'ACCOUNTANT VERIFICATION AND SUBMISSION REQUIRED BEFORE FINAL APPROVAL';end if;
 if exists(select 1 from dealers x where x.id<>p_dealer and upper(coalesce(x.dealer_code,''))=upper(trim(p_dealer_code))) then raise exception 'DEALER CODE ALREADY EXISTS';end if;

 -- Lock any already-linked canonical Dealer identity first. Exactly one active Dealer app identity is allowed.
 perform 1 from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer for update;
 select count(*) into linked_count from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id=p_dealer;
 if linked_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;

 -- Legacy migration path: bind only when the normalized mobile resolves to exactly one unbound active Dealer app user.
 -- Never choose one row from duplicate mobile identities and never approve without a canonical app identity.
 if linked_count=0 then
  mob:=right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10);
  if length(mob)<>10 then raise exception 'VALID DEALER MOBILE REQUIRED';end if;
  perform 1 from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id is null and right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=mob for update;
  select count(*),min(id) into legacy_count,legacy_id from app_users where active=true and lower(coalesce(role,''))='dealer' and dealer_id is null and right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=mob;
  if legacy_count=0 then raise exception 'DEALER APP IDENTITY REQUIRED BEFORE APPROVAL';
  elsif legacy_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;
  update app_users set dealer_id=p_dealer where id=legacy_id and dealer_id is null;
  if not found then raise exception 'DEALER APP IDENTITY BIND FAILED';end if;
 end if;

 -- Approval status changes only after the canonical identity gate succeeds.
 update dealers set dealer_code=upper(trim(p_dealer_code)),rate_group=p_rate_group,status='approved',approved_by=a.id,approved_at=now() where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_FINAL_APPROVED','dealer',p_dealer::text,jsonb_build_object('dealer_code',upper(trim(p_dealer_code)),'rate_group',p_rate_group,'accountant_verified_by',d.accountant_verified_by,'accountant_verified_at',d.accountant_verified_at,'canonical_identity_bound',true));
end$$;
revoke all on function approve_dealer(uuid,text,text) from public,anon;
grant execute on function approve_dealer(uuid,text,text) to authenticated;
