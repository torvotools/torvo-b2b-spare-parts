-- TORVO V2 CUSTOMER DEMAND -> CONTROLLED DEALER ROUTING
-- CONTACT STAYS PRIVATE UNTIL A DEVICE-VERIFIED DEALER ACCEPTS ITS ASSIGNED LEAD.
create table if not exists customer_demand_dealer_leads(
 id uuid primary key default gen_random_uuid(),
 demand_id uuid not null references customer_product_demands(id) on delete cascade,
 dealer_id uuid not null references dealers(id) on delete restrict,
 routing_stage text not null default 'LOCAL' check(routing_stage in('LOCAL','EXTENDED','TORVO_ASSIGNED')),
 status text not null default 'sent' check(status in('sent','accepted','declined','expired','closed')),
 sent_at timestamptz not null default now(),accepted_at timestamptz,declined_at timestamptz,closed_at timestamptz,
 assigned_by uuid references app_users(id),
 unique(demand_id,dealer_id)
);
create index if not exists idx_customer_demand_dealer_leads_dealer on customer_demand_dealer_leads(dealer_id,status,sent_at desc);
create index if not exists idx_customer_demand_dealer_leads_demand on customer_demand_dealer_leads(demand_id,status,sent_at desc);
alter table customer_demand_dealer_leads enable row level security;
revoke all on customer_demand_dealer_leads from anon,authenticated;

-- OWNER/ADMIN routes only a confirmed demand to an approved dealer. Distance stages are labels only here;
-- actual 0-25/25-50 KM routing must be supplied by a truthful geospatial/service-area selector later.
create or replace function admin_route_customer_demand_to_dealer(p_demand_id uuid,p_dealer_id uuid,p_routing_stage text default 'TORVO_ASSIGNED')
returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;rid uuid;stage text:=upper(btrim(coalesce(p_routing_stage,'')));
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 if stage not in('LOCAL','EXTENDED','TORVO_ASSIGNED') then raise exception 'INVALID ROUTING STAGE';end if;
 if not exists(select 1 from customer_product_demands d where d.id=p_demand_id and d.status not in('closed','cancelled')) then raise exception 'ACTIVE CUSTOMER REQUIREMENT REQUIRED';end if;
 if not exists(select 1 from dealers d where d.id=p_dealer_id and d.status='approved') then raise exception 'APPROVED DEALER REQUIRED';end if;
 insert into customer_demand_dealer_leads(demand_id,dealer_id,routing_stage,assigned_by) values(p_demand_id,p_dealer_id,stage,u.id)
 on conflict(demand_id,dealer_id) do update set routing_stage=excluded.routing_stage,status='sent',sent_at=now(),accepted_at=null,declined_at=null,closed_at=null,assigned_by=u.id returning id into rid;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_DEMAND_ROUTED','CUSTOMER_PRODUCT_DEMAND',p_demand_id::text,jsonb_build_object('dealer_id',p_dealer_id,'routing_stage',stage));
 return rid;
end$$;
revoke all on function admin_route_customer_demand_to_dealer(uuid,uuid,text) from public,anon;grant execute on function admin_route_customer_demand_to_dealer(uuid,uuid,text) to authenticated;

-- Device-verified dealer inbox exposes requirement only: NO customer name/mobile/WhatsApp.
create or replace function dealer_customer_demand_leads(p_device_id text,p_session_token text,p_limit integer default 50)
returns table(lead_id uuid,demand_id uuid,search_text text,pin_code text,brand text,model_number text,requirement_note text,routing_stage text,status text,sent_at timestamptz)
language plpgsql security definer set search_path=public as $$declare did uuid;begin
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 return query select l.id,d.id,d.search_text,d.pin_code,d.brand,d.model_number,d.requirement_note,l.routing_stage,l.status,l.sent_at from customer_demand_dealer_leads l join customer_product_demands d on d.id=l.demand_id where l.dealer_id=did and l.status in('sent','accepted') order by l.sent_at desc limit greatest(1,least(coalesce(p_limit,50),100));
end$$;
revoke all on function dealer_customer_demand_leads(text,text,integer) from public,anon;grant execute on function dealer_customer_demand_leads(text,text,integer) to authenticated;

-- Accept first, then unlock only this customer's necessary contact for this assigned dealer.
-- Reopening an already accepted lead is intentionally idempotent so a refreshed app can unlock contact again.
create or replace function dealer_accept_customer_demand_lead(p_lead_id uuid,p_device_id text,p_session_token text)
returns table(lead_id uuid,customer_name text,mobile text,whatsapp text,pin_code text,search_text text)
language plpgsql security definer set search_path=public as $$declare did uuid;l customer_demand_dealer_leads%rowtype;au uuid;
begin
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 select * into l from customer_demand_dealer_leads where id=p_lead_id and dealer_id=did for update;
 if l.id is null then raise exception 'ASSIGNED CUSTOMER LEAD REQUIRED';end if;
 if l.status not in('sent','accepted') then raise exception 'CUSTOMER LEAD IS NOT OPEN';end if;
 update customer_demand_dealer_leads set status='accepted',accepted_at=coalesce(accepted_at,now()) where id=l.id;
 select id into au from app_users where auth_user_id=auth.uid() and active=true limit 1;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(au,'CUSTOMER_DEMAND_LEAD_ACCEPTED','CUSTOMER_DEMAND_DEALER_LEAD',l.id::text,jsonb_build_object('demand_id',l.demand_id,'dealer_id',did,'already_accepted',l.status='accepted'));
 return query select l.id,c.full_name,c.mobile,c.whatsapp,d.pin_code,d.search_text from customer_product_demands d join customer_contacts c on c.id=d.customer_id where d.id=l.demand_id and d.status not in('closed','cancelled');
end$$;
revoke all on function dealer_accept_customer_demand_lead(uuid,text,text) from public,anon;grant execute on function dealer_accept_customer_demand_lead(uuid,text,text) to authenticated;

create or replace function dealer_decline_customer_demand_lead(p_lead_id uuid,p_device_id text,p_session_token text)
returns boolean language plpgsql security definer set search_path=public as $$declare did uuid;l customer_demand_dealer_leads%rowtype;au uuid;begin
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 select * into l from customer_demand_dealer_leads where id=p_lead_id and dealer_id=did and status='sent' for update;
 if l.id is null then raise exception 'OPEN ASSIGNED CUSTOMER LEAD REQUIRED';end if;
 update customer_demand_dealer_leads set status='declined',declined_at=now() where id=l.id;
 select id into au from app_users where auth_user_id=auth.uid() and active=true limit 1;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(au,'CUSTOMER_DEMAND_LEAD_DECLINED','CUSTOMER_DEMAND_DEALER_LEAD',l.id::text,jsonb_build_object('demand_id',l.demand_id,'dealer_id',did));
 return true;
end$$;
revoke all on function dealer_decline_customer_demand_lead(uuid,text,text) from public,anon;grant execute on function dealer_decline_customer_demand_lead(uuid,text,text) to authenticated;
