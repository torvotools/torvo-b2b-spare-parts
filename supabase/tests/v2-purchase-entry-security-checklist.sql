-- TORVO V2 PURCHASE ENTRY / STOCK RECEIPT STAGING SECURITY CHECKLIST
-- TEST ONLY IN DEDICATED STAGING. Source presence alone is NOT runtime verification.
select to_regclass('public.purchase_stock_receipts');
select indexname,indexdef from pg_indexes where schemaname='public' and tablename in('purchase_headers','purchase_lines','purchase_stock_receipts') order by tablename,indexname;
select c.relname,c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='purchase_stock_receipts';
select grantee,table_name,privilege_type from information_schema.role_table_grants where table_schema='public' and table_name in('purchase_stock_receipts','inventory','inventory_movements') and grantee in('anon','authenticated') and privilege_type in('INSERT','UPDATE','DELETE');
-- EXPECT zero direct browser write grants.

-- ROLE: OWNER/ADMIN create+receive allowed. SALESMAN/ACCOUNTANT/STORE KEEPER/DEALER/ANON denied for source purchase-cost/stock receipt operations.
-- DUPLICATE INVOICE: Supplier S + INV-1 then same supplier + case/space variant must fail atomically.
-- DUPLICATE ITEM: same item_id twice in JSON must fail atomically.
-- CREATE: create_purchase_entry alone must NOT change inventory or create receipt/movement.

-- EXACTLY-ONCE REQUEST-KEY MATRIX (mandatory):
-- A) receive_purchase_stock(P1,'KEY-1') -> succeeds once; exact stock/movement delta.
-- B) replay P1+'KEY-1' -> idempotent success; NO additional stock/movement.
-- C) replay same P1 with DIFFERENT unused 'KEY-2' -> MUST REJECT; NO stock/movement change.
-- D) reuse 'KEY-1' with different P2 -> MUST REJECT; NO stock/movement change.
-- E) reverse P1 legitimately, then receive P1 with original OR any new key -> MUST REJECT.
-- This distinguishes legitimate network retry from conflicting second receive intent.

-- REVERSAL: received Purchase reverses once only; before-receipt reversal rejected; insufficient current stock rejects entire reversal; active Purchase Requirement links must be reversed first under later integrity layer.
-- ATOMICITY: force controlled failure during receive and prove no partial item receipt/movement survives.
-- PRIVACY: OWNER may see purchase-rate history; ADMIN/other roles must follow Owner-only confidential purchase cost policy.
-- RECONCILIATION: canonical inventory_movements net change must reconcile current stock. No later migration may reinstall an older create/receive function.

-- RELEASE EVIDENCE
-- MIGRATION COMMIT: __________ TEST DATE: __________ TESTER: __________
-- ROLE SECURITY: PASS/FAIL | DUPLICATES: PASS/FAIL | CREATE-NO-STOCK: PASS/FAIL
-- SAME-KEY REPLAY: PASS/FAIL | DIFFERENT-KEY SAME-PURCHASE REJECT: PASS/FAIL
-- SAME-KEY DIFFERENT-PURCHASE REJECT: PASS/FAIL | REVERSED RE-RECEIVE REJECT: PASS/FAIL
-- REVERSAL: PASS/FAIL | PRIVACY: PASS/FAIL | ATOMICITY: PASS/FAIL | OVERALL: PASS/FAIL
