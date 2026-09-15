-- TORVO V2 CUSTOMER LEAD ADMIN LIFECYCLE
-- OWNER/ADMIN CAN REVIEW CONFIRMED DEMAND + DEALER ROUTING WITHOUT WEAKENING CONTACT PRIVACY.
create or replace function admin_customer_lead_center(p_status text default null,p_limit integer default 100)
returns table(demand_id uuid,created_at timestamptz,customer_name text,mobile text,pin_code text,search_text text,brand text,model_number text,requirement_note text,demand_status text,torvo_help_requested boolean,lead_id uuid,dealer_id uuid,dealer_name text,routing_stage text,lead_status text,sent_at timestamptz,accepted_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;s text:=lower(nullif(btrim(coalesce(p_status,'')),''));begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if s is not null and s not in('submitted','sourcing','available','closed','cancelled','sent','accepted','declined','expired') then raise exception 'INVALID LEAD STATUS';end if;
 return query select d.id,d.created_at,c.full_name,c.mobile,d.pin_code,d.search_text,d.brand,d.model_number,d.requirement_note,d.status,d.torvo_help_requested,l.id,l.dealer_id,x.shop_name,l.routing_stage,l.status,l.sent_at,l.accepted_at
 from customer_product_demands d join customer_contacts c on c.id=d.customer_id
 left join customer_demand_dealer_leads l on l.demand_id=d.id
 left join dealers x on x.id=l.dealer_id
 where s is null or d.status=s or l.status=s
 order by d.created_at desc,l.sent_at desc nulls last limit greatest(1,least(coalesce(p_limit,100),500));
end$$;
revoke all on function admin_customer_lead_center(text,integer) from public,anon;grant execute on function admin_customer_lead_center(text,integer) to authenticated;

create or replace function admin_close_customer_demand_lead(p_demand_id uuid,p_reason text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;r text:=left(nullif(btrim(coalesce(p_reason,'')),''),500);begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 update customer_product_demands set status='closed',updated_at=now() where id=p_demand_id and status not in('closed','cancelled');
 if not found then raise exception 'OPEN CUSTOMER REQUIREMENT REQUIRED';end if;
 update customer_demand_dealer_leads set status='closed',closed_at=now() where demand_id=p_demand_id and status in('sent','accepted');
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_DEMAND_CLOSED','CUSTOMER_PRODUCT_DEMAND',p_demand_id::text,jsonb_build_object('reason',r));
 return true;
end$$;
revoke all on function admin_close_customer_demand_lead(uuid,text) from public,anon;grant execute on function admin_close_customer_demand_lead(uuid,text) to authenticated;
