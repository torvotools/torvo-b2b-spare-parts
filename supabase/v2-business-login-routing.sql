-- TORVO V2 PRIVACY-SAFE DEALER MOBILE LOGIN ROUTING
-- STAFF NORMAL LOGIN IS ADMIN-ISSUED STAFF USER ID + ONE-TIME PASSWORD AND DOES NOT USE THIS MOBILE ROUTER.
-- PUBLIC CALLER MAY LEARN ONLY WHETHER ONE ACTIVE REGISTERED DEALER MAY USE DEALER PIN LOGIN.
-- IT NEVER RETURNS ROLE, USER ID, DEALER ID, NAME, RATE GROUP OR OTHER PRIVATE PROFILE DATA.
-- SAME GENERIC not_authorized RESPONSE IS USED FOR UNKNOWN, INACTIVE, DUPLICATE OR NON-DEALER ACCOUNTS.
create or replace function public_login_route(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m text;match_count integer;
begin
 m:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
 if length(m)<>10 or m!~'^[0-9]{10}$' then raise exception 'VALID_10_DIGIT_MOBILE_REQUIRED';end if;
 select count(*) into match_count from app_users u join dealers d on d.id=u.dealer_id where right(regexp_replace(coalesce(u.mobile,''),'\D','','g'),10)=m and u.active=true and lower(coalesce(u.role,''))='dealer' and lower(coalesce(d.status,''))='approved';
 if match_count<>1 then return jsonb_build_object('login_method','not_authorized');end if;
 return jsonb_build_object('login_method','dealer_pin');
end$$;
revoke all on function public_login_route(text) from public,anon,authenticated;
grant execute on function public_login_route(text) to anon,authenticated;
