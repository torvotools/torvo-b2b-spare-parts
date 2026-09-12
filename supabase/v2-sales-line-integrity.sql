-- TORVO V2 Sales document line integrity guard.
-- Run after v2-sales-revision-rpcs.sql.
-- A Sales/Estimate document must never contain the same catalog item twice.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

-- Fail loudly on an existing database if historical duplicate lines exist.
-- Do not silently merge/delete financial document history.
do $$
begin
  if exists (
    select 1
    from sales_document_lines
    group by document_id,item_id
    having count(*)>1
  ) then
    raise exception 'Duplicate sales_document_lines exist. Review historical documents before installing TORVO sales line integrity guard.';
  end if;
end $$;

create unique index if not exists uq_sales_document_lines_document_item
  on sales_document_lines(document_id,item_id);

comment on index uq_sales_document_lines_document_item is
  'TORVO V2: one catalog item per sales document. Duplicate item submissions are rejected at database level.';
