-- TORVO V2 CUSTOMER DEMAND FOUND / CONVERSION LIFECYCLE
-- OWNER/ADMIN records a truthful found/available result. Public customer may read only their own result using demand id + matching mobile.

alter table customer_product_demands add column if not exists converted_at timestamptz;
alter table customer_product_demands add column if not exists closed_at timestamptz;

create or replace function admin_mark_customer_demand_available(p_demand_id uuid,p_found_dealer_id uuid default null,p_found_contact_note text default null,p_sourcing_note text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;d customer_product_demands%rowtype;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if length(coalesce(p_found_contact_note,''))>1000 or length(coalesce(p_sourcing_note,''))>1000 then raise exception 'NOTE TOO LONG';end if;
 select * into d from customer_product_demands where id=p_demand_id for update;
 if d.id is null then raise exception 'CUSTOMER REQUIREMENT NOT FOUND';end if;
 if d.status in('closed','cancelled') then raise exception 'CUSTOMER REQUIREMENT IS NOT ACTIVE';end if;
 if p_found_dealer_id is not null and not exists(select 1 from dealers x where x.id=p_found_dealer_id and x.status='approved') then raise exception 'APPROVED DEALER REQUIRED';end if;
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
 return query select d.id,d.status,d.search_text,case when d.status='available' then 'THE ITEM YOU REQUESTED IS NOW AVAILABLE.' when d.status='closed' then 'CUSTOMER REQUIREMENT CLOSED.' else 'TORVO IS WORKING ON YOUR REQUIREMENT.' end,d.found_dealer_id,case when d.status='available' then d.found_contact_note else null end,d.available_at from customer_product_demands d join customer_contacts c on c.id=d.customer_id where d.id=p_demand_id and c.mobile=m;
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
