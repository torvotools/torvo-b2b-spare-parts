# TORVO V2 — OWNER FINAL SUBMISSION GATE
Date: 2026-10-09. Canonical branch: torvo-v2-build. Refresh remote HEAD before each write.

## Owner's final product decision
Deliver one premium, consistent, complete TORVO V2 across Website, Dealer App, Salesman App, Store Keeper App, Accountant and Owner/Admin. Owner delegates ordinary UI/UX decisions. Preserve the original TORVO logo, RED/BLACK/WHITE/GREY theme, canonical design foundation, approved business logic and role boundaries. Do not revive V27/V72 or create a parallel database/deployment.

## Read-only staging audit (2026-10-09)
STAGING project jvmhhngjlaqrfopfavur: official location states=0, districts=0, cities=0; sales_documents=0; purchase_headers=0; backup_runs=0; backup_restore_manifests=0; app_release_artifacts=0.
These are hard evidence gaps. Do not fabricate GoI LGD/OGD data, identities, business transactions, device tests, signed releases or backup artifacts.
CI success alone is not runtime acceptance.

## Mandatory final evidence matrix
1. Architecture: one codebase/backend; exact-SHA build, Cloudflare, Android CI; duplicate/dead route audit.
2. Six-surface UI/UX: desktop/mobile visual checks, original media/logo, typography, accessibility, forms, empty/loading/error/success states, working controls.
3. Registration: genuine official State→District→City data, Other City, submit and approval E2E.
4. Security: genuine Dealer email OTP, Staff ID/OTP, single device/session, revocation, role privacy.
5. Catalog: search, filters, fitment, original product photos and requirement fallback.
6. Sales: Dealer PO→Quotation→Dealer OK→Estimate→Marg Bill Approval→Sale→Stock Out, retries/idempotency.
7. Inventory: purchases, receipts, stock, dispatch, delivery, returns and reconciled quantities.
8. Finance: rates, expense/profit, report totals/details and dealer privacy.
9. Operations: service book, rewards, referrals, notifications, role workflows.
10. Admin: destructive operations, confirmation, usage checks and audit.
11. Backup: real trusted encrypted artifact, checksum, identity manifest, secret-free portable export, isolated restore.
12. Android: exact-SHA APK physically installed, login/UI/business checks, privately signed release evidence.

## Canonical commercial and public boundaries
Public website is discovery/referral only: NO public prices, stock promises, checkout or payment.
Dealer registered-email OTP; staff ID and OTP. Accountant desktop-only.
Dealer PO→Quotation→Dealer OK→Estimate→Marg Bill Approval→Sale→Stock Out→Dispatch→Delivery. Typing a Marg Bill number alone never posts stock.

## Release rule
Verified fully accepted workstreams currently 0/12 = 0%; remaining 100% (acceptance score, NOT code completion). Mark each gate PASS only with timestamp, environment, exact SHA, actor reference without secrets and actual runtime/device evidence. Do not claim FINAL/100%/LIVE READY until all 12 are accepted. Production database, main, domain cutover and release signing require explicit Owner approval.

## Execution
Fix the complete product in compatible bulk, not repetitive cosmetic-only micro-commits. Reuse the canonical design system; keep approved business/security decisions intact. After each batch verify exact-SHA CI, staging behavior and applicable physical-device evidence. Keep this document as an acceptance contract, not as a substitute for implementation.

## Owner decision — 10 October 2026: private live trial before public launch
Owner requests a 15–20 day INTERNAL live-testing period starting no earlier than 11 October 2026, followed by public announcement/rollout only after Owner confirmation and required acceptance gates pass. Internal live testing means restricted, authenticated owner/staff/dealer access; it does NOT authorize public marketing, public dealer rollout, production database changes, domain cutover, production signing, or bypassing backup/security prerequisites. Prepare a controlled staging/private-preview pilot first; obtain explicit Owner approval for any production cutover. Record real login, catalog, transaction, stock, reports, backup and device evidence, with incident tracking and rollback readiness. Tentative public decision window 26–31 October 2026 is conditional, not a committed launch date.
