# TORVO V2 Supabase install order

This file is the authoritative dependency order for a fresh V2 database setup. Do not run the SQL files alphabetically.

## Core
1. `v2-schema.sql`
2. `v2-extended-schema.sql`
3. `v2-rls.sql`
4. `v2-admin-rpcs.sql`
5. `v2-business-rpcs.sql`
6. `v2-operations-rpcs.sql`
7. `v2-dashboard-rpc.sql`
8. `v2-feature-controls.sql`

## Dealer/catalog operations
9. `v2-dealer-link.sql`
10. `v2-dealer-machine-spares.sql`
11. `v2-message-direction.sql`
12. `v2-sales-catalog-rpcs.sql`
13. `v2-delivery-rpc.sql`

## Schemes and rewards
14. `v2-scheme-progress.sql`
15. `v2-reward-lots.sql`
16. `v2-rewards-rpcs.sql`
17. `v2-scheme-reward-credit.sql`
18. `v2-referrals.sql`

### Reward dependency rule
The `reward_ledger` table is created by `v2-extended-schema.sql`; there is no separate reward-ledger migration in this V2 branch. `v2-reward-lots.sql` MUST run after `v2-extended-schema.sql` and before any SQL that creates or spends lot-based reward points. Scheme and referral reward credits depend on `reward_point_lots`.

### Existing database migration warning
Do not blindly rerun the full list on an existing database. Apply only the new/changed migrations in dependency order. `v2-reward-lots.sql` deliberately auto-backfills only dealers whose reward history has no prior redeem/expire entries. Historical dealers with redemption/expiry activity require reconciliation before lot-based balances are enabled for production use.

### Production safety
- Never place a Supabase service-role key in browser code or GitHub source.
- Keep RLS enabled; privileged mutations must use the authorized RPC path.
- Verify stock deduction remains payment-received + delivery-only and idempotent before production launch.
- Test the SQL against a staging Supabase project before production migration.
