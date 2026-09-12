-- TORVO V2 Purchase Requirement staging security checklist
-- MANUAL/STAGING ONLY. Do not run destructive setup against production.
-- Purpose: verify role-safe Dealer selection and server-side Dealer validation after installing
-- v2-purchase-requirement-rpcs.sql and v2-purchase-requirement-item-link.sql.

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

-- PASS GATE: all seven checks above must pass before Purchase Requirements are production-ready.
