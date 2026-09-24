-- TORVO V2 TRUSTED AUTH WORKER RUNTIME GRANTS + DEALER ASSERTION COMPATIBILITY
-- SERVICE ROLE IS USED ONLY INSIDE SUPABASE EDGE FUNCTIONS; NEVER IN CLIENT CODE.

-- Dealer PIN login is legacy/retired. Canonical login is registered Email OTP.
revoke all on function dealer_verify_pin(text,text) from public,anon,authenticated;
grant execute on function dealer_email_otp_begin(text,text,text) to service_role;
grant execute on function dealer_email_otp_verify(uuid,text,text,text) to service_role;
grant execute on function dealer_start_device_session(uuid,text,integer) to service_role;
grant execute on function dealer_validate_device_session(uuid,text,text) to service_role;
grant execute on function dealer_revoke_device_sessions(uuid,text) to service_role;
grant execute on function staff_email_otp_begin(text,text,text) to service_role;
grant execute on function staff_email_otp_verify(uuid,text,text,text) to service_role;
grant execute on function staff_create_verified_session(uuid,text,text) to service_role;

-- Keep the final runtime assertion on the canonical app_users.dealer_id identity link.
-- This file is installed after v2-dealer-pin-auth.sql, so it must never restore mobile-based relinking.
create or replace function dealer_assert_my_device_session(p_device_id text,p_session_token text) returns uuid
language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_user_count integer;v_dealer_id uuid;v_ok boolean;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION REQUIRED';end if;
 select count(*) into v_user_count from app_users where auth_user_id=auth.uid() and active=true;
 if v_user_count=0 then raise exception 'ACTIVE DEALER LOGIN REQUIRED';elsif v_user_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;
 select * into strict v_user from app_users where auth_user_id=auth.uid() and active=true;
 if lower(coalesce(v_user.role,''))<>'dealer' then raise exception 'ACTIVE DEALER LOGIN REQUIRED';end if;
 if v_user.dealer_id is null then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 select d.id into strict v_dealer_id from dealers d where d.id=v_user.dealer_id and lower(coalesce(d.status,''))='approved';
 if length(btrim(coalesce(p_device_id,'')))<8 or length(coalesce(p_device_id,''))>180 or length(coalesce(p_session_token,''))<32 then raise exception 'DEALER DEVICE SESSION INVALID';end if;
 v_ok:=dealer_validate_device_session(v_dealer_id,p_device_id,p_session_token);
 if not coalesce(v_ok,false) then raise exception 'DEALER DEVICE SESSION INVALID';end if;
 return v_dealer_id;
exception when no_data_found then raise exception 'APPROVED DEALER LINK REQUIRED';
end$$;
revoke all on function dealer_assert_my_device_session(text,text) from public,anon;
grant execute on function dealer_assert_my_device_session(text,text) to authenticated;