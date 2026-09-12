-- TORVO V2 SALES / DELIVERY INTEGRITY STAGING CHECKLIST
-- This is a verification checklist, not proof of runtime success.
-- Run only after the authoritative V2 staging install order compiles.

-- 1) OBJECT / CONSTRAINT PRESENCE
select to_regclass('public.additional_purchase_order_links') as additional_po_links,
       to_regclass('public.stock_movements') as stock_movements,
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
 'finalize_actual_delivery'
) order by p.proname;

-- 3) DIRECT WRITE GRANTS MUST NOT BYPASS STOCK FINALIZATION
select table_name,privilege_type,grantee
from information_schema.role_table_grants
where table_schema='public'
  and table_name in('inventory','stock_movements','delivery_stock_finalizations','additional_purchase_order_links')
  and grantee in('anon','authenticated')
  and privilege_type in('INSERT','UPDATE','DELETE')
order by table_name,grantee,privilege_type;
-- Expected: no bypassing write grants. Investigate every returned row.

-- 4) RUNTIME ROLE TESTS (perform with real staging sessions)
-- DEALER: can confirm only own latest exact Sales Order revision.
-- DEALER: stale revision confirmation fails after TORVO revision.
-- DEALER: cannot read internal payment/outstanding/purchase-cost data.
-- DEALER: 30-day history returns only own Sales Order/Estimate rows.
-- OWNER/ADMIN/SALESMAN: revision invalidates prior DEALER OK.
-- ACCOUNTANT/OWNER/ADMIN: Estimate conversion fails without latest exact DEALER OK.
-- Estimate conversion locks original Sales Order against direct revision.
-- ADD MORE ITEMS creates a separate linked Sales Order; original order/Estimate row+lines remain byte-for-byte unchanged.
-- Additional order remains pending until OWNER/ADMIN approval.

-- 5) DUPLICATE-LINE TEST
-- Attempt two sales_document_lines with same (document_id,item_id).
-- Expected: unique constraint failure; update quantity on existing line instead.

-- 6) PAYMENT IDEMPOTENCY TEST
-- Call record_payment twice with identical estimate/status/amount/request_key.
-- Expected: same payment id; payment total changes only once.
-- Reuse same request_key with different amount/estimate/status.
-- Expected: rejection.

-- 7) DELIVERY / STOCK EXACTLY-ONCE TEST
-- Capture inventory quantities and stock_movements count before delivery.
-- Attempt finalize_actual_delivery before required payment: must fail and stock must be unchanged.
-- Attempt while dispatch status is PICKED/PACKED (or otherwise not ready): must fail and stock must be unchanged.
-- Attempt with insufficient stock: entire transaction must fail; no item may be partially deducted.
-- With full required payment + ready/dispatched state + sufficient stock, finalize delivery once.
-- Expected: each item deducted exactly ordered quantity, one delivery_out movement/item, finalization ledger row created, estimate/dispatch delivered.
-- Replay same request_key: expected no further stock movement.
-- Replay different request_key for same estimate: expected no further stock movement.

-- 8) AUDIT TEST
-- Confirm SALES_ORDER_REVISED, DEALER_OK, ESTIMATE_CREATED,
-- ADDITIONAL_PURCHASE_ORDER_REQUESTED/APPROVED/REJECTED,
-- INTERNAL_PAYMENT_NOTED and ACTUAL_DELIVERY_FINALIZED events are present as applicable.

-- 9) RELEASE RULE
-- Do not mark payment/delivery/stock flow runtime verified until all applicable tests above pass
-- against the same staging migration set and code commit, with non-secret evidence retained.
