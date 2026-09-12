# TORVO V2 — SUPABASE STAGING INSTALL ORDER

This file is the authoritative dependency order for TORVO V2 database installation/testing. Do not install migrations alphabetically. Production remains blocked until this chain compiles and the staging gates below pass.

## SAFETY RULES
- Run only against dedicated TORVO V2 staging first.
- Never place service-role keys, provider secrets, passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Stop on first SQL error and fix dependency before continuing.
- GitHub source presence is NOT runtime verification.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql`, then role/profile/dealer-link and base RLS/security dependencies.

2. CATALOG: catalog/item/master/rate/search foundations and their dependent RPCs.

3. SALES: sales/order foundations first, then `v2-sales-order-integrity.sql`, then `v2-additional-purchase-order.sql`. These final definitions enforce duplicate-line protection, latest DEALER OK, revision invalidation, ESTIMATE locking and separate ADD MORE ITEMS orders.

4. PURCHASE + INVENTORY: inventory/`inventory_movements` foundation, `v2-purchase-entry-rpcs.sql`, `v2-inventory-purchase-guard.sql`, `v2-purchase-entry-integrity.sql`, then `v2-purchase-buying-intelligence.sql`. Purchase buying intelligence is OWNER-only and shows real supplier/rate history; it never fabricates a recommended rate.

5. PURCHASE REQUIREMENTS: `v2-purchase-requirements.sql`, `v2-purchase-requirement-rpcs.sql`, `v2-purchase-requirement-item-link.sql`, `v2-purchase-requirement-fulfilment.sql`, `v2-purchase-requirement-receipt-integrity.sql`. Only non-reversed received Purchase stock can fulfil requirements; linking never changes inventory.

6. PAYMENT / DELIVERY: payment/dispatch foundations including older `v2-delivery-rpc.sql` if required, then `v2-delivery-stock-integrity.sql` LAST for its signatures. Actual Delivery is the only outbound sales stock deduction point and uses canonical `inventory_movements`.

7. CENTRAL MAKER-CHECKER: after `app_users`, `audit_log` and all transaction foundations exist, install `v2-maker-checker-approval.sql`, then `v2-maker-checker-payment-gate.sql`. Owner controls which ADMIN/ACCOUNTANT users can approve and whether a trusted checker can self-approve. ACCOUNTANT/ADMIN payment entry is only a pending request; approval posts the payment through the idempotent `record_payment` path. OWNER may retain direct operational authority. Do not describe Purchase/reversal/other modules as approval-gated until their final-effect RPC is explicitly wired.

8. Inventory movement center, low-stock/reorder, Purchase Cost History and reporting views. Read/reporting modules must never introduce another inventory write path.

9. Private Suitable/fitment and Dealer/role privacy migrations.

10. Dashboard/admin/business/reporting RPCs after dependencies. If an older same-signature `record_payment`, `deliver_estimate`, Purchase Entry or Requirement RPC exists, install it BEFORE the integrity layer or skip it. Integrity definitions remain final.

11. BACKUP in exact order: `v2-backup-control.sql`, `v2-backup-channels.sql`, `v2-backup-worker-contract.sql`.

12. Later conversion/repacking, rewards, GST and advanced modules only after prerequisites.

## MANDATORY STAGING GATE
- OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER authorization/privacy.
- Dealer financial privacy and private Suitable/fitment visibility.
- PURCHASE ORDER -> SALES ORDER -> revision -> latest DEALER OK -> ESTIMATE.
- ADD MORE ITEMS is separate and original order/Estimate is immutable.
- Purchase Entry creation alone does not change stock; explicit receipt receives exactly once.
- Duplicate Supplier+Invoice and duplicate item lines blocked.
- Purchase reversal audited/exactly once; requirement-linked receipt cannot reverse until active links reverse.
- Purchase Requirement rejects unreceived/reversed Purchase stock.
- Purchase receive + actual Delivery both use canonical `inventory_movements`.
- Payment + actual Delivery deducts stock exactly once; ESTIMATE/PICKED/PACKED/READY never deduct stock.
- Payment request-key replay safe; conflicting payload rejected.
- Delivery same-key replay safe; different key after finalization rejected.
- Legacy `deliver_estimate` cannot double deduct.
- Direct client writes cannot bypass stock/finalization integrity.
- Maker-checker: Owner can independently grant approval to any 1/2/3 Accountants/Admins; unauthorized checker denied; self-approval denied by default; explicit Owner self-approval permission works; decided request cannot be decided again; maker sees final status/checker/time.
- Payment maker-checker: Accountant/Admin submission does NOT create payment immediately; APPROVE creates exactly one payment; REJECT creates none; approval replay cannot duplicate payment; payment still obeys outstanding/idempotency validation at approval time.
- OWNER-only Purchase buying intelligence never leaks purchase cost/history to unauthorized roles.
- No secrets/service-role credentials exposed.

Run applicable staging checklists:
- `tests/v2-purchase-entry-security-checklist.sql`
- `tests/v2-purchase-requirement-security-checklist.sql`
- `tests/v2-sales-delivery-integrity-checklist.sql`
- `tests/v2-maker-checker-approval-checklist.sql`
- `tests/v2-backup-control-security-checklist.sql`

## BACKUP / DR RELEASE GATE
Backup is production-trusted only after OWNER/ADMIN authorization, VERIFIED-age warning/critical policy, trusted-worker-only verification, encrypted secret-free artifact, checksum/restore manifest, secure export/provider confirmation, idempotent completion, and a clean staging restore drill all pass.

## RELEASE EVIDENCE
Retain non-secret migration set + branch/commit, pass/fail evidence, role/security results, exactly-once Purchase/payment/Delivery tests, approval tests, backup checksum/manifest and restore drill result. Do not call database/payment/stock/approval/backup runtime-verified until staging evidence exists.
