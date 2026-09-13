-- TORVO V2 PUBLIC DEALER REGISTRATION INTAKE
-- CREATES ONLY A PENDING DEALER REQUEST. NEVER AUTO-APPROVES OR ASSIGNS A RATE GROUP.
create or replace function public_register_dealer(
 p_shop_name text,p_contact_person text,p_mobile text,p_pin_code text,p_business_type text default null
) returns table(dealer_id uuid,status text)
language plpgsql security definer set search_path=public as $$
declare v_mobile text;v_id uuid;begin
 if length(btrim(coalesce(p_shop_name,'')))<2 then raise exception 'SHOP / FIRM NAME REQUIRED';end if;
 if length(btrim(coalesce(p_contact_person,'')))<2 then raise exception 'CONTACT PERSON REQUIRED';end if;
 v_mobile:=regexp_replace(coalesce(p_mobile,''),'\D','','g');if length(v_mobile)>10 then v_mobile:=right(v_mobile,10);end if;
 if length(v_mobile)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;
 if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 if exists(select 1 from dealers where mobile=v_mobile and status in('pending','approved','hold')) then raise exception 'THIS MOBILE NUMBER ALREADY HAS A DEALER REGISTRATION';end if;
 insert into dealers(shop_name,contact_person,mobile,whatsapp,pin_code,address,status)
 values(upper(btrim(p_shop_name)),upper(btrim(p_contact_person)),v_mobile,v_mobile,btrim(p_pin_code),case when nullif(btrim(p_business_type),'') is null then null else 'BUSINESS TYPE: '||upper(btrim(p_business_type)) end,'pending') returning id into v_id;
 return query select v_id,'PENDING VERIFICATION'::text;
end$$;
revoke all on function public_register_dealer(text,text,text,text,text) from public;
grant execute on function public_register_dealer(text,text,text,text,text) to anon,authenticated;
