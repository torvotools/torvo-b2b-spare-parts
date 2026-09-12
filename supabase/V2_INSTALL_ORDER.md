# TORVO V2 — SUPABASE STAGING INSTALL ORDER

This file is the authoritative dependency order for TORVO V2 database installation/testing. Do not install migrations alphabetically. Production remains blocked until this chain compiles and the staging gates below pass.

## SAFETY RULES

- Run this only against the dedicated TORVO V2 staging Supabase project first.
- Never paste service-role keys, provider secrets, passwords, PINs, OTP secrets, database passwords or private tokens into GitHub.
- Stop on the first SQL error. Fix the dependency/error before continuing.
- GitHub source presence is not runtime verification.
- A backup request is not a successful backup. Only trusted-worker completion plus integrity verification may mark a run verified.

## INSTALL SEQUENCE

Use the repository's `supabase/` V2 migration files in dependency order. Preserve dependency notes inside each migration.

1. Core foundation:
   - `v2-schema.sql`
   - role/profile/dealer-link and base RLS/security migrations that depend on the schema.

2. Catalog foundation:
   - catalog/item/product/master-value migrations;
   - dealer catalog/rate/search migrations;
   - sales catalog RPCs only after their catalog/rate tables exist.

3. Purchase Order / Sales Order foundation and final integrity definitions:
   - sales/order foundation RPCs and team mapping prerequisites;
   - `v2-sales-order-integrity.sql`
   - `v2-additional-purchase-order.sql`
   These enforce duplicate-line protection, exact latest DEALER OK, revision invalidation, ESTIMATE locking and separate linked ADD MORE ITEMS orders. Any older same-signature RPC must be installed before these final definitions.

4. Purchase Entry and canonical inventory movement chain:
   - inventory / `inventory_movements` foundation from the core schema and operational migrations;
   - `v2-purchase-entry-rpcs.sql`
   - `v2-inventory-purchase-guard.sql`
   - `v2-purchase-entry-integrity.sql`
   Purchase Entry creation does not receive stock. `RECEIVE PURCHASE STOCK` is the single supplier stock-receipt action, writes inventory and the canonical `inventory_movements` ledger exactly once, and duplicate Supplier+Invoice / duplicate item lines are blocked.

5. Purchase Requirement chain, after Purchase Entry integrity exists:
   - `v2-purchase-requirements.sql`
   - `v2-purchase-requirement-rpcs.sql`
   - `v2-purchase-requirement-item-link.sql`
   - `v2-purchase-requirement-fulfilment.sql`
   - `v2-purchase-requirement-receipt-integrity.sql`
   Requirement fulfilment may use only a non-reversed Purchase stock receipt. Requirement linkage/allocation never changes inventory. Active requirement allocations block Purchase stock reversal until those links are reversed through the audited requirement flow.

6. Payment / dispatch / actual Delivery chain, after payment, dispatch, inventory and `inventory_movements` objects exist:
   - payment idempotency/foundation migrations;
   - dispatch/delivery foundation migrations including `v2-delivery-rpc.sql` if required by the existing environment;
   - `v2-delivery-stock-integrity.sql` LAST for these signatures.
   `v2-delivery-stock-integrity.sql` is the final outbound-sales stock definition. It uses the same canonical `inventory_movements` ledger as Purchase Entry, makes actual Delivery the only sales stock-deduction point, and converts legacy `deliver_estimate(uuid)` into a wrapper around `finalize_actual_delivery(...)`. Do not reinstall an older `deliver_estimate` or `record_payment` definition after it.

7. Inventory movement center, low-stock/reorder, Purchase Cost History and operational views/RPCs after the canonical Purchase/Delivery write paths above. Read/reporting modules must not introduce another inventory write path.

8. Private Suitable/fitment and role/dealer privacy migrations.

9. Dashboard/admin/business/reporting RPC migrations after their dependent tables/policies exist. IMPORTANT: if these files contain an older same-signature `record_payment`, `deliver_estimate`, Purchase Entry or Purchase Requirement RPC, install that older foundation before the corresponding integrity layer above or skip the superseded definition. Integrity definitions must remain final.

10. Backup and disaster-recovery group, in this exact order:
   - `v2-backup-control.sql`
   - `v2-backup-channels.sql`
   - `v2-backup-worker-contract.sql`

11. Later feature migrations such as conversion/repacking, rewards, GST and advanced modules only after their prerequisites are present.

Before executing staging, inventory the actual `supabase/v2-*.sql` files and reconcile every file into this dependency sequence. Never assume a new migration is safe merely because its filename sorts after another file.

## MANDATORY STAGING GATE

The release is blocked until all applicable checks pass with real staging sessions/data:

- OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER and DEALER authorization/privacy.
- Dealer financial privacy and private Suitable/fitment visibility.
- Dealer catalog/rate server calculation and scalable search/finders.
- PURCHASE ORDER -> SALES ORDER -> revision -> exact latest DEALER OK -> ESTIMATE flow.
- TORVO revision invalidates old DEALER OK; ESTIMATE locks direct revision.
- ADD MORE ITEMS creates a separate linked additional order and never mutates the original order/Estimate.
- Duplicate catalog/order item lines are blocked by UI and database integrity.
- Purchase Entry creation alone does not change inventory; explicit stock receipt receives supplier stock exactly once.
- Duplicate Supplier+Invoice and duplicate Purchase item lines are blocked.
- Purchase correction/reversal is audited, exactly once and does not duplicate/re-receive stock.
- Purchase Requirements partial/full fulfilment, exact Dealer allocation and tracking reversal are secure/audited.
- Purchase Requirement fulfilment rejects saved-but-not-received Purchase Entries and reversed stock receipts.
- Purchase stock reversal is blocked until active Purchase Requirement links are reversed first.
- Purchase receipt and actual Delivery both write the canonical `inventory_movements` ledger; no parallel sales stock ledger exists.
- Payment + actual Delivery deducts stock exactly once. ESTIMATE/PICKED/PACKED/READY never deduct stock.
- Same payment request replay returns the original payment; conflicting request-key payload is rejected.
- Same Delivery request replay is safe; a different request key cannot finalize an already-finalized Estimate.
- Delivery cannot finalize with insufficient stock or insufficient required payment.
- Legacy `deliver_estimate(uuid)` cannot create a second stock-deduction path.
- Direct client writes cannot bypass inventory, inventory movement, Purchase receipt or Delivery finalization integrity.
- Dealer fitment suggestions earn ZERO points and remain private between Dealer and TORVO.
- No secrets/service-role credentials are exposed to browser/client/GitHub.

Run repository staging checklists under `supabase/tests/` where applicable, including:

- `tests/v2-purchase-entry-security-checklist.sql`
- `tests/v2-purchase-requirement-security-checklist.sql`
- `tests/v2-sales-delivery-integrity-checklist.sql`
- `tests/v2-backup-control-security-checklist.sql`

## BACKUP / DISASTER-RECOVERY RELEASE GATE

Backup Control Center is not production-trusted until all of these are proven in staging:

- OWNER/ADMIN can perform only the backup actions allowed by policy; other roles and ANON are denied.
- The dashboard status is based on the last VERIFIED backup, not merely the latest request.
- No VERIFIED backup for >=24 hours produces WARNING; >=48 hours produces CRITICAL.
- Browser/client code cannot mark a backup verified or fabricate worker completion.
- Trusted worker records integrity evidence/checksum and the restore manifest.
- Portable backup artifacts are encrypted and exclude secrets/passwords/service-role credentials.
- A Full Restore Point records database backup, code branch/commit, database/schema version, checksum and restore manifest.
- Download/share uses a trusted signed/secure export path; UI never claims Email/WhatsApp delivery until the provider confirms success.
- Replay/completion is idempotent and failed runs remain auditable.
- A clean staging restore drill succeeds and checksum/manifest are verified.
- After restore, critical role/order/payment/stock/privacy tests pass again.

## RELEASE EVIDENCE

For each staging run, retain non-secret evidence of:

- migration set + code branch/commit tested;
- pass/fail result and first failure if any;
- role/security test results;
- exactly-once Purchase receipt, payment and Delivery stock tests;
- backup checksum/manifest verification status;
- restore drill date/result.

Do not describe TORVO V2 database, backup, WhatsApp OTP, payment/stock flow or release as runtime-verified until the corresponding staging/runtime evidence actually exists.
