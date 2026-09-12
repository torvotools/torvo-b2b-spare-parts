# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Integrity migrations remain the final definition for overlapping transaction signatures.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql`, role/profile/dealer-link and base RLS/security dependencies.
2. CATALOG: catalog/item/master/rate/search foundations + dependent RPCs.
3. SALES: sales/order foundations -> `v2-sales-order-integrity.sql` -> `v2-additional-purchase-order.sql`.
4. PURCHASE + INVENTORY: inventory + canonical `inventory_movements` -> `v2-purchase-entry-rpcs.sql` -> `v2-inventory-purchase-guard.sql` -> `v2-purchase-entry-integrity.sql` -> `v2-purchase-atomic-save-receive.sql` -> `v2-purchase-buying-intelligence.sql`.
5. PURCHASE REQUIREMENTS: `v2-purchase-requirements.sql` -> `v2-purchase-requirement-rpcs.sql` -> `v2-purchase-requirement-item-link.sql` -> `v2-purchase-requirement-fulfilment.sql` -> `v2-purchase-requirement-receipt-integrity.sql`.
6. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`. Actual Delivery is the only outbound sales stock deduction point.
7. RETURNS BASE: `v2-sales-purchase-returns.sql` after Delivery + received Purchase integrity.
8. CENTRAL MAKER-CHECKER: `v2-maker-checker-approval.sql` -> `v2-maker-checker-payment-gate.sql` -> `v2-payment-approval-final-boundary.sql` -> `v2-approval-permission-read.sql` -> `v2-purchase-approval-final-boundary.sql` -> `v2-return-approval-gate.sql`. Payment direct posting and Admin Purchase/Return stock effects are gated at final server boundaries.
9. Inventory movement center, low-stock/reorder, Purchase Cost History/reporting read layers.
10. Private Suitable/fitment and Dealer/role privacy.
11. Dashboard/admin/business/reporting RPCs. Older overlapping transaction RPCs must be installed BEFORE final integrity layers or skipped.
12. BACKUP: `v2-backup-control.sql` -> `v2-backup-channels.sql` -> `v2-backup-worker-contract.sql`.
13. Later conversion/repacking/rewards/GST/advanced modules after prerequisites.

## MANDATORY STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER.
- PURCHASE ORDER -> SALES ORDER -> latest DEALER OK -> ESTIMATE; revision invalidates old OK; ADD MORE ITEMS separate.
- OWNER atomic Purchase SAVE & RECEIVE commits header/lines/receipt/movements/stock together; injected failure leaves none; exact retry idempotent.
- ADMIN Purchase submit creates PENDING APPROVAL and ZERO stock/header/receipt effect; approval applies exactly once through non-browser-executable internal effect; rejection applies none; direct Admin atomic Purchase rejects.
- Duplicate Supplier+Invoice/item blocked; Purchase reversal exactly once; active Requirement link blocks reversal; buying intelligence OWNER-only received/unreversed data.
- Purchase Requirement links only received/unreversed stock and never duplicates inventory.
- ESTIMATE/PICKED/PACKED/READY never deduct; full required payment + Actual Delivery deduct exactly once.
- Payment: OWNER direct allowed; ADMIN/ACCOUNTANT direct posting rejected; submit creates no payment; APPROVE creates exactly one; REJECT none; internal payment effect has no PUBLIC/anon/authenticated EXECUTE.
- Maker-checker: Owner can grant chosen active Admin/Accountant; unauthorized denied; self-approval default denied; explicit self-approval permission works; decided request cannot decide twice.
- ADMIN Sales/Purchase Return submit creates pending approval and ZERO stock effect; APPROVE applies canonical return exactly once; REJECT none. OWNER direct return remains allowed.
- Sales Return cannot exceed actually delivered less prior completed returns; Purchase Return cannot exceed received less prior completed returns, cannot drive stock negative, and active Purchase Requirement link blocks it.
- Canonical `inventory_movements` reconciles Purchase receipt + Delivery + Sales Return + Purchase Return.
- No direct client write bypass and no secret exposure.

Run staging checklists: `tests/v2-purchase-entry-security-checklist.sql`, `tests/v2-purchase-requirement-security-checklist.sql`, `tests/v2-sales-delivery-integrity-checklist.sql`, `tests/v2-maker-checker-approval-checklist.sql`, `tests/v2-backup-control-security-checklist.sql`.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exactly-once Purchase/payment/Delivery/Return evidence, approval evidence, backup checksum/manifest and clean restore drill. No runtime-verified claim without this evidence.
