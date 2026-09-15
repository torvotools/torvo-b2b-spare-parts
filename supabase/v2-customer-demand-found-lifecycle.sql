-- TORVO V2 CUSTOMER DEMAND FOUND / CONVERSION LIFECYCLE
-- OWNER/ADMIN records a truthful found/available result. Public customer may read only their own result using demand id + matching mobile.

alter table customer_product_demands add column if not exists converted_at timestamptz;
alter table customer_product_demands add column if not exists closed_at timestamptz;

create or replace function admin_mark_customer_demand_available(p_demand_id uuid,p_found_dealer_id uuid default null,p_found_contact_note text default null,p_sourcing_note text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;d customer_product_demands%rowtype;fd dealers%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if length(coalesce(p_found_contact_note,''))>1000 or length(coalesce(p_sourcing_note,''))>1000 then raise exception 'NOTE TOO LONG';end if;
 select * into d from customer_product_demands where id=p_demand_id for update;
 if d.id is null then raise exception 'CUSTOMER REQUIREMENT NOT FOUND';end if;
 if d.status in('closed','cancelled') then raise exception 'CUSTOMER REQUIREMENT IS NOT ACTIVE';end if;
 if p_found_dealer_id is not null then select * into fd from dealers where id=p_found_dealer_id for update;if fd.id is null or fd.status<>'approved' then raise exception 'APPROVED DEALER REQUIRED';end if;end if;
 update customer_product_demands set status='available',found_dealer_id=p_found_dealer_id,found_contact_note=upper(nullif(btrim(p_found_contact_note),'')),sourcing_note=upper(nullif(btrim(p_sourcing_note),'')),available_at=coalesce(available_at,now()),updated_at=now() where id=p_demand_id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_DEMAND_AVAILABLE','CUSTOMER_PRODUCT_DEMAND',p_demand_id::text,jsonb_build_object('found_dealer_id',p_found_dealer_id));return true;
end$$;
revoke all on function admin_mark_customer_demand_available(uuid,uuid,text,text) from public,anon;grant execute on function admin_mark_customer_demand_available(uuid,uuid,text,text) to authenticated;

create or replace function public_customer_demand_result(p_demand_id uuid,p_mobile text)
returns table(demand_id uuid,status text,search_text text,message text,found_dealer_id uuid,found_contact_note text,available_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare m text:=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
begin
 if length(m)<>10 then raise exception '10-DIGIT MOBILE REQUIRED';end if;
 return query select d.id,d.status,d.search_text,
 case when d.status='available' then 'THE ITEM YOU REQUESTED IS NOW AVAILABLE.' when d.status='closed' then 'CUSTOMER REQUIREMENT CLOSED.' else 'TORVO IS WORKING ON YOUR REQUIREMENT.' end,
 case when d.status='available' then d.found_dealer_id else null end,
 case when d.status='available' then d.found_contact_note else null end,
 case when d.status='available' then d.available_at else null end
 from customer_product_demands d join customer_contacts c on c.id=d.customer_id
 where d.id=p_demand_id and right(regexp_replace(coalesce(c.mobile,''),'\D','','g'),10)=m;
end$$;
revoke all on function public_customer_demand_result(uuid,text) from public;grant execute on function public_customer_demand_result(uuid,text) to anon,authenticated;

create or replace function admin_convert_customer_demand(p_demand_id uuid,p_reason text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;d customer_product_demands%rowtype;r text:=left(upper(btrim(coalesce(p_reason,''))),500);
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 select * into d from customer_product_demands where id=p_demand_id for update;if d.id is null then raise exception 'CUSTOMER REQUIREMENT NOT FOUND';end if;if d.status<>'available' then raise exception 'AVAILABLE CUSTOMER REQUIREMENT REQUIRED';end if;
 update customer_product_demands set status='closed',converted_at=coalesce(converted_at,now()),closed_at=coalesce(closed_at,now()),updated_at=now() where id=p_demand_id;
 update customer_demand_dealer_leads set status='closed',closed_at=coalesce(closed_at,now()) where demand_id=p_demand_id and status in('sent','accepted');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_DEMAND_CONVERTED','CUSTOMER_PRODUCT_DEMAND',p_demand_id::text,jsonb_build_object('reason',nullif(r,''),'found_dealer_id',d.found_dealer_id));return true;
end$$;
revoke all on function admin_convert_customer_demand(uuid,text) from public,anon;grant execute on function admin_convert_customer_demand(uuid,text) to authenticated;

-- POST-FOUND OVERRIDE: the base admin lifecycle is installed before found timestamps exist.
create or replace function admin_customer_lead_center(p_status text default null,p_limit integer default 100)
returns table(demand_id uuid,created_at timestamptz,customer_name text,mobile text,pin_code text,search_text text,brand text,model_number text,requirement_note text,demand_status text,torvo_help_requested boolean,lead_id uuid,dealer_id uuid,dealer_name text,routing_stage text,lead_status text,sent_at timestamptz,accepted_at timestamptz,found_dealer_id uuid,found_dealer_name text,found_contact_note text,available_at timestamptz,converted_at timestamptz,closed_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;s text:=lower(nullif(btrim(coalesce(p_status,'')),''));begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if s is not null and s not in('submitted','sourcing','available','closed','cancelled','sent','accepted','declined','expired') then raise exception 'INVALID LEAD STATUS';end if;
 return query select d.id,d.created_at,c.full_name,c.mobile,d.pin_code,d.search_text,d.brand,d.model_number,d.requirement_note,d.status,d.torvo_help_requested,l.id,l.dealer_id,x.shop_name,l.routing_stage,l.status,l.sent_at,l.accepted_at,d.found_dealer_id,fd.shop_name,d.found_contact_note,d.available_at,d.converted_at,d.closed_at
 from customer_product_demands d join customer_contacts c on c.id=d.customer_id
 left join customer_demand_dealer_leads l on l.demand_id=d.id
 left join dealers x on x.id=l.dealer_id
 left join dealers fd on fd.id=d.found_dealer_id
 where s is null or d.status=s or l.status=s
 order by d.created_at desc,l.sent_at desc nulls last limit greatest(1,least(coalesce(p_limit,100),500));
end$$;
revoke all on function admin_customer_lead_center(text,integer) from public,anon;grant execute on function admin_customer_lead_center(text,integer) to authenticated;

-- Recreate close RPC here so every manual Admin close records the demand close timestamp too.
create or replace function admin_close_customer_demand_lead(p_demand_id uuid,p_reason text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;r text:=left(nullif(upper(btrim(coalesce(p_reason,''))),''),500);begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 update customer_product_demands set status='closed',closed_at=coalesce(closed_at,now()),updated_at=now() where id=p_demand_id and status not in('closed','cancelled');
 if not found then raise exception 'OPEN CUSTOMER REQUIREMENT REQUIRED';end if;
 update customer_demand_dealer_leads set status='closed',closed_at=coalesce(closed_at,now()) where demand_id=p_demand_id and status in('sent','accepted');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_DEMAND_CLOSED','CUSTOMER_PRODUCT_DEMAND',p_demand_id::text,jsonb_build_object('reason',r));
 return true;
end$$;
revoke all on function admin_close_customer_demand_lead(uuid,text) from public,anon;grant execute on function admin_close_customer_demand_lead(uuid,text) to authenticated;
