-- TORVO V2 PRIVACY-SAFE DEALER LOGIN ROUTING
-- DEALER MOBILE/PIN LOGIN IS RETIRED. DEALER NORMAL LOGIN USES REGISTERED EMAIL + SERVER-GENERATED EMAIL OTP.
-- STAFF NORMAL LOGIN USES STAFF USER ID + SERVER-GENERATED MASTER-EMAIL OTP AND DOES NOT USE THIS ROUTER.
-- Compatibility function retained only for old callers; it never returns role, user ID, Dealer ID, name, rate group or profile data.
create or replace function public_login_route(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m text;match_count integer;
begin
 m:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
 if length(m)<>10 or m!~'^[0-9]{10}$' then raise exception 'VALID_10_DIGIT_MOBILE_REQUIRED';end if;
 select count(*) into match_count from app_users u join dealers d on d.id=u.dealer_id where right(regexp_replace(coalesce(u.mobile,''),'\D','','g'),10)=m and u.active=true and lower(coalesce(u.role,''))='dealer' and lower(coalesce(d.status,''))='approved';
 if match_count<>1 then return jsonb_build_object('login_method','not_authorized');end if;
 return jsonb_build_object('login_method','dealer_email_otp');
end$$;
revoke all on function public_login_route(text) from public,anon,authenticated;
grant execute on function public_login_route(text) to anon,authenticated;
