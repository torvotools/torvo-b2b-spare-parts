-- TORVO V2 SALES / DELIVERY INTEGRITY STAGING CHECKLIST
-- This is a verification checklist, not proof of runtime success.
-- Run only after the authoritative V2 staging install order compiles.

-- 1) OBJECT / CONSTRAINT PRESENCE
select to_regclass('public.additional_purchase_order_links') as additional_po_links,
       to_regclass('public.inventory') as inventory,
       to_regclass('public.inventory_movements') as canonical_inventory_movements,
       to_regclass('public.delivery_stock_finalizations') as delivery_finalizations;

select indexname from pg_indexes
where schemaname='public' and indexname in(
 'idx_sales_document_lines_document_item_uq',
 'idx_payments_request_key_uq'
) order by indexname;

-- 2) SECURITY-DEFINER RPC PRESENCE
select p.proname, p.prosecdef
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
 'torvo_apply_sales_order_revision',
 'dealer_confirm_sales_order_revision',
 'convert_sales_order_to_estimate',
 'request_additional_purchase_order',
 'decide_additional_purchase_order',
 'get_dealer_order_history_30d',
 'record_payment',
 'finalize_actual_delivery',
 'deliver_estimate'
) order by p.proname;

-- 3) DIRECT WRITE GRANTS MUST NOT BYPASS STOCK FINALIZATION
select table_name,privilege_type,grantee
from information_schema.role_table_grants
where table_schema='public'
  and table_name in('inventory','inventory_movements','delivery_stock_finalizations','additional_purchase_order_links')
  and grantee in('anon','authenticated')
  and privilege_type in('INSERT','UPDATE','DELETE')
order by table_name,grantee,privilege_type;
-- Expected: no bypassing write grants. Investigate every returned row.

-- 4) VERIFY THERE IS NO PARALLEL SALES STOCK LEDGER
-- inventory_movements is the canonical Purchase + Delivery stock movement ledger.
select to_regclass('public.stock_movements') as legacy_parallel_stock_movements;
-- Expected for the final V2 design: NULL, unless an older staging database still has a legacy table.
-- If non-NULL, inspect it and migrate/remove the obsolete write path before release.

-- 5) RUNTIME ROLE TESTS (perform with real staging sessions)
-- DEALER: can confirm only own latest exact Sales Order revision.
-- DEALER: stale revision confirmation fails after TORVO revision.
-- DEALER: cannot read internal payment/outstanding/purchase-cost data.
-- DEALER: 30-day history returns only own Sales Order/Estimate rows.
-- OWNER/ADMIN/SALESMAN: revision invalidates prior DEALER OK.
-- ACCOUNTANT/OWNER/ADMIN: Estimate conversion fails without latest exact DEALER OK.
-- Estimate conversion locks original Sales Order against direct revision.
-- ADD MORE ITEMS creates a separate linked Sales Order; original order/Estimate row+lines remain unchanged.
-- Additional order remains pending until OWNER/ADMIN approval.

-- 6) DUPLICATE-LINE TEST
-- Attempt two sales_document_lines with same (document_id,item_id).
-- Expected: unique constraint failure; update quantity on existing line instead.

-- 7) PAYMENT IDEMPOTENCY TEST
-- Call record_payment twice with identical estimate/status/amount/request_key.
-- Expected: same payment id; payment total changes only once.
-- Reuse same request_key with different amount/estimate/status.
-- Expected: rejection.

-- 8) MARG BILL SALE POSTING / STOCK EXACTLY-ONCE TEST
-- Owner rule: entering/saving the Marg Bill number is the final Sale code. There is no separate payment or approval gate.
-- Capture inventory quantities and inventory_movements count before posting the Marg Bill.
-- Attempt approve_marg_bill_sale with insufficient stock: entire transaction must fail; no item may be partially deducted and no Dispatch may be created.
-- Post one valid unique Marg Bill number for an eligible Estimate.
-- Expected in the SAME transaction: Sale posted, each item deducted exactly ordered quantity,
-- one negative MARG BILL APPROVED SALE inventory_movements row/item, Dispatch created at PICK_LIST, Estimate marked SALE_POSTED.
-- Replay the same Estimate or Marg Bill number: expected rejection and no further stock movement.

-- 9) DELIVERY AFTER MARG BILL POSTING
-- Advance the Dispatch through its authorized stages to READY_FOR_DISPATCH, then call finalize_actual_delivery.
-- Expected: delivery closes Dispatch/Estimate only; stock is NOT deducted again because stock already moved at Marg Bill Sale posting.
-- Calling delivery finalization again must not create another stock deduction.
-- Legacy non-Marg compatibility paths, if retained for historical rows, must never double-deduct a Marg-posted Sale.

-- 10) PURCHASE -> SALE -> DELIVERY LEDGER CONTINUITY
-- For one staging item:
-- A) RECEIVE PURCHASE STOCK once and verify positive inventory_movements entry.
-- B) Post a valid Marg Bill and verify the negative sale inventory movement.
-- C) Complete delivery and verify there is no second negative stock movement.
-- D) Reconcile current inventory quantity to opening + all canonical inventory_movements changes.
-- Expected: no hidden/parallel stock mutation.

-- 11) AUDIT TEST
-- Confirm SALES_ORDER_REVISED, DEALER_OK, ESTIMATE_CREATED,
-- ADDITIONAL_PURCHASE_ORDER_REQUESTED/APPROVED/REJECTED,
-- MARG_BILL_SALE_POSTED and ACTUAL_DELIVERY_FINALIZED events are present as applicable.

-- 12) RELEASE RULE
-- Do not mark payment/delivery/stock flow runtime verified until all applicable tests above pass
-- against the same staging migration set and code commit, with non-secret evidence retained.
