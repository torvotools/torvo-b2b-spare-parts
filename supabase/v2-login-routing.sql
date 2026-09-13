-- PRIVACY-SAFE LOGIN ROUTING. APPLY AFTER v2-staff-whatsapp-auth.sql.
create or replace function public_login_route(p_mobile text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype; m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
begin
 if length(m)<>10 then return jsonb_build_object('login_method','denied'); end if;
 select * into u from app_users where right(regexp_replace(coalesce(mobile,''),'\D','','g'),10)=m and active=true limit 1;
 if u.id is null then return jsonb_build_object('login_method','denied'); end if;
 if torvo_is_staff_role(u.role) then return jsonb_build_object('login_method','staff_whatsapp_otp'); end if;
 if u.role='dealer' then return jsonb_build_object('login_method','dealer_pin'); end if;
 return jsonb_build_object('login_method','denied');
end $$;
revoke all on function public_login_route(text) from public;
grant execute on function public_login_route(text) to anon,authenticated;
