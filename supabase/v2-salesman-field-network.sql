-- TORVO V2 SALESMAN FIELD NETWORK
-- REUSES THE EXISTING MINIMAL DISCOVERY LEAD + REPAIR OFFER TABLES.
-- DOES NOT CREATE OR APPROVE A DEALER. RUN AFTER v2-referral-repair-routing.sql.

create or replace function salesman_submit_dealer_discovery_lead(p_shop_name text,p_contact_person text,p_mobile text,p_pin_code text,p_capability text default 'product_sales',p_area text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;v_id uuid;v_mobile text;v_cap text;v_existing dealer_discovery_leads%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 v_mobile:=regexp_replace(coalesce(p_mobile,''),'\D','','g');if length(v_mobile)>10 then v_mobile:=right(v_mobile,10);end if;if length(v_mobile)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;
 if nullif(btrim(p_shop_name),'') is null then raise exception 'SHOP NAME REQUIRED';end if;if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 v_cap:=lower(btrim(coalesce(p_capability,'product_sales')));if v_cap not in('product_sales','repair_service','both') then raise exception 'INVALID CAPABILITY';end if;
 if exists(select 1 from dealers d where right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10)=v_mobile) then raise exception 'DEALER ALREADY EXISTS FOR THIS MOBILE';end if;
 select * into v_existing from dealer_discovery_leads where mobile=v_mobile and status in('new','verification_pending') order by created_at desc limit 1 for update;
 if v_existing.id is not null then
  update dealer_discovery_leads set shop_name=upper(btrim(p_shop_name)),contact_person=nullif(upper(btrim(p_contact_person)),''),whatsapp=v_mobile,pin_code=btrim(p_pin_code),area=nullif(upper(btrim(p_area)),''),capability=v_cap,updated_at=now() where id=v_existing.id returning id into v_id;
 else
  insert into dealer_discovery_leads(shop_name,contact_person,mobile,whatsapp,pin_code,area,capability,source,submitted_by,status) values(upper(btrim(p_shop_name)),nullif(upper(btrim(p_contact_person)),''),v_mobile,v_mobile,btrim(p_pin_code),nullif(upper(btrim(p_area)),''),v_cap,'salesman_field',u.id,'new') returning id into v_id;
 end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'SALESMAN_DEALER_LEAD_SUBMITTED','dealer_discovery_lead',v_id::text,jsonb_build_object('pin_code',btrim(p_pin_code),'capability',v_cap));return v_id;
end$$;
revoke all on function salesman_submit_dealer_discovery_lead(text,text,text,text,text,text) from public,anon;grant execute on function salesman_submit_dealer_discovery_lead(text,text,text,text,text,text) to authenticated;

create or replace function salesman_my_dealer_discovery_leads()
returns table(id uuid,shop_name text,contact_person text,mobile text,pin_code text,area text,capability text,status text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;return query select l.id,l.shop_name,l.contact_person,l.mobile,l.pin_code,l.area,l.capability,l.status,l.created_at from dealer_discovery_leads l where l.submitted_by=u.id order by l.created_at desc limit 100;end$$;
revoke all on function salesman_my_dealer_discovery_leads() from public,anon;grant execute on function salesman_my_dealer_discovery_leads() to authenticated;

create or replace function salesman_open_repair_requirements()
returns table(requirement_id uuid,brand text,model_number text,problem_description text,pin_code text,status text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;return query select r.id,r.brand,r.model_number,r.problem_description,r.customer_pin_code,r.status,r.created_at from customer_service_requirements r where r.status in('received','dealers_offered') order by r.created_at desc limit 100;end$$;
revoke all on function salesman_open_repair_requirements() from public,anon;grant execute on function salesman_open_repair_requirements() to authenticated;

create or replace function salesman_offer_repair_to_dealer(p_requirement_id uuid,p_dealer_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v_id uuid;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 perform 1 from customer_service_requirements where id=p_requirement_id and status in('received','dealers_offered');if not found then raise exception 'OPEN REPAIR REQUIREMENT REQUIRED';end if;
 perform 1 from dealers where id=p_dealer_id and status='approved' and customer_referral_enabled=true and repair_service_available=true;if not found then raise exception 'APPROVED REPAIR DEALER REQUIRED';end if;
 insert into customer_service_dealer_offers(requirement_id,dealer_id,offered_by,status) values(p_requirement_id,p_dealer_id,u.id,'offered') on conflict(requirement_id,dealer_id) do update set status=case when customer_service_dealer_offers.status in('withdrawn','cannot_repair') then 'offered' else customer_service_dealer_offers.status end,offered_by=u.id,offered_at=case when customer_service_dealer_offers.status in('withdrawn','cannot_repair') then now() else customer_service_dealer_offers.offered_at end returning id into v_id;
 update customer_service_requirements set status='dealers_offered',updated_at=now() where id=p_requirement_id and status='received';insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'REPAIR_REQUIREMENT_OFFERED','customer_service_requirement',p_requirement_id::text,jsonb_build_object('dealer_id',p_dealer_id,'offer_id',v_id));return v_id;end$$;
revoke all on function salesman_offer_repair_to_dealer(uuid,uuid) from public,anon;grant execute on function salesman_offer_repair_to_dealer(uuid,uuid) to authenticated;
