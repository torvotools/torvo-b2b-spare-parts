# TORVO V2 Supabase install order

This file is the authoritative dependency order for a fresh V2 database setup. Do not run the SQL files alphabetically.

## Core
1. `v2-schema.sql`
2. `v2-extended-schema.sql`
3. `v2-rls.sql`
4. `v2-admin-rpcs.sql`
5. `v2-business-rpcs.sql`
6. `v2-payment-idempotency.sql`
7. `v2-operations-rpcs.sql`
8. `v2-reorder-guard.sql`
9. `v2-purchase-cost-history.sql`
10. `v2-dashboard-rpc.sql`
11. `v2-report-summary-rpc.sql`
12. `v2-report-detail-rpc.sql`
13. `v2-feature-controls.sql`

## Dealer/catalog operations
14. `v2-dealer-link.sql`
15. `v2-dealer-machine-spares.sql`
16. `v2-message-direction.sql`
17. `v2-sales-catalog-rpcs.sql`
18. `v2-catalog-master-values.sql`
19. `v2-delivery-rpc.sql`

## Sales team / assisted field operations
20. `v2-sales-team-mapping.sql`
21. `v2-sales-team-rpcs.sql`
22. `v2-salesman-assisted-workflows.sql`
23. `v2-sales-revision-rpcs.sql`
24. `v2-purchase-requirements.sql`
25. `v2-purchase-requirement-rpcs.sql`

## Private suitable knowledge / Dealer fitment suggestions
26. `v2-knowledge-rewards.sql`

## Schemes and sales rewards
27. `v2-scheme-progress.sql`
28. `v2-reward-lots.sql`
29. `v2-reward-reconciliation.sql`
30. `v2-rewards-rpcs.sql`
31. `v2-scheme-reward-credit.sql`
32. `v2-referrals.sql`

### Sales revision / Dealer OK rule
`v2-sales-revision-rpcs.sql` is the controlled revision layer for the current sales flow. Owner/Admin/authorized Accountant may revise a Sales Order before Estimate; the server recalculates every revised line from the Dealer's current rate group and records revision history. A revision invalidates prior Dealer OK. Authorized staff can mark the exact latest revision as awaiting Dealer OK; a mapped Salesman is restricted to assigned Dealers. Dealer confirmation is accepted only for the Dealer's own Sales Order and exact current revision. Estimate must follow Dealer OK, and direct Sales Order revision is locked after an Estimate exists. WhatsApp delivery must never be recorded as sent until the provider is actually connected and verified.

### Sales team security rule
`v2-sales-team-rpcs.sql` is the authoritative mutation/scoped-read layer for Salesman area, Dealer ownership and target controls. Owner/Admin assign State → District → City areas, assign/transfer Dealers with audit, and set Monthly/Quarterly/Financial Year targets. Salesman Dealer reads must use the scoped RPC path and must not rely on UI filtering as the security boundary.

### Suitable knowledge privacy rule
`v2-knowledge-rewards.sql` now represents Dealer Fitment Suggestions / Suitable Knowledge, not a reward source. Dealer answers are private between Dealers and Dealer-facing challenge/history reads use scoped security-definer RPCs. Owner/Admin verify each suggestion as Correct, Partly Correct, Wrong/Rejected or Duplicate and may promote an eligible verified known-part fitment into TORVO's PRIVATE Suitable Master. Dealer fitment suggestions earn ZERO TORVO Points. TORVO Points are reserved for eligible actual sales/final paid billing under the separate sales reward system.

### Catalog / OEM rule
`v2-schema.sql` includes the optional `catalog_items.oem_code` field plus a normalized lookup index. `v2-sales-catalog-rpcs.sql` persists TORVO item code and Company/OEM Original Code separately. OEM code is searchable but is intentionally not globally unique because the same manufacturer reference may legitimately appear in more than one catalog context.

### Catalog master protection rule
`v2-catalog-master-values.sql` provides normalized UPPERCASE Brand/Category/Model masters. Normalization trims edges and collapses repeated whitespace before duplicate comparison, so values such as `BOSCH`, `bosch` and `  BOSCH  ` resolve to the same live master. Authenticated V2 users receive read access through RLS; Owner/Admin mutations use authorized RPCs. Rename is blocked while a master is referenced by catalog items, forcing reassignment first. Active/Inactive preserves history. Normal Delete requires confirmation code `1122`, is blocked while referenced, and moves an unused master to Trash instead of destroying it. Trash can be restored when restoration would not create a normalized live duplicate. Permanent Delete is a separate Owner/Admin operation, works only on an unused trashed value, and again requires `1122`. Treat the confirmation code as secondary operational protection, never as a substitute for authentication/RLS.

### Detailed report rule
`v2-report-detail-rpc.sql` provides database-authorized detail rows for Sales, Order-vs-Estimate, Outstanding/Aging, Dealer, Product, Inventory, Reorder, Dispatch, Scheme, Missing Range Opportunity and Audit reports. Store Keeper is limited to Inventory/Reorder/Dispatch and never receives sales, payment, purchase-cost or profit rows through this RPC. Audit output is capped to the latest 1000 matching rows per request.

### Purchase-cost / profit rule
`v2-purchase-cost-history.sql` stores append-only effective-dated purchase costs through an Owner-only RPC and exposes Owner-only profit summary. Profit remains unavailable when any delivered sales line has no applicable historical purchase cost; the system must not invent a cost or misleading profit.

### Payment retry rule
`v2-payment-idempotency.sql` supersedes the base `record_payment` RPC and requires a unique client request key. Retrying the exact same estimate/status/amount with the same key returns the existing payment; reusing a key for different payment data raises a conflict. New clients must send `p_request_key`.

### Reorder duplicate rule
`v2-reorder-guard.sql` supersedes `submit_reorder` and enforces at most one active (`submitted`/`ordered`) reorder per catalog item. On an existing database it intentionally aborts if duplicate active requests already exist so they can be reviewed instead of silently merged or deleted.

### Reward dependency rule
The `reward_ledger` table is created by `v2-extended-schema.sql`; there is no separate reward-ledger migration in this V2 branch. `v2-reward-lots.sql` MUST run after `v2-extended-schema.sql` and before any SQL that creates or spends lot-based sales reward points. Knowledge/Fitment Suggestions must never write to the reward ledger. Scheme and referral reward credits depend on `reward_point_lots`.

### Existing database reward cutover
`v2-reward-lots.sql` deliberately auto-backfills only dealers whose reward history has no prior redeem/expire entries. `v2-reward-reconciliation.sql` is read-only/guarded migration support: run `reward_reconciliation_status()` as Owner/Admin and resolve every row that is not `LOT_ACCOUNTING_READY`. Then run `assert_reward_lot_migration_ready()` before enabling lot-based rewards in production. The guard intentionally refuses to invent historical FIFO allocations.

### Existing database migration warning
Do not blindly rerun the full list on an existing database. Apply only the new/changed migrations in dependency order. Historical dealers with redemption/expiry activity require reconciliation before lot-based balances are enabled for production use.

## Mandatory staging release gate
GitHub/Vite build success does **not** validate PostgreSQL migrations or RPC behavior. Before V2 can be called production-ready, run the applicable SQL above against a separate staging Supabase project and complete all of these checks:

1. Sign in with test users for Owner, Admin, Salesman, Accountant, Store Keeper and Dealer; confirm each role can open only its allowed modules and database rows.
2. Complete one test sale end-to-end: Dealer Purchase Order → TORVO Sales Order → Admin/authorized revision → Send latest revision for Dealer OK → Dealer reviews exact items/qty/rates/total → Dealer OK → Estimate → Payment → Delivery. Confirm stale Dealer OK is rejected after any new revision and direct revision is blocked after Estimate.
3. Confirm inventory does **not** deduct at Estimate, Picked or Packed; it deducts exactly once only after valid payment + delivery. Retry delivery and confirm stock cannot deduct twice.
4. Retry the same payment request key and confirm it returns the same payment; reuse that key with different data and confirm it is rejected.
5. Create/receive a reorder and confirm duplicate active reorder protection and inventory movement history.
6. Test Machine → Spare Parts mapping and confirm internal compatibility stays Owner/Admin-only unless a mapping is explicitly dealer-visible.
7. Test Brand/Category/Model add and duplicate rejection with case/extra-space variants. Confirm usage count, used-master rename block and Active/Inactive. Confirm `1122` Delete moves an unused value to Trash, normal dropdowns exclude Trash, Restore works, duplicate-collision Restore is rejected, linked values cannot be trashed, and Permanent Delete works only from Trash after `1122` plus a fresh usage check.
8. Create and edit catalog items with both TORVO Item Code and Company/OEM Original Code; confirm both persist independently and Smart Search can find either code.
9. Run summary/detail reports as each allowed role and confirm Store Keeper never receives financial/rate/profit data; Profit/Purchase Cost remain Owner-only.
10. Run `reward_reconciliation_status()` and `assert_reward_lot_migration_ready()` before enabling lot rewards on migrated production data; test FIFO redeem and expiry on staging.
11. Verify Salesman cannot read another Salesman's Dealers; test Dealer transfer, area mapping and targets with audit history.
12. Using two Dealer accounts, verify Dealer A can never receive Dealer B's fitment suggestion/history. Verify Correct/Partly Correct/Wrong/Duplicate review and Private Suitable promotion. Confirm no fitment submission/review creates TORVO Points or reward-ledger rows.
13. Verify notifications/messages, dealer approval, inactive-user blocking and audit entries for critical actions.
14. Confirm no service-role key or other privileged secret is present in browser code, GitHub source or public deployment output.

Record any staging failure before production migration. Do not point the live domain at V2 and do not replace/merge the existing live version until this gate passes and the Owner explicitly approves cutover.

### Production safety
- Never place a Supabase service-role key in browser code or GitHub source.
- Keep RLS enabled; privileged mutations must use the authorized RPC path.
- Verify stock deduction remains payment-received + delivery-only and idempotent before production launch.
- Test the SQL against a staging Supabase project before production migration.
