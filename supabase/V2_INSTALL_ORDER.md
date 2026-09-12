# TORVO V2 — SUPABASE STAGING INSTALL ORDER

This file is the authoritative dependency order for TORVO V2 database installation/testing. Do not install migrations alphabetically. Production remains blocked until this chain compiles and the staging gates below pass.

## SAFETY RULES

- Run this only against the dedicated TORVO V2 staging Supabase project first.
- Never paste service-role keys, provider secrets, passwords, PINs, OTP secrets, database passwords or private tokens into GitHub.
- Stop on the first SQL error. Fix the dependency/error before continuing.
- GitHub source presence is not runtime verification.
- A backup request is not a successful backup. Only trusted-worker completion plus integrity verification may mark a run verified.

## INSTALL SEQUENCE

Use the repository's `supabase/` V2 migration files in dependency order. Preserve any dependency notes inside each migration. The backup/recovery group must be installed after the core role/auth foundation it references and before production release verification:

1. Core V2 schema, role/profile/dealer-link and security foundation migrations.
2. Catalog/item/product/master-value and dealer catalog/rate/search migrations.
3. Purchase Order / Sales Order / revision / Dealer OK / Estimate / Add More Items migrations and duplicate-line integrity guards.
4. Purchase Entry, inventory movement, low-stock and Purchase Requirement/fulfilment migrations.
5. Private Suitable/fitment and role/dealer privacy migrations.
6. Dashboard/admin/business RPC migrations after their dependent tables/policies exist.
7. Backup and disaster-recovery group, in this exact order:
   - `v2-backup-control.sql`
   - `v2-backup-channels.sql`
   - `v2-backup-worker-contract.sql`
8. Later feature migrations such as conversion/repacking, rewards, GST and advanced modules only after their prerequisites are present.

Before executing staging, inventory the actual `supabase/v2-*.sql` files and reconcile every file into this dependency sequence. Never assume a new migration is safe merely because its filename sorts after another file.

## MANDATORY STAGING GATE

The release is blocked until all applicable checks pass with real staging sessions/data:

- OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEER and DEALER authorization/privacy.
- Dealer financial privacy and private Suitable/fitment visibility.
- Dealer catalog/rate server calculation and scalable search/finders.
- PURCHASE ORDER -> SALES ORDER -> revision -> exact latest DEALER OK -> ESTIMATE flow.
- TORVO revision invalidates old DEALER OK; ESTIMATE locks direct revision.
- ADD MORE ITEMS creates a separate linked additional order and never mutates the original order/Estimate.
- Duplicate catalog/order item lines are blocked by UI and database integrity.
- Purchase Entry receives supplier stock exactly once; duplicate Supplier+Invoice is blocked.
- Purchase correction/reversal is audited and does not duplicate stock.
- Purchase Requirements partial/full fulfilment, exact Dealer allocation and tracking reversal are secure/audited.
- Payment + actual Delivery deducts stock exactly once. ESTIMATE/PICKED/PACKED never deduct stock.
- Replayed payment/delivery actions remain idempotent.
- Dealer fitment suggestions earn ZERO points and remain private between Dealer and TORVO.
- No secrets/service-role credentials are exposed to browser/client/GitHub.

Run repository staging checklists under `supabase/tests/` where applicable, including:

- `tests/v2-purchase-requirement-security-checklist.sql`
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
- exactly-once stock/payment tests;
- backup checksum/manifest verification status;
- restore drill date/result.

Do not describe TORVO V2 database, backup, WhatsApp OTP, payment/stock flow or release as runtime-verified until the corresponding staging/runtime evidence actually exists.
