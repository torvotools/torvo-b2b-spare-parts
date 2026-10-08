-- TORVO V2 PUBLIC DEALER REGISTRATION INTAKE
-- CREATES ONLY A PENDING DEALER REQUEST. NEVER AUTO-APPROVES OR ASSIGNS A RATE GROUP.
-- STATE AND DISTRICT MUST MATCH THE AUTHORITATIVE LOCATION MASTER.
-- CITY IS REQUIRED AND MAY COME FROM THE CITY DROPDOWN OR OTHER / Add City FALLBACK.
-- RESULT REMAINS PENDING VERIFICATION UNTIL ACCOUNTANT + OWNER/ADMIN APPROVAL.

create or replace function public_register_dealer(p_shop_name text,p_contact_person text,p_mobile text,p_email text,p_pin_code text,p_business_type text,p_state text,p_district text,p_city text)
returns table(dealer_id uuid,status text)
language plpgsql security definer set search_path=public as $$
declare m text;e text;did uuid;s text;d text;c text;
begin
 if length(btrim(coalesce(p_shop_name,'')))<2 or length(btrim(coalesce(p_contact_person,'')))<2 then raise exception 'SHOP AND CONTACT PERSON REQUIRED';end if;
 m:=regexp_replace(coalesce(p_mobile,''),'\\D','','g');if length(m)>10 then m:=right(m,10);end if;if length(m)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;
 e:=lower(btrim(coalesce(p_email,'')));if e!~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$' then raise exception 'VALID EMAIL ID REQUIRED';end if;
 if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 s:=upper(btrim(coalesce(p_state,'')));d:=upper(btrim(coalesce(p_district,'')));c:=upper(btrim(coalesce(p_city,'')));if s='' or d='' or c='' then raise exception 'STATE DISTRICT AND CITY REQUIRED';end if;
 if not exists(select 1 from location_states where active) or not exists(select 1 from location_districts where active) or not exists(select 1 from location_cities where active) then raise exception 'LOCATION_MASTER_NOT_READY';end if;
 if not exists(select 1 from location_districts ld join location_states ls on ls.id=ld.state_id where ld.active and ls.active and upper(btrim(ls.name))=s and upper(btrim(ld.name))=d) then raise exception 'VALID_STATE_DISTRICT_REQUIRED';end if;
 if exists(select 1 from dealers x where x.mobile=m and x.status in('pending','approved','hold')) then raise exception 'THIS MOBILE NUMBER ALREADY HAS A DEALER REGISTRATION';end if;
 if exists(select 1 from dealers x where lower(btrim(coalesce(x.email,'')))=e and x.status in('pending','approved','hold')) then raise exception 'THIS EMAIL ID ALREADY HAS A DEALER REGISTRATION';end if;
 insert into dealers(shop_name,contact_person,mobile,whatsapp,email,pin_code,state,district,city,address,status)
 values(upper(btrim(p_shop_name)),upper(btrim(p_contact_person)),m,m,e,btrim(p_pin_code),s,d,c,case when nullif(btrim(p_business_type),'') is null then null else 'BUSINESS TYPE: '||upper(btrim(p_business_type)) end,'pending') returning id into did;
 return query select did,'PENDING VERIFICATION'::text;
end$$;
revoke all on function public_register_dealer(text,text,text,text,text,text,text,text,text) from public;
grant execute on function public_register_dealer(text,text,text,text,text,text,text,text,text) to anon,authenticated;
