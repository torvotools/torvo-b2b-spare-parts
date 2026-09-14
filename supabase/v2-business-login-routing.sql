-- TORVO V2 PRIVACY-SAFE BUSINESS LOGIN ROUTING
-- PUBLIC CALLER MAY LEARN ONLY WHICH LOGIN METHOD TO SHOW FOR A REGISTERED ACTIVE NUMBER.
-- IT NEVER RETURNS ROLE, USER ID, DEALER ID, NAME, RATE GROUP OR OTHER PRIVATE PROFILE DATA.
-- SAME GENERIC not_authorized RESPONSE IS USED FOR UNKNOWN, INACTIVE OR UNSUPPORTED ACCOUNTS.
create or replace function public_login_route(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m text;u app_users%rowtype;match_count integer;
begin
 m:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
 if length(m)<>10 or m!~'^[0-9]{10}$' then raise exception 'VALID_10_DIGIT_MOBILE_REQUIRED';end if;
 select count(*) into match_count from app_users where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and active=true;
 -- Ambiguous duplicate active identities must never be routed by guessing the newest record.
 if match_count<>1 then return jsonb_build_object('login_method','not_authorized');end if;
 select * into u from app_users where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and active=true limit 1;
 if lower(coalesce(u.role,''))='dealer' then return jsonb_build_object('login_method','dealer_pin');end if;
 if torvo_is_staff_role(lower(coalesce(u.role,''))) then return jsonb_build_object('login_method','staff_whatsapp_otp');end if;
 return jsonb_build_object('login_method','not_authorized');
end$$;
revoke all on function public_login_route(text) from public;
revoke all on function public_login_route(text) from anon,authenticated;
grant execute on function public_login_route(text) to anon,authenticated;
