-- TORVO V2 CUSTOMER DEMAND QUANTITY INTEGRITY
-- ADDITIVE: preserves existing demand/lead tables and extends the authoritative flow with selected quantity.
alter table public.customer_product_demands add column if not exists quantity integer not null default 1;
do $$ begin
 if not exists(select 1 from pg_constraint where conname='customer_product_demands_quantity_check') then
  alter table public.customer_product_demands add constraint customer_product_demands_quantity_check check(quantity between 1 and 9999);
 end if;
end $$;

create or replace function public.public_create_product_demand(p_full_name text,p_mobile text,p_pin_code text,p_search_text text,p_product_id uuid,p_brand text,p_model_number text,p_requirement_note text,p_marketing_opt_in boolean,p_lead_source text,p_quantity integer)
returns table(demand_id uuid,status text)
language plpgsql security definer set search_path=public as $$
declare r record;s text:=torvo_normalize_public_lead_source(p_lead_source);q integer:=coalesce(p_quantity,1);
begin
 if q<1 or q>9999 then raise exception 'QUANTITY MUST BE 1-9999';end if;
 for r in select * from public_create_product_demand(p_full_name,p_mobile,p_pin_code,p_search_text,p_product_id,p_brand,p_model_number,p_requirement_note,p_marketing_opt_in) loop
  update customer_contacts set lead_source=s where mobile=right(regexp_replace(coalesce(p_mobile,''),'\D','','g'),10);
  update customer_product_demands set lead_source=s,quantity=q where id=r.demand_id;
  return query select r.demand_id,r.status;
 end loop;
end$$;
revoke all on function public.public_create_product_demand(text,text,text,text,uuid,text,text,text,boolean,text,integer) from public;
grant execute on function public.public_create_product_demand(text,text,text,text,uuid,text,text,text,boolean,text,integer) to anon,authenticated;

drop function if exists public.dealer_customer_demand_leads(text,text,integer);
create function public.dealer_customer_demand_leads(p_device_id text,p_session_token text,p_limit integer default 50)
returns table(lead_id uuid,demand_id uuid,search_text text,quantity integer,pin_code text,brand text,model_number text,requirement_note text,routing_stage text,status text,sent_at timestamptz)
language plpgsql security definer set search_path=public as $$declare did uuid;begin
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 return query select l.id,d.id,d.search_text,d.quantity,d.pin_code,d.brand,d.model_number,d.requirement_note,l.routing_stage,l.status,l.sent_at
 from customer_demand_dealer_leads l join customer_product_demands d on d.id=l.demand_id
 where l.dealer_id=did and l.status in('sent','accepted') and d.status not in('closed','cancelled')
 order by l.sent_at desc limit greatest(1,least(coalesce(p_limit,50),100));
end$$;
revoke all on function public.dealer_customer_demand_leads(text,text,integer) from public,anon;
grant execute on function public.dealer_customer_demand_leads(text,text,integer) to authenticated;
