-- TORVO V2 EXPENSE + PROFIT INTEGRITY
-- Install after delivered Sales, Purchase Cost History and Sales Return foundations.
-- Financial tables are private; profit is OWNER-only and never invents missing historical cost.

create table if not exists public.business_expenses(
 id uuid primary key default gen_random_uuid(),
 expense_date date not null,
 category text not null,
 description text not null,
 amount numeric not null check(amount>0),
 request_key text not null unique,
 status text not null default 'active' check(status in('active','reversed')),
 created_by uuid not null references public.app_users(id),
 created_at timestamptz not null default now(),
 reversed_by uuid references public.app_users(id),
 reversed_at timestamptz,
 reverse_reason text
);
create index if not exists idx_business_expenses_date on public.business_expenses(expense_date desc);
alter table public.business_expenses enable row level security;
revoke all on public.business_expenses from public,anon,authenticated;

create or replace function public.record_business_expense(p_date date,p_category text,p_description text,p_amount numeric,p_request_key text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;e business_expenses%rowtype;eid uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Financial role required';end if;
 if p_date is null or p_date>current_date or nullif(upper(trim(p_category)),'') is null or nullif(upper(trim(p_description)),'') is null or p_amount is null or p_amount<=0 or nullif(trim(p_request_key),'') is null then raise exception 'Valid expense required';end if;
 select * into e from business_expenses where request_key=trim(p_request_key);
 if found then
  if e.expense_date=p_date and e.category=upper(trim(p_category)) and e.description=upper(trim(p_description)) and e.amount=p_amount then return e.id;end if;
  raise exception 'Expense request key already used';
 end if;
 insert into business_expenses(expense_date,category,description,amount,request_key,created_by) values(p_date,upper(trim(p_category)),upper(trim(p_description)),p_amount,trim(p_request_key),a.id) returning id into eid;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'EXPENSE_RECORDED','business_expense',eid::text,jsonb_build_object('expense_date',p_date,'category',upper(trim(p_category)),'amount',p_amount,'request_key',trim(p_request_key)));
 return eid;
end;$$;

create or replace function public.reverse_business_expense(p_expense uuid,p_reason text)
returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;e business_expenses%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;
 if nullif(upper(trim(p_reason)),'') is null then raise exception 'Reversal reason required';end if;
 select * into e from business_expenses where id=p_expense for update;
 if not found then raise exception 'Expense not found';end if;
 if e.status='reversed' then raise exception 'Expense already reversed';end if;
 update business_expenses set status='reversed',reversed_by=a.id,reversed_at=now(),reverse_reason=upper(trim(p_reason)) where id=e.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'EXPENSE_REVERSED','business_expense',e.id::text,jsonb_build_object('reason',upper(trim(p_reason)),'amount',e.amount));
end;$$;

create or replace function public.get_business_expenses(p_from timestamptz default null,p_to timestamptz default null)
returns table(id uuid,expense_date date,category text,description text,amount numeric,status text,created_at timestamptz,created_by_name text,reverse_reason text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Financial role required';end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid report date range';end if;
 return query select e.id,e.expense_date,e.category,e.description,e.amount,e.status,e.created_at,u.full_name,e.reverse_reason from business_expenses e left join app_users u on u.id=e.created_by where(p_from is null or e.expense_date>=p_from::date)and(p_to is null or e.expense_date<p_to::date) order by e.expense_date desc,e.created_at desc;
end;$$;

create or replace function public.get_profit_summary(p_from timestamptz default null,p_to timestamptz default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;rev numeric:=0;ret_rev numeric:=0;cost numeric:=0;ret_cost numeric:=0;exp numeric:=0;missing integer:=0;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner only profit report';end if;
 if p_from is not null and p_to is not null and p_from>=p_to then raise exception 'Invalid report date range';end if;
 with delivered as(
  select e.id,coalesce(f.finalized_at,e.created_at) delivered_at from sales_documents e join delivery_stock_finalizations f on f.estimate_id=e.id where e.doc_type='estimate' and(p_from is null or coalesce(f.finalized_at,e.created_at)>=p_from)and(p_to is null or coalesce(f.finalized_at,e.created_at)<p_to)
 ), lines as(
  select d.id estimate_id,d.delivered_at,l.item_id,l.qty,coalesce(l.amount,l.qty*coalesce(l.rate,0)) line_revenue,l.rate,
   (select pl.purchase_rate from purchase_lines pl join purchase_headers ph on ph.id=pl.purchase_id where pl.item_id=l.item_id and ph.invoice_date<=d.delivered_at::date order by ph.invoice_date desc,ph.created_at desc limit 1) unit_cost
  from delivered d join sales_document_lines l on l.document_id=d.id
 ), returned as(
  select r.source_id estimate_id,rl.item_id,sum(rl.qty)::numeric qty from transaction_returns r join transaction_return_lines rl on rl.return_id=r.id where r.return_type='sales_return' and r.status='completed' and(p_from is null or r.completed_at>=p_from)and(p_to is null or r.completed_at<p_to) group by r.source_id,rl.item_id
 )
 select coalesce(sum(l.line_revenue),0),coalesce(sum(coalesce(r.qty,0)*coalesce(l.rate,0)),0),coalesce(sum(l.qty*l.unit_cost) filter(where l.unit_cost is not null),0),coalesce(sum(coalesce(r.qty,0)*l.unit_cost) filter(where l.unit_cost is not null),0),count(*) filter(where l.unit_cost is null)
 into rev,ret_rev,cost,ret_cost,missing from lines l left join returned r on r.estimate_id=l.estimate_id and r.item_id=l.item_id;
 select coalesce(sum(amount),0) into exp from business_expenses where status='active' and(p_from is null or expense_date>=p_from::date)and(p_to is null or expense_date<p_to::date);
 return jsonb_build_object('complete',missing=0,'revenue',rev-ret_rev,'gross_cost',cost-ret_cost,'expenses',exp,'cost',(cost-ret_cost)+exp,'profit',(rev-ret_rev)-((cost-ret_cost)+exp),'margin_percent',case when rev-ret_rev>0 then round((((rev-ret_rev)-((cost-ret_cost)+exp))/(rev-ret_rev))*100,2) else 0 end,'sales_returns_revenue',ret_rev,'sales_returns_cost',ret_cost,'missing_cost_lines',missing);
end;$$;

revoke all on function public.record_business_expense(date,text,text,numeric,text),public.reverse_business_expense(uuid,text),public.get_business_expenses(timestamptz,timestamptz),public.get_profit_summary(timestamptz,timestamptz) from public,anon;
grant execute on function public.record_business_expense(date,text,text,numeric,text),public.reverse_business_expense(uuid,text),public.get_business_expenses(timestamptz,timestamptz),public.get_profit_summary(timestamptz,timestamptz) to authenticated;
