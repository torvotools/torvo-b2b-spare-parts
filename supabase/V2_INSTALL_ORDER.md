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
4. PURCHASE + INVENTORY: inventory + canonical `inventory_movements` -> `v2-purchase-entry-rpcs.sql` -> `v2-inventory-purchase-guard.sql` -> `v2-purchase-entry-integrity.sql` -> `v2-purchase-atomic-save-receive.sql` -> `v2-purchase-buying-intelligence.sql`. Browser Purchase Entry uses the atomic SAVE & RECEIVE RPC so header/lines/stock/movements either all commit or all roll back. The lower-level create/receive functions remain controlled recovery primitives, not the normal UI path. Buying intelligence is OWNER-only and includes only actually received, unreversed purchases.
5. PURCHASE REQUIREMENTS: `v2-purchase-requirements.sql` -> `v2-purchase-requirement-rpcs.sql` -> `v2-purchase-requirement-item-link.sql` -> `v2-purchase-requirement-fulfilment.sql` -> `v2-purchase-requirement-receipt-integrity.sql`.
6. PAYMENT / DELIVERY: payment/dispatch foundations including older `v2-delivery-rpc.sql` if required -> `v2-delivery-stock-integrity.sql` LAST for same signatures. Actual Delivery is the only outbound sales stock deduction point.
7. CENTRAL MAKER-CHECKER: `v2-maker-checker-approval.sql` -> `v2-maker-checker-payment-gate.sql` after transaction foundations. Owner controls checker permissions/self-approval permission. ACCOUNTANT/ADMIN payment submission remains pending until authorized approval posts through idempotent `record_payment`.
8. Inventory movement center, low-stock/reorder, Purchase Cost History/reporting read layers.
9. Private Suitable/fitment and Dealer/role privacy.
10. Dashboard/admin/business/reporting RPCs. Older overlapping transaction RPCs must be installed BEFORE integrity layers or skipped.
11. BACKUP: `v2-backup-control.sql` -> `v2-backup-channels.sql` -> `v2-backup-worker-contract.sql`.
12. Later conversion/repacking/rewards/GST/advanced modules after prerequisites.

## MANDATORY STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER.
- PURCHASE ORDER -> SALES ORDER -> latest DEALER OK -> ESTIMATE; revision invalidates old OK; ADD MORE ITEMS separate.
- Atomic Purchase SAVE & RECEIVE: success creates exactly one header, unique lines, one receipt, correct canonical movements and exact stock increase; injected failure leaves NONE of them.
- Atomic Purchase exact request-key replay returns same Purchase with no second stock/movement; same key + changed payload rejects.
- Lower-level receive: same Purchase+same key replay safe; same Purchase+different key rejects; same key+different Purchase rejects; reversed Purchase cannot re-receive.
- Duplicate Supplier+Invoice and duplicate Purchase item blocked.
- Purchase reversal exactly once; active Requirement link blocks reversal until link reversal.
- Buying intelligence excludes unreceived/reversed purchases and remains OWNER-only.
- Purchase Requirement only links non-reversed received stock and never changes inventory.
- Purchase receipt + actual Delivery both use canonical `inventory_movements`.
- ESTIMATE/PICKED/PACKED/READY never deduct stock; payment requirement + actual Delivery deduct exactly once.
- Payment key replay safe/conflict rejected; Delivery same-key replay safe/different-key refinalization rejected; legacy `deliver_estimate` cannot double deduct.
- Maker-checker: Owner may grant any 1/2/3 Accountants/Admins; unauthorized denied; self-approval default denied; explicit Owner permission works; decided request cannot be decided twice.
- Payment approval: submission creates no payment; APPROVE creates exactly one; REJECT creates none; current outstanding/idempotency revalidated at approval time.
- No direct client write bypass and no secret exposure.

Run staging checklists: `tests/v2-purchase-entry-security-checklist.sql`, `tests/v2-purchase-requirement-security-checklist.sql`, `tests/v2-sales-delivery-integrity-checklist.sql`, `tests/v2-maker-checker-approval-checklist.sql`, `tests/v2-backup-control-security-checklist.sql`.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exactly-once Purchase/payment/Delivery evidence, approval evidence, backup checksum/manifest and clean restore drill. No runtime-verified claim without this evidence.
