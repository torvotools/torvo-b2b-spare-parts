# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## LOCKED BUSINESS ARCHITECTURE
- PUBLIC CUSTOMER HAS NO TORVO RETAIL PRICE, CHECKOUT, COD, PAYMENT OR PUBLIC RETURN FLOW.
- CUSTOMER DISCOVERS PRODUCT -> FINDS APPROVED DEALER -> TORVO REFERRAL -> CUSTOMER AND DEALER FINALIZE RETAIL RATE/PAYMENT/DELIVERY.
- DEALER PROCUREMENT REMAINS PRIVATE B2B WITH A/B/C RATE GROUPS.
- WEBSITE, ONE APP AND SECURE DESKTOP USE ONE AUTHORITATIVE BACKEND; DO NOT CREATE DUPLICATE BUSINESS TABLES PER INTERFACE.
- ADMIN PANEL IS THE DAILY BUSINESS CONTROL CENTER. APP/WEBSITE READ CENTRAL SETTINGS.
- AI PRODUCT CONTENT IS ASSISTED DRAFT ONLY; ADMIN APPROVES CONTENT. AI NEVER AUTHORIZES COMPATIBILITY, OEM CLAIM, RATE OR STOCK.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Integrity migrations remain the final definition for overlapping transaction signatures.
- Server derives authenticated role/user/dealer identity; never trust a browser-supplied role or dealer identity.
- Never invent Dealer distance, Dealer local stock, authorization or compatibility.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql`, role/profile/dealer-link and base RLS/security dependencies.
2. CATALOG: catalog/item/master/rate/search foundations + dependent RPCs. Install compatibility/fitment foundation before public compatibility reads.
3. SALES: sales/order foundations -> `v2-sales-order-integrity.sql` -> `v2-additional-purchase-order.sql`.
4. PURCHASE + INVENTORY: inventory + canonical `inventory_movements` -> `v2-purchase-entry-rpcs.sql` -> `v2-inventory-purchase-guard.sql` -> `v2-purchase-entry-integrity.sql` -> `v2-purchase-atomic-save-receive.sql` -> `v2-purchase-buying-intelligence.sql`.
5. PURCHASE REQUIREMENTS: `v2-purchase-requirements.sql` -> `v2-purchase-requirement-rpcs.sql` -> `v2-purchase-requirement-item-link.sql` -> `v2-purchase-requirement-fulfilment.sql` -> `v2-purchase-requirement-receipt-integrity.sql`.
6. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`. Actual Delivery is the outbound sales stock deduction point under the existing B2B rule.
7. RETURNS BASE: `v2-sales-purchase-returns.sql` after Delivery + received Purchase integrity. These are controlled B2B/internal returns, not public Customer returns.
8. CENTRAL MAKER-CHECKER: `v2-maker-checker-approval.sql` -> `v2-maker-checker-payment-gate.sql` -> `v2-payment-approval-final-boundary.sql` -> `v2-approval-permission-read.sql` -> `v2-purchase-approval-final-boundary.sql` -> `v2-return-approval-gate.sql` -> `v2-return-approval-checker-fix.sql`.
9. Inventory movement center, low-stock/reorder, Purchase Cost History/reporting read layers.
10. Private Suitable/fitment and Dealer/role privacy.
11. CUSTOMER/DEALER NETWORK: `v2-customer-dealer-referral-network.sql` -> `v2-referral-repair-routing.sql` -> `v2-validated-dealer-service-areas.sql` -> `v2-public-customer-referral-rpc.sql` -> `v2-public-repair-request-rpc.sql`.
12. REFERRAL TO B2B: `v2-referral-to-b2b-order-conversion.sql` after Sales Order + Dealer rate + inventory dependencies. It must reuse existing B2B Sales Order records and never expose private rate to Customer.
13. FIELD/STORE ROLE BOUNDARIES: `v2-salesman-field-network.sql` -> `v2-store-keeper-boundary.sql` after Dealer/referral/repair and dispatch dependencies.
14. CENTRAL ADMIN CONTROL: `v2-admin-central-control.sql` after delivery settings, portal settings, tax settings, app users and audit log exist.
15. PRODUCT DIGITAL CONTENT: `v2-product-digital-content.sql` after catalog items/app users/audit log. AI provider worker is external/server-side; provider secrets never enter browser/database content rows.
16. PRODUCT/DRAFT MEDIA: `v2-media-storage.sql` after `app_users`. Use the same Supabase project/storage. Product media is public-read catalog media; only active OWNER/ADMIN can write/delete. Never reuse this public bucket for private Customer repair media.
17. SECURE DESKTOP: `v2-secure-desktop-verification.sql` after app user/auth foundations. Production provider delivery/session hardening is mandatory before privileged live use.
18. BACKUP: `v2-backup-control.sql` -> `v2-backup-channels.sql` -> `v2-backup-worker-contract.sql`.
19. Dashboard/admin/business/reporting RPCs and later conversion/repacking/rewards/GST modules after prerequisites. Older overlapping transaction RPCs install before final integrity layers or are skipped after dependency audit.

## RETIRED / DO NOT ENABLE IN LOCKED PRODUCTION MODEL
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`
These are historical development migrations from an earlier public-retail direction. Do not install/enable their public retail behavior in the locked Dealer-referral production architecture. Preserve history until dependency audit proves safe archival/removal.

## MANDATORY STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER boundaries.
- ONE APP routes by authoritative authenticated role. Admin Mobile remains limited; full Admin and Accountant stay Desktop/Laptop as defined.
- Public Website/Customer App cannot read Dealer Rate A/B/C, Dealer schemes, private fitment, purchase cost, private inventory internals or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment. Referral does not become TORVO direct retail.
- Nearby Dealer search returns exact PIN or verified service area only; no fake KM/distance/local-stock claims.
- Public compatibility shows only Admin-verified PUBLIC VISIBLE mappings.
- Repair Customer contact/media remains protected; full contact is not broadcast to unassigned Dealers.
- Referral code creation/verification/redemption is idempotent and auditable; Customer benefit does not expose/store Dealer retail price.
- Referral -> ORDER FROM TORVO creates at most one linked B2B Sales Order and uses authenticated Dealer + private rate group server-side.
- PURCHASE ORDER -> SALES ORDER -> latest DEALER OK -> ESTIMATE; revision invalidates old OK; ADD MORE ITEMS separate.
- OWNER atomic Purchase SAVE & RECEIVE commits header/lines/receipt/movements/stock together; injected failure leaves none; exact retry idempotent.
- ADMIN Purchase submit creates PENDING APPROVAL and ZERO stock/header/receipt effect; approval applies exactly once; rejection applies none; direct Admin atomic Purchase rejects.
- Purchase Requirement links only received/unreversed stock and never duplicates inventory.
- ESTIMATE/PICKED/PACKED/READY never deduct; authoritative payment requirement + Actual Delivery deduct exactly once under applicable stock rule.
- Payment: OWNER direct allowed; ADMIN/ACCOUNTANT direct posting rejected; submit creates no payment; APPROVE creates exactly one; REJECT none; internal payment effect has no PUBLIC/anon/authenticated EXECUTE.
- Maker-checker: Owner can grant chosen active Admin/Accountant; unauthorized denied; self-approval default denied; explicit self-approval permission works; decided request cannot decide twice.
- ADMIN Sales/Purchase Return submit creates pending approval and ZERO stock effect; APPROVE by OWNER or explicitly-authorized ADMIN/ACCOUNTANT applies return exactly once; REJECT none. OWNER direct return remains allowed. Direct ACCOUNTANT Return remains denied.
- Sales Return cannot exceed actually delivered less prior completed returns; Purchase Return cannot exceed received less prior completed returns, cannot drive stock negative, and active Purchase Requirement link blocks it.
- Canonical `inventory_movements` reconciles Purchase receipt + Delivery + authorized Return effects.
- Central Admin settings changes require authorized Admin/Owner and audit reason; Customer App/Website read the same current backend values.
- Product AI draft cannot publish itself; only authorized Admin/Owner approval updates approved product content.
- Product Draft/Item photo upload is OWNER/ADMIN write-only and file type/size constrained; Customer repair media uses a separate PRIVATE bucket/policy before live enablement.
- No direct client write bypass and no secret exposure.

Run staging checklists: `tests/v2-purchase-entry-security-checklist.sql`, `tests/v2-purchase-requirement-security-checklist.sql`, `tests/v2-sales-delivery-integrity-checklist.sql`, `tests/v2-maker-checker-approval-checklist.sql`, `tests/v2-backup-control-security-checklist.sql`. Add dedicated referral/privacy/role-routing tests before production enablement.

## CLEAN PRODUCTION RULE
Development preview/test/migration artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures. Before release, perform dependency-aware code/database cleanup. Never delete an old table/function/file merely because its name looks unused; prove dependencies and preserve migration/audit history needed for recovery.

## ANDROID / LIVE RELEASE GATE
- GitHub `TORVO V2 Build Check` must pass on the exact release SHA.
- `TORVO V2 Android APK` must pass and its APK artifact must install/open on a real Android device before calling the App production-ready.
- Debug APK is TEST ONLY. Public release requires a private production signing key and a signed release AAB/APK; never commit signing keys/passwords to GitHub.
- Google Play publication requires the TORVO Google Play Developer account. This is an external account action, not a code/database dependency.
- WhatsApp OTP requires an approved WhatsApp provider/API and server-side credentials before production login OTP is enabled. Do not place provider secrets in browser code.
- AI PHOTO -> PRODUCT DETAIL requires an approved vision-capable AI API/server worker. Until connected, AI requests remain drafts/queued and never fake completed content.
- Custom domain/DNS must point to the verified production deployment only after final real-use testing.
- Supabase remains the preferred unified DB/Auth/Storage/backend platform; add another provider only when the capability genuinely requires it.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, referral privacy/idempotency evidence, exactly-once Purchase/payment/Delivery/Return evidence, approval evidence, backup checksum/manifest, clean restore drill, exact web build/deploy SHA, Android build artifact and real-device install result. No runtime-verified/final-live claim without this evidence.
