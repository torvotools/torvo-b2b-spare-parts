-- TORVO V2 PURCHASE ENTRY / STOCK RECEIPT STAGING SECURITY CHECKLIST
-- TEST ONLY IN DEDICATED STAGING. Do not run blindly in production.
-- Runtime evidence is required; source presence alone is not a pass.

-- 1) OBJECT / CONSTRAINT CHECKS
select to_regclass('public.purchase_stock_receipts') as purchase_stock_receipts_table;
select indexname,indexdef from pg_indexes where schemaname='public' and tablename in('purchase_headers','purchase_lines','purchase_stock_receipts') order by tablename,indexname;

-- EXPECT:
-- uq_purchase_supplier_invoice exists.
-- uq_purchase_lines_purchase_item exists.
-- purchase_stock_receipts has PK purchase_id and UNIQUE request_key.

-- 2) RLS / DIRECT CLIENT WRITE CHECKS
select c.relname,c.relrowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname='purchase_stock_receipts';

select grantee,table_name,privilege_type
from information_schema.role_table_grants
where table_schema='public'
  and table_name in('purchase_stock_receipts','inventory','inventory_movements')
  and grantee in('anon','authenticated')
order by table_name,grantee,privilege_type;

-- EXPECT: purchase_stock_receipts RLS=true.
-- EXPECT: no INSERT/UPDATE/DELETE for anon/authenticated on receipt ledger, inventory, inventory_movements.

-- 3) FUNCTION EXECUTE SURFACE
select routine_name,routine_type
from information_schema.routines
where routine_schema='public'
  and routine_name in('create_purchase_entry','receive_purchase_stock','reverse_purchase_entry')
order by routine_name;

-- Test as real sessions:
-- OWNER: create/receive/reverse allowed.
-- ADMIN: create/receive/reverse allowed.
-- SALESMAN/ACCOUNTANT/STORE KEEPER/DEALER: denied for these Purchase financial/source operations.
-- ANON: denied.

-- 4) DUPLICATE SUPPLIER + INVOICE
-- Create Purchase Entry A with Supplier S + Invoice INV-1.
-- Replay same supplier with invoice variants such as ' inv-1 ' / 'INV-1'.
-- EXPECT: second creation fails and no second header/stock movement exists.

-- 5) DUPLICATE ITEM LINE
-- Attempt one Purchase Entry whose JSON contains the same item_id twice.
-- EXPECT: creation fails atomically; no header, line, receipt or inventory movement remains.

-- 6) CREATE DOES NOT RECEIVE STOCK
-- Record inventory.current_qty for an item.
-- Call create_purchase_entry(...).
-- EXPECT: Purchase header/lines exist but current_qty is unchanged.
-- EXPECT: no purchase_stock_receipts row and no PURCHASE STOCK RECEIVED movement yet.

-- 7) EXACTLY-ONCE RECEIVE
-- Call receive_purchase_stock(P,'REQ-UNIQUE-1').
-- EXPECT: stock increases exactly by Purchase line qty, one receipt ledger row, one movement per aggregated item.
-- Replay receive_purchase_stock(P,'REQ-UNIQUE-1').
-- EXPECT: successful idempotent no-op; stock and movement count unchanged.
-- Replay same Purchase P with a different request key.
-- EXPECT: no second stock addition.
-- Reuse 'REQ-UNIQUE-1' for another Purchase.
-- EXPECT: rejected.

-- 8) REVERSAL
-- Reverse received Purchase P with explicit reason.
-- EXPECT: stock decreases exactly by received qty; receipt row gets reversed_at/by/reason; audited PURCHASE_REVERSED.
-- Replay reversal.
-- EXPECT: rejected/no second deduction.
-- Attempt reverse before stock receipt.
-- EXPECT: rejected.
-- Reduce current stock below the Purchase qty through legitimate downstream staging flow, then attempt reversal.
-- EXPECT: reversal rejected rather than making stock negative.

-- 9) RE-RECEIVE AFTER REVERSAL
-- Attempt receive_purchase_stock(P, new_request_key) after reversal.
-- EXPECT: rejected; a reversed Purchase cannot silently re-enter stock.

-- 10) ATOMICITY / FAILURE INJECTION
-- Include one invalid/inactive item among otherwise valid lines.
-- EXPECT: whole create transaction rolls back.
-- Force one receive failure (e.g. controlled staging constraint failure).
-- EXPECT: no partial stock receipt or partial receipt ledger row.

-- 11) PURCHASE RATE PRIVACY
-- As OWNER: get_purchase_entries/get_purchase_entry_lines may return allowed purchase values.
-- As ADMIN: verify confidential purchase-rate/amount fields follow current Owner-only policy.
-- As DEALER/SALESMAN/STORE KEEPER: direct table/RPC access must not expose purchase cost/profit/source financial data.

-- 12) INVENTORY MOVEMENT RECONCILIATION
-- For each tested Purchase:
-- SUM(receipt movements) + SUM(reversal movements) must reconcile to net stock effect.
-- No legacy create_purchase_entry definition may remain installed after v2-purchase-entry-integrity.sql.

-- RELEASE RESULT (fill manually in staging evidence):
-- MIGRATION COMMIT: ____________________
-- TEST DATE: ___________________________
-- TESTER: ______________________________
-- OWNER: PASS / FAIL
-- ADMIN: PASS / FAIL
-- OTHER ROLE DENIALS: PASS / FAIL
-- DUPLICATE INVOICE: PASS / FAIL
-- DUPLICATE LINE: PASS / FAIL
-- CREATE-NO-STOCK: PASS / FAIL
-- EXACTLY-ONCE RECEIVE: PASS / FAIL
-- REVERSAL: PASS / FAIL
-- PRIVACY: PASS / FAIL
-- ATOMICITY: PASS / FAIL
-- OVERALL: PASS / FAIL
