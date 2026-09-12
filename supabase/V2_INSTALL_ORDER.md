# TORVO V2 Supabase install order

This file is the authoritative dependency order for a fresh V2 database setup. Do not run the SQL files alphabetically.

## Core
1. `v2-schema.sql`
2. `v2-extended-schema.sql`
3. `v2-rls.sql`
4. `v2-dealer-financial-privacy.sql`
5. `v2-admin-rpcs.sql`
6. `v2-business-rpcs.sql`
7. `v2-payment-idempotency.sql`
8. `v2-operations-rpcs.sql`
9. `v2-reorder-guard.sql`
10. `v2-purchase-cost-history.sql`
11. `v2-dashboard-rpc.sql`
12. `v2-report-summary-rpc.sql`
13. `v2-report-detail-rpc.sql`
14. `v2-feature-controls.sql`
15. `v2-backup-control.sql`
16. `v2-backup-channels.sql`

## Dealer/catalog operations
17. `v2-dealer-link.sql`
18. `v2-dealer-machine-spares.sql`
19. `v2-message-direction.sql`
20. `v2-sales-catalog-rpcs.sql`
21. `v2-dealer-catalog-search.sql`
22. `v2-catalog-master-values.sql`
23. `v2-delivery-rpc.sql`

## Sales team / assisted field operations
24. `v2-sales-team-mapping.sql`
25. `v2-sales-team-rpcs.sql`
26. `v2-salesman-assisted-workflows.sql`
27. `v2-sales-revision-rpcs.sql`
28. `v2-sales-line-integrity.sql`
29. `v2-purchase-requirements.sql`
30. `v2-purchase-requirement-rpcs.sql`
31. `v2-purchase-requirement-item-link.sql`
32. `v2-purchase-entry-rpcs.sql`
33. `v2-inventory-purchase-guard.sql`
34. `v2-purchase-requirement-fulfilment.sql`
35. `v2-item-movement-center.sql`

## Private suitable knowledge / Dealer fitment suggestions
36. `v2-knowledge-rewards.sql`

## Schemes and sales rewards
37. `v2-scheme-progress.sql`
38. `v2-reward-lots.sql`
39. `v2-reward-reconciliation.sql`
40. `v2-rewards-rpcs.sql`
41. `v2-scheme-reward-credit.sql`
42. `v2-referrals.sql`

## Critical privacy overrides
`v2-dealer-financial-privacy.sql` MUST run immediately after base RLS. It removes Dealer direct SELECT access to `payments`. Dealer Portal is intentionally operational: own Sales/Estimate and own delivery/dispatch status may be visible, but payment/accounting/outstanding rows remain internal to Owner/Admin/Accountant. UI hiding is not the security boundary.

## Mandatory release notes
- `v2-dealer-catalog-search.sql` is the Dealer-safe scalable catalog search path. Dealer UI must never use Purchase catalog RPCs.
- `v2-sales-line-integrity.sql` enforces one catalog item per Sales/Estimate document at the database boundary.
- `v2-backup-control.sql` + `v2-backup-channels.sql` create backup control metadata only; trusted backup artifacts require a server worker and verification.
- GitHub SQL is source-level work until the exact migration chain is executed and tested in staging.

## Mandatory staging release gate
Before production, test Owner/Admin/Salesman/Accountant/Store Keeper/Dealer separately. In particular: Dealer A must never read Dealer B documents/change requests; Dealer must not read `payments`, Purchase Rate/supplier/private Suitable data; Dealer catalog search must work only for an active linked approved Dealer; Add More Items must create a separate linked order without mutating the original; stale Dealer OK must fail after revision; duplicate sales lines must fail at DB level; payment+delivery stock deduction must happen exactly once; Purchase receipt/reversal and Purchase Requirement allocation must be transactional; backup requests must remain unverified until a trusted worker verifies the artifact. Record every staging failure before cutover.

## Restore / disaster recovery gate
A Project Restore package is trusted only after its checksum is verified and `docs/TORVO-V2-RESTORE-GUIDE.md` is successfully followed in a clean staging environment. Secrets/service-role credentials are never stored in the package or repository.

## Production safety
- Never place a Supabase service-role key in browser code or GitHub source.
- Keep RLS enabled; privileged mutations must use authorized RPC paths.
- Keep V27/main untouched until V2 staging, responsive UI, security and restore gates pass and Owner explicitly approves cutover.
