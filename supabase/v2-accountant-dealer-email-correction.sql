-- TORVO V2 ACCOUNTANT DEALER REGISTERED-EMAIL CORRECTION
-- Additive final boundary after v2-accountant-dealer-verification.sql.
drop function if exists accountant_update_dealer_request(uuid,text,text,text,text,text,text,text,text,text,text);

create or replace function accountant_update_dealer_request(
 p_dealer uuid,p_shop_name text,p_contact_person text,p_mobile text,p_whatsapp text,
 p_email text,p_address text,p_city text,p_district text,p_state text,p_pin_code text,p_note text default null
) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d dealers%rowtype;mob text;wa text;mail text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'NOT AUTHORIZED';end if;
 select * into d from dealers where id=p_dealer for update;
 if not found or d.status='approved' then raise exception 'DEALER REQUEST NOT EDITABLE';end if;
 if a.role='accountant' and coalesce(d.accountant_verification_status,'pending_accountant')<>'pending_accountant' then raise exception 'REQUEST ALREADY SUBMITTED TO ADMIN';end if;
 if length(btrim(coalesce(p_shop_name,'')))<2 or length(btrim(coalesce(p_contact_person,'')))<2 then raise exception 'SHOP AND CONTACT PERSON REQUIRED';end if;
 mob:=regexp_replace(coalesce(p_mobile,''),'\D','','g');if length(mob)>10 then mob:=right(mob,10);end if;if length(mob)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;
 wa:=regexp_replace(coalesce(p_whatsapp,mob),'\D','','g');if length(wa)>10 then wa:=right(wa,10);end if;if length(wa)<>10 then raise exception 'VALID 10 DIGIT WHATSAPP REQUIRED';end if;
 mail:=lower(btrim(coalesce(p_email,'')));if mail!~'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$' then raise exception 'VALID REGISTERED EMAIL REQUIRED';end if;
 if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 if exists(select 1 from dealers x where x.id<>p_dealer and x.mobile=mob and x.status in('pending','approved','hold')) then raise exception 'MOBILE NUMBER ALREADY USED BY ANOTHER DEALER';end if;
 if exists(select 1 from dealers x where x.id<>p_dealer and lower(btrim(coalesce(x.email,'')))=mail and x.status in('pending','approved','hold')) then raise exception 'REGISTERED EMAIL ALREADY USED BY ANOTHER DEALER';end if;
 update dealers set shop_name=upper(btrim(p_shop_name)),contact_person=upper(btrim(p_contact_person)),mobile=mob,whatsapp=wa,email=mail,address=nullif(upper(btrim(p_address)),''),city=nullif(upper(btrim(p_city)),''),district=nullif(upper(btrim(p_district)),''),state=nullif(upper(btrim(p_state)),''),pin_code=btrim(p_pin_code),accountant_verification_note=nullif(upper(btrim(p_note)),'') where id=p_dealer;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_REQUEST_EDITED','dealer',p_dealer::text,jsonb_build_object('stage','ACCOUNTANT_VERIFICATION','registered_email_corrected',mail is distinct from lower(btrim(coalesce(d.email,'')))));
end$$;
revoke all on function accountant_update_dealer_request(uuid,text,text,text,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function accountant_update_dealer_request(uuid,text,text,text,text,text,text,text,text,text,text,text) to authenticated;
