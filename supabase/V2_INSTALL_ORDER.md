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
18. `v2-delivery-rpc.sql`

## Schemes and rewards
19. `v2-scheme-progress.sql`
20. `v2-reward-lots.sql`
21. `v2-reward-reconciliation.sql`
22. `v2-rewards-rpcs.sql`
23. `v2-scheme-reward-credit.sql`
24. `v2-referrals.sql`

### Detailed report rule
`v2-report-detail-rpc.sql` provides database-authorized detail rows for Sales, Order-vs-Estimate, Outstanding/Aging, Dealer, Product, Inventory, Reorder, Dispatch, Scheme, Missing Range Opportunity and Audit reports. Store Keeper is limited to Inventory/Reorder/Dispatch and never receives sales, payment, purchase-cost or profit rows through this RPC. Audit output is capped to the latest 1000 matching rows per request.

### Purchase-cost / profit rule
`v2-purchase-cost-history.sql` stores append-only effective-dated purchase costs through an Owner-only RPC and exposes Owner-only profit summary. Profit remains unavailable when any delivered sales line has no applicable historical purchase cost; the system must not invent a cost or misleading profit.

### Payment retry rule
`v2-payment-idempotency.sql` supersedes the base `record_payment` RPC and requires a unique client request key. Retrying the exact same estimate/status/amount with the same key returns the existing payment; reusing a key for different payment data raises a conflict. New clients must send `p_request_key`.

### Reorder duplicate rule
`v2-reorder-guard.sql` supersedes `submit_reorder` and enforces at most one active (`submitted`/`ordered`) reorder per catalog item. On an existing database it intentionally aborts if duplicate active requests already exist so they can be reviewed instead of silently merged or deleted.

### Reward dependency rule
The `reward_ledger` table is created by `v2-extended-schema.sql`; there is no separate reward-ledger migration in this V2 branch. `v2-reward-lots.sql` MUST run after `v2-extended-schema.sql` and before any SQL that creates or spends lot-based reward points. Scheme and referral reward credits depend on `reward_point_lots`.

### Existing database reward cutover
`v2-reward-lots.sql` deliberately auto-backfills only dealers whose reward history has no prior redeem/expire entries. `v2-reward-reconciliation.sql` is read-only/guarded migration support: run `reward_reconciliation_status()` as Owner/Admin and resolve every row that is not `LOT_ACCOUNTING_READY`. Then run `assert_reward_lot_migration_ready()` before enabling lot-based rewards in production. The guard intentionally refuses to invent historical FIFO allocations.

### Existing database migration warning
Do not blindly rerun the full list on an existing database. Apply only the new/changed migrations in dependency order. Historical dealers with redemption/expiry activity require reconciliation before lot-based balances are enabled for production use.

## Mandatory staging release gate
GitHub/Vite build success does **not** validate PostgreSQL migrations or RPC behavior. Before V2 can be called production-ready, run the applicable SQL above against a separate staging Supabase project and complete all of these checks:

1. Sign in with test users for Owner, Admin, Salesman, Accountant, Store Keeper and Dealer; confirm each role can open only its allowed modules and database rows.
2. Complete one test sale end-to-end: Dealer Query → Quotation → Dealer Accept → Sales Order → Estimate → Payment → Ready for Dispatch → Delivered.
3. Confirm inventory does **not** deduct at Estimate, Picked or Packed; it deducts exactly once only after valid payment + delivery. Retry delivery and confirm stock cannot deduct twice.
4. Retry the same payment request key and confirm it returns the same payment; reuse that key with different data and confirm it is rejected.
5. Create/receive a reorder and confirm duplicate active reorder protection and inventory movement history.
6. Test Machine → Spare Parts mapping and confirm internal compatibility stays Owner/Admin-only unless a mapping is explicitly dealer-visible.
7. Run summary/detail reports as each allowed role and confirm Store Keeper never receives financial/rate/profit data; Profit/Purchase Cost remain Owner-only.
8. Run `reward_reconciliation_status()` and `assert_reward_lot_migration_ready()` before enabling lot rewards on migrated production data; test FIFO redeem and expiry on staging.
9. Verify notifications/messages, dealer approval, inactive-user blocking and audit entries for critical actions.
10. Confirm no service-role key or other privileged secret is present in browser code, GitHub source or public deployment output.

Record any staging failure before production migration. Do not point the live domain at V2 and do not replace/merge the existing live version until this gate passes and the Owner explicitly approves cutover.

### Production safety
- Never place a Supabase service-role key in browser code or GitHub source.
- Keep RLS enabled; privileged mutations must use the authorized RPC path.
- Verify stock deduction remains payment-received + delivery-only and idempotent before production launch.
- Test the SQL against a staging Supabase project before production migration.
