-- TORVO V2 Row Level Security foundation.
-- Server-side access control. UI permissions are never treated as a security boundary.

create or replace function current_app_user()
returns app_users
language sql
stable
security definer
set search_path=public
as $$
  select u from app_users u where u.auth_user_id=auth.uid() and u.active=true limit 1
$$;
revoke all on function current_app_user() from public, anon;
grant execute on function current_app_user() to authenticated;

create or replace function current_app_role()
returns text
language sql
stable
security definer
set search_path=public
as $$
  select role from app_users where auth_user_id=auth.uid() and active=true limit 1
$$;
revoke all on function current_app_role() from public, anon;
grant execute on function current_app_role() to authenticated;

create or replace function current_dealer_id()
returns uuid
language sql
stable
security definer
set search_path=public
as $$
  select d.id
  from dealers d
  join app_users u on u.mobile=d.mobile
  where u.auth_user_id=auth.uid()
    and u.active=true
    and u.role='dealer'
    and d.status='approved'
  limit 1
$$;
revoke all on function current_dealer_id() from public, anon;
grant execute on function current_dealer_id() to authenticated;

alter table app_users enable row level security;
alter table dealers enable row level security;
alter table catalog_items enable row level security;
alter table item_rates enable row level security;
alter table machine_spare_mapping enable row level security;
alter table inventory enable row level security;
alter table sales_documents enable row level security;
alter table sales_document_lines enable row level security;
alter table payments enable row level security;
alter table dispatches enable row level security;
alter table inventory_movements enable row level security;
alter table audit_log enable row level security;

-- App users: authenticated users can read their own profile. Owner/Admin can read staff profiles.
drop policy if exists app_users_read on app_users;
create policy app_users_read on app_users for select to authenticated
using (
  auth_user_id=auth.uid()
  or current_app_role() in ('owner','admin')
);

-- Dealers: internal staff can read dealer records; a dealer can read only the approved record tied to their login mobile.
drop policy if exists dealers_read on dealers;
create policy dealers_read on dealers for select to authenticated
using (
  current_app_role() in ('owner','admin','salesman','accountant','store_keeper')
  or id=current_dealer_id()
);

-- Catalog: active catalog is readable by authenticated users; write operations remain RPC/admin-service controlled.
drop policy if exists catalog_read on catalog_items;
create policy catalog_read on catalog_items for select to authenticated
using (active=true or current_app_role() in ('owner','admin'));

-- Dealer rates are visible only to staff or to the dealer's assigned rate group.
drop policy if exists item_rates_read on item_rates;
create policy item_rates_read on item_rates for select to authenticated
using (
  current_app_role() in ('owner','admin','salesman','accountant')
  or (
    current_app_role()='dealer'
    and rate_group=(select d.rate_group from dealers d where d.id=current_dealer_id())
  )
);

-- Compatibility remains private unless explicitly dealer/public visible.
drop policy if exists mapping_read on machine_spare_mapping;
create policy mapping_read on machine_spare_mapping for select to authenticated
using (
  current_app_role() in ('owner','admin','salesman')
  or (current_app_role()='dealer' and (dealer_visible=true or public_visible=true))
);

-- Inventory quantities are internal only.
drop policy if exists inventory_read on inventory;
create policy inventory_read on inventory for select to authenticated
using (current_app_role() in ('owner','admin','store_keeper'));

-- Sales documents: staff by responsibility; dealer only their own documents.
drop policy if exists sales_documents_read on sales_documents;
create policy sales_documents_read on sales_documents for select to authenticated
using (
  current_app_role() in ('owner','admin','salesman','accountant','store_keeper')
  or dealer_id=current_dealer_id()
);

drop policy if exists sales_lines_read on sales_document_lines;
create policy sales_lines_read on sales_document_lines for select to authenticated
using (
  exists (
    select 1 from sales_documents d
    where d.id=document_id
      and (current_app_role() in ('owner','admin','salesman','accountant','store_keeper') or d.dealer_id=current_dealer_id())
  )
);

-- Payments: financial staff can read all; dealer only payments for their own estimate.
drop policy if exists payments_read on payments;
create policy payments_read on payments for select to authenticated
using (
  current_app_role() in ('owner','admin','accountant')
  or exists (
    select 1 from sales_documents d
    where d.id=estimate_id and d.dealer_id=current_dealer_id()
  )
);

-- Dispatch status is available to operational staff and the owning dealer.
drop policy if exists dispatches_read on dispatches;
create policy dispatches_read on dispatches for select to authenticated
using (
  current_app_role() in ('owner','admin','salesman','store_keeper')
  or exists (
    select 1 from sales_documents d
    where d.id=estimate_id and d.dealer_id=current_dealer_id()
  )
);

-- Movement history and audit logs are internal.
drop policy if exists inventory_movements_read on inventory_movements;
create policy inventory_movements_read on inventory_movements for select to authenticated
using (current_app_role() in ('owner','admin','store_keeper'));

drop policy if exists audit_log_read on audit_log;
create policy audit_log_read on audit_log for select to authenticated
using (current_app_role() in ('owner','admin'));

-- No INSERT/UPDATE/DELETE policies are intentionally granted here.
-- Sensitive mutations must use reviewed SECURITY DEFINER RPCs that authenticate auth.uid(),
-- validate role/business rules, and write an audit record atomically.
