-- TORVO V2 Purchase Requirement staging security/integrity checklist
-- MANUAL/STAGING ONLY. Do not run destructive setup against production.
-- Install through v2-purchase-requirement-receipt-integrity.sql before running receipt-linkage checks.

-- 1. OWNER / ADMIN / ACCOUNTANT / STORE KEEPER
-- select * from get_purchase_requirement_dealers();
-- EXPECT: approved Dealers only; columns limited to id, dealer_code, shop_name.

-- 2. SALESMAN
-- select * from get_purchase_requirement_dealers();
-- EXPECT: approved Dealers mapped to the current Salesman only.
-- EXPECT: no rate_group, mobile, address, financial or private Dealer fields.

-- 3. UNAUTHORIZED / INACTIVE STAFF
-- select * from get_purchase_requirement_dealers();
-- EXPECT: exception 'Not authorized'.

-- 4. EXISTING ITEM REQUIREMENT WITH UNAPPROVED DEALER
-- select submit_purchase_requirement(<active_item>,1,'dealer_demand','test',<unapproved_dealer>);
-- EXPECT: exception 'Approved Dealer required'. No requirement/dealer-demand row should be created.

-- 5. NEW ITEM REQUIREMENT WITH UNAPPROVED DEALER
-- select submit_new_item_requirement(1,'TEST BRAND',null,null,'TEST ITEM',null,null,null,null,'test',<unapproved_dealer>);
-- EXPECT: exception 'Approved Dealer required'. No requirement/new-item row should be created.

-- 6. SALESMAN USING AN APPROVED BUT UNMAPPED DEALER
-- Run either submit function as that Salesman.
-- EXPECT: exception 'Dealer is not mapped to this salesman'.

-- 7. LARGE CATALOG FINDER
-- select * from search_purchase_requirement_items(null,null,null,100);
-- EXPECT: zero rows (no full-catalog dump on empty search).
-- select * from search_purchase_requirement_items('801',null,null,100);
-- EXPECT: <=100 active identity-only matches, with exact/prefix item/OEM matches ranked first.

-- 8. SAVED PURCHASE ENTRY IS NOT YET RECEIVED STOCK
-- Create a Purchase Entry containing the requirement item, but DO NOT call receive_purchase_stock().
-- select * from get_requirement_purchase_candidates(<requirement_id>,100);
-- EXPECT: that Purchase Entry is absent.
-- select link_purchase_to_requirement(<requirement_id>,<saved_purchase_id>,1,'STAGING TEST');
-- EXPECT: exception 'Purchase stock has not been received or was reversed'.
-- EXPECT: purchased_qty, Dealer fulfilled_qty and inventory remain unchanged by the failed link.

-- 9. RECEIVED PURCHASE STOCK CAN FULFIL REQUIREMENT WITHOUT CHANGING INVENTORY AGAIN
-- Capture inventory.current_qty for the item immediately after receive_purchase_stock(<purchase_id>,<unique_key>).
-- select link_purchase_to_requirement(<requirement_id>,<purchase_id>,1,'STAGING TEST');
-- EXPECT: succeeds when approved/remaining quantity permits.
-- EXPECT: requirement purchased_qty and Dealer allocation advance by linked quantity.
-- EXPECT: inventory.current_qty is EXACTLY unchanged by requirement linking.

-- 10. DUPLICATE ACTIVE REQUIREMENT/PURCHASE LINK IS BLOCKED
-- Repeat link_purchase_to_requirement() for the same requirement + Purchase while the first link is active.
-- EXPECT: rejected; no second active link and no duplicate Dealer allocation.
-- Also verify uq_purchase_requirement_active_purchase_link exists and prevents concurrent duplicate active rows.

-- 11. PURCHASE REVERSAL IS BLOCKED WHILE REQUIREMENT LINK IS ACTIVE
-- select reverse_purchase_entry(<purchase_id>,'STAGING ACTIVE LINK TEST');
-- EXPECT: exception 'Reverse active Purchase Requirement links before reversing Purchase stock'.
-- EXPECT: inventory and purchase_stock_receipts.reversed_at remain unchanged.

-- 12. SAFE REVERSAL ORDER
-- select reverse_purchase_requirement_link(<active_link_id>,'STAGING ROLLBACK');
-- EXPECT: requirement purchased_qty and exact Dealer allocation are rolled back/audited; inventory is unchanged.
-- Then select reverse_purchase_entry(<purchase_id>,'STAGING ROLLBACK');
-- EXPECT: succeeds only if current stock can safely cover the received Purchase quantity.
-- EXPECT: Purchase stock is reversed once and audited.

-- 13. REVERSED PURCHASE IS NOT A FULFILMENT CANDIDATE
-- select * from get_requirement_purchase_candidates(<requirement_id>,100);
-- EXPECT: reversed Purchase is absent.
-- select link_purchase_to_requirement(<requirement_id>,<reversed_purchase_id>,1,'STAGING TEST');
-- EXPECT: exception 'Purchase stock has not been received or was reversed'.

-- 14. ROLE BOUNDARY
-- As SALESMAN / ACCOUNTANT / STORE KEEPER / DEALER, call get_requirement_purchase_candidates() and link_purchase_to_requirement().
-- EXPECT: Owner/Admin required.
-- Direct browser writes to purchase_stock_receipts, inventory and inventory_movements must remain denied.

-- PASS GATE: all applicable checks above must pass with real staging sessions/data before Purchase Requirements are production-ready.
-- GitHub source presence alone is NOT runtime verification.
