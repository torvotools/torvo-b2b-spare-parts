-- TORVO V2 — Salesman mapped-dealer sales read boundary
-- Canonical rule: normal Salesman may read only active mapped Dealers.
-- Explicit Master Salesman grant may read all approved Dealer sales.
-- Owner/Admin/Accountant and Dealer-own visibility remain unchanged.

drop policy if exists sales_documents_read on public.sales_documents;
create policy sales_documents_read
on public.sales_documents
for select
to authenticated
using (
  current_app_role() = any (array['owner'::text,'admin'::text,'accountant'::text])
  or dealer_id = current_dealer_id()
  or (
    current_app_role() = 'salesman'
    and (
      is_master_salesman()
      or exists (
        select 1
        from public.salesman_dealer_mappings sdm
        join public.app_users au on au.id = sdm.salesman_id
        where au.auth_user_id = auth.uid()
          and au.active = true
          and au.role = 'salesman'
          and sdm.active = true
          and sdm.dealer_id = sales_documents.dealer_id
      )
    )
  )
);

drop policy if exists sales_lines_read on public.sales_document_lines;
create policy sales_lines_read
on public.sales_document_lines
for select
to authenticated
using (
  exists (
    select 1
    from public.sales_documents d
    where d.id = sales_document_lines.document_id
  )
);

comment on policy sales_documents_read on public.sales_documents is
'TORVO V2 canonical sales visibility: Owner/Admin/Accountant all; Dealer own; normal Salesman active mapped Dealers only; explicit Master Salesman all approved Dealer scope via server grant.';
comment on policy sales_lines_read on public.sales_document_lines is
'Lines inherit the canonical visible parent sales_document boundary.';
