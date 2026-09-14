-- TORVO V2 TRUSTED AUTH WORKER RUNTIME GRANTS + DEALER ASSERTION COMPATIBILITY
-- SERVICE ROLE IS USED ONLY INSIDE SUPABASE EDGE FUNCTIONS; NEVER IN CLIENT CODE.

grant execute on function dealer_verify_pin(text,text) to service_role;
grant execute on function dealer_start_device_session(uuid,text,integer) to service_role;
grant execute on function dealer_validate_device_session(uuid,text,text) to service_role;
grant execute on function dealer_revoke_device_sessions(uuid,text) to service_role;
grant execute on function staff_verify_one_time_password(text,text,text,text) to service_role;
grant execute on function staff_create_verified_session(uuid,text,text) to service_role;

-- Replace the earlier compact assertion with explicit branches and no min(uuid) aggregate dependency.
create or replace function dealer_assert_my_device_session(p_device_id text,p_session_token text) returns uuid
language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_mobile text;v_user_count integer;v_dealer_count integer;v_dealer_id uuid;v_ok boolean;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION REQUIRED';end if;
 select count(*) into v_user_count from app_users where auth_user_id=auth.uid() and active=true;
 if v_user_count=0 then raise exception 'ACTIVE DEALER LOGIN REQUIRED';elsif v_user_count>1 then raise exception 'DEALER AUTH IDENTITY AMBIGUOUS';end if;
 select * into strict v_user from app_users where auth_user_id=auth.uid() and active=true;
 if lower(coalesce(v_user.role,''))<>'dealer' then raise exception 'ACTIVE DEALER LOGIN REQUIRED';end if;
 v_mobile:=right(regexp_replace(coalesce(v_user.mobile,''),'\D','','g'),10);
 if length(v_mobile)<>10 then raise exception 'DEALER MOBILE LINK REQUIRED';end if;
 select count(*) into v_dealer_count from dealers d where right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10)=v_mobile and lower(coalesce(d.status,''))='approved';
 if v_dealer_count=0 then raise exception 'APPROVED DEALER LINK REQUIRED';elsif v_dealer_count>1 then raise exception 'DEALER LINK AMBIGUOUS';end if;
 select d.id into strict v_dealer_id from dealers d where right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10)=v_mobile and lower(coalesce(d.status,''))='approved';
 v_ok:=dealer_validate_device_session(v_dealer_id,p_device_id,p_session_token);
 if not coalesce(v_ok,false) then raise exception 'DEALER DEVICE SESSION INVALID';end if;
 return v_dealer_id;
end$$;
revoke all on function dealer_assert_my_device_session(text,text) from public,anon;
grant execute on function dealer_assert_my_device_session(text,text) to authenticated;
