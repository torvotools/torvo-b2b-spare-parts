# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Integrity migrations remain the final definition for overlapping transaction signatures.
- Public Customer pricing/payment is server-authoritative; never trust browser-sent rate, discount, total, payment-success or role/channel.
- Do not create duplicate business tables merely for Website/App/Desktop. They are interfaces over one authoritative business platform.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql`, role/profile/dealer-link and base RLS/security dependencies.
2. CATALOG: catalog/item/master/rate/search foundations + dependent RPCs.
3. PUBLIC RETAIL PRICING: after authoritative product/Dealer-rate dependencies, install `v2-public-retail-pricing-foundation.sql`. Public retail is a separate HIGH customer rate channel; staging must prove it cannot expose/select private Dealer pricing.
4. SALES: sales/order foundations -> `v2-sales-order-integrity.sql` -> `v2-additional-purchase-order.sql`.
5. PURCHASE + INVENTORY: inventory + canonical `inventory_movements` -> `v2-purchase-entry-rpcs.sql` -> `v2-inventory-purchase-guard.sql` -> `v2-purchase-entry-integrity.sql` -> `v2-purchase-atomic-save-receive.sql` -> `v2-purchase-buying-intelligence.sql`.
6. PURCHASE REQUIREMENTS: `v2-purchase-requirements.sql` -> `v2-purchase-requirement-rpcs.sql` -> `v2-purchase-requirement-item-link.sql` -> `v2-purchase-requirement-fulfilment.sql` -> `v2-purchase-requirement-receipt-integrity.sql`.
7. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`. Actual Delivery is the only outbound sales stock deduction point under the existing B2B rule.
8. PUBLIC RETAIL CHECKOUT: after pricing + payment foundations, install `v2-public-checkout-payment-modes.sql`. Then install later authoritative public cart/address/order/provider-verification RPCs only after their dependencies. FULL PREPAID and LOGISTICS ADVANCE + BALANCE ON DELIVERY are the approved modes; ZERO-ADVANCE COD is not approved.
9. RETURNS BASE: `v2-sales-purchase-returns.sql` after Delivery + received Purchase integrity. These are internal controlled returns, not a public no-reason Return feature.
10. CENTRAL MAKER-CHECKER: `v2-maker-checker-approval.sql` -> `v2-maker-checker-payment-gate.sql` -> `v2-payment-approval-final-boundary.sql` -> `v2-approval-permission-read.sql` -> `v2-purchase-approval-final-boundary.sql` -> `v2-return-approval-gate.sql` -> `v2-return-approval-checker-fix.sql`.
11. Inventory movement center, low-stock/reorder, Purchase Cost History/reporting read layers.
12. Private Suitable/fitment and Dealer/role privacy.
13. Dashboard/admin/business/reporting RPCs. Older overlapping transaction RPCs must be installed BEFORE final integrity layers or skipped.
14. PUBLIC CUSTOMER CLAIM/EXCEPTION: controlled claim/RTO/refund/replacement layers after authoritative public order/payment records exist. Do not expose a routine public RETURN button.
15. BACKUP: `v2-backup-control.sql` -> `v2-backup-channels.sql` -> `v2-backup-worker-contract.sql`.
16. Later conversion/repacking/rewards/GST/advanced modules after prerequisites.

## MANDATORY STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER boundaries.
- Public website cannot read Dealer Rate A/B/C, Dealer schemes or private fitment merely through catalog/checkout access.
- Public retail price is server-calculated and protected from client rate/channel/discount substitution; invalid protected pricing fails safely.
- FULL PREPAID: client redirect/button is not payment proof; only verified provider/server payment can enter paid fulfilment.
- LOGISTICS ADVANCE: zero-advance fulfilment is rejected; required advance must be verified; balance-on-delivery is stored separately and cannot be client-forged.
- Duplicate provider callbacks/retries do not duplicate payment credit, order confirmation or stock effects.
- RTO/refusal treatment is auditable; Admin/legal/TORVO-fault exceptions can be handled without creating a routine public no-reason Return path.
- PURCHASE ORDER -> SALES ORDER -> latest DEALER OK -> ESTIMATE; revision invalidates old OK; ADD MORE ITEMS separate.
- OWNER atomic Purchase SAVE & RECEIVE commits header/lines/receipt/movements/stock together; injected failure leaves none; exact retry idempotent.
- ADMIN Purchase submit creates PENDING APPROVAL and ZERO stock/header/receipt effect; approval applies exactly once; rejection applies none; direct Admin atomic Purchase rejects.
- Duplicate Supplier+Invoice/item blocked; Purchase reversal exactly once; active Requirement link blocks reversal; buying intelligence OWNER-only received/unreversed data.
- Purchase Requirement links only received/unreversed stock and never duplicates inventory.
- ESTIMATE/PICKED/PACKED/READY never deduct; authoritative payment requirement + Actual Delivery deduct exactly once under the applicable stock rule.
- Payment: OWNER direct allowed; ADMIN/ACCOUNTANT direct posting rejected; submit creates no payment; APPROVE creates exactly one; REJECT none; internal payment effect has no PUBLIC/anon/authenticated EXECUTE.
- Maker-checker: Owner can grant chosen active Admin/Accountant; unauthorized denied; self-approval default denied; explicit self-approval permission works; decided request cannot decide twice.
- ADMIN Sales/Purchase Return submit creates pending approval and ZERO stock effect; APPROVE by OWNER or explicitly-authorized ADMIN/ACCOUNTANT applies return exactly once; REJECT none. OWNER direct return remains allowed. Direct ACCOUNTANT Return remains denied.
- Sales Return cannot exceed actually delivered less prior completed returns; Purchase Return cannot exceed received less prior completed returns, cannot drive stock negative, and active Purchase Requirement link blocks it.
- Canonical `inventory_movements` reconciles Purchase receipt + Delivery + authorized Return effects.
- No direct client write bypass and no secret exposure.

Run staging checklists: `tests/v2-purchase-entry-security-checklist.sql`, `tests/v2-purchase-requirement-security-checklist.sql`, `tests/v2-sales-delivery-integrity-checklist.sql`, `tests/v2-maker-checker-approval-checklist.sql`, `tests/v2-backup-control-security-checklist.sql`. Add dedicated public-retail checkout security tests before production enablement.

## CLEAN PRODUCTION RULE
Development preview/test/migration artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures. Before release, perform dependency-aware code/database cleanup. Never delete an old table/function/file merely because its name looks unused; prove dependencies and preserve migration/audit history needed for recovery.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, public price/payment idempotency evidence, exactly-once Purchase/payment/Delivery/Return evidence, approval evidence, backup checksum/manifest and clean restore drill. No runtime-verified claim without this evidence.
