-- TORVO V2 purchase-cost history. Owner-only financial source for profit reports.
create table if not exists purchase_cost_history(
 id uuid primary key default gen_random_uuid(),item_id uuid not null references catalog_items(id) on delete restrict,
 purchase_cost numeric not null check(purchase_cost>=0),effective_from timestamptz not null default now(),
 note text,created_by uuid references app_users(id),created_at timestamptz not null default now()
);
create index if not exists idx_purchase_cost_item_effective on purchase_cost_history(item_id,effective_from desc,created_at desc);
alter table purchase_cost_history enable row level security;
drop policy if exists purchase_cost_owner_read on purchase_cost_history;
create policy purchase_cost_owner_read on purchase_cost_history for select using(is_role('owner'));
revoke insert,update,delete on purchase_cost_history from anon,authenticated;

create or replace function set_purchase_cost(p_item uuid,p_cost numeric,p_effective_from timestamptz default now(),p_note text default null) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
 if p_cost is null or p_cost<0 or not exists(select 1 from catalog_items where id=p_item) then raise exception 'Invalid purchase cost';end if;
 insert into purchase_cost_history(item_id,purchase_cost,effective_from,note,created_by) values(p_item,p_cost,coalesce(p_effective_from,now()),nullif(trim(p_note),''),a.id) returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_COST_RECORDED','catalog_item',p_item::text,jsonb_build_object('cost_history_id',v,'effective_from',coalesce(p_effective_from,now())));
 return v;
end;$$;
revoke all on function set_purchase_cost(uuid,numeric,timestamptz,text) from public,anon;grant execute on function set_purchase_cost(uuid,numeric,timestamptz,text) to authenticated;

create or replace function get_profit_summary(p_from timestamptz default null,p_to timestamptz default null) returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;rev numeric:=0;cost numeric:=0;missing bigint:=0;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid report date range';end if;
 with delivered as(
  select e.id,e.final_payable,e.created_at from sales_documents e join dispatches d on d.estimate_id=e.id where e.doc_type='estimate' and d.status='delivered' and(p_from is null or e.created_at>=p_from) and(p_to is null or e.created_at<p_to)
 ),line_cost as(
  select l.id,l.qty,(select p.purchase_cost from purchase_cost_history p where p.item_id=l.item_id and p.effective_from<=e.created_at order by p.effective_from desc,p.created_at desc limit 1) unit_cost
  from sales_document_lines l join delivered e on e.id=l.document_id
 )
 select coalesce((select sum(final_payable) from delivered),0),coalesce((select sum(qty*unit_cost) from line_cost where unit_cost is not null),0),coalesce((select count(*) from line_cost where unit_cost is null),0) into rev,cost,missing;
 return jsonb_build_object('revenue',rev,'cost',cost,'profit',case when missing=0 then rev-cost else null end,'margin_percent',case when missing=0 and rev>0 then round(((rev-cost)*100/rev)::numeric,2) else null end,'missing_cost_lines',missing,'complete',missing=0,'from',p_from,'to',p_to);
end;$$;
revoke all on function get_profit_summary(timestamptz,timestamptz) from public,anon;grant execute on function get_profit_summary(timestamptz,timestamptz) to authenticated;
