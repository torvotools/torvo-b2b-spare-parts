-- Dealer financial privacy hardening.
-- Dealers do not receive direct payment/accounting table reads. Payment state is an internal TORVO concern.
-- Dealer operational delivery visibility remains separately scoped through dispatch records for the Dealer's own document.

drop policy if exists payments_read on payments;
create policy payments_read on payments for select to authenticated
using(current_app_role() in('owner','admin','accountant'));

-- Reassert own-document-only dispatch visibility. This contains no payment amount/outstanding data.
drop policy if exists dispatches_read on dispatches;
create policy dispatches_read on dispatches for select to authenticated
using(
 current_app_role() in('owner','admin','salesman','store_keeper')
 or exists(
  select 1 from sales_documents d
  where d.id=estimate_id and d.dealer_id=current_dealer_id()
 )
);

comment on policy payments_read on payments is 'Internal financial/payment rows: Owner, Admin and Accountant only; Dealer Portal must not expose accounting/outstanding data.';
