# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## LOCKED BUSINESS ARCHITECTURE
- PUBLIC CUSTOMER HAS NO TORVO RETAIL PRICE, CHECKOUT, COD, PAYMENT OR PUBLIC RETURN FLOW.
- CUSTOMER DISCOVERS ONE OR MORE PRODUCTS -> PRICE-FREE ENQUIRY CART -> CUSTOMER/AREA DETAILS -> APPROVED DEALERS -> TORVO REFERRAL -> CUSTOMER AND DEALER FINALIZE RETAIL RATE/PAYMENT/DELIVERY.
- CUSTOMER ENQUIRY + DEALER CONTACT EVENTS ARE MEASURABLE FOR ADMIN. A CALL/WHATSAPP CLICK IS NOT A SALE; ONLY AN AUTHORIZED CONFIRMATION MAY BECOME `CONFIRMED_CONVERSION`.
- DEALER PROCUREMENT REMAINS PRIVATE B2B WITH A/B/C RATE GROUPS.
- WEBSITE, ONE APP AND SECURE DESKTOP USE ONE AUTHORITATIVE BACKEND; DO NOT CREATE DUPLICATE BUSINESS TABLES PER INTERFACE.
- ADMIN PANEL IS THE DAILY BUSINESS CONTROL CENTER. APP/WEBSITE READ CENTRAL SETTINGS.
- AI PRODUCT CONTENT IS ASSISTED DRAFT ONLY; ADMIN APPROVES CONTENT. AI NEVER AUTHORIZES COMPATIBILITY, OEM CLAIM, RATE OR STOCK.
- PUBLIC PRODUCT SHOWCASE READS THE SAME CENTRAL PRODUCT MASTER; ONLY ACTIVE + PUBLIC-VISIBLE + ADMIN-APPROVED CONTENT MAY APPEAR.
- ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION AT A TIME. SUCCESSFUL LOGIN ON A NEW MOBILE REVOKES THE PREVIOUS MOBILE SESSION.

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
6. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`.
7. RETURNS BASE: `v2-sales-purchase-returns.sql` after Delivery + received Purchase integrity.
8. CENTRAL MAKER-CHECKER: `v2-maker-checker-approval.sql` -> `v2-maker-checker-payment-gate.sql` -> `v2-payment-approval-final-boundary.sql` -> `v2-approval-permission-read.sql` -> `v2-purchase-approval-final-boundary.sql` -> `v2-return-approval-gate.sql` -> `v2-return-approval-checker-fix.sql`.
9. Inventory movement center, low-stock/reorder, Purchase Cost History/reporting read layers.
10. Private Suitable/fitment and Dealer/role privacy foundations. Do not install Dealer Missing Part RPC yet if it relies on authenticated Dealer identity.
11. CUSTOMER/DEALER NETWORK BASE: install customer/dealer referral tables and public referral/repair/registration/service-area/support foundations. Dealer-mutating referral RPC definitions are finalized again after Dealer Auth in step 17 so they can require the active device proof.
12. REFERRAL TO B2B BASE DEPENDENCIES: Sales Order + Dealer rate + inventory must exist. Final Dealer referral supply/order RPC definitions are installed after Dealer Auth in step 17.
13. FIELD/STORE ROLE BOUNDARIES: `v2-salesman-field-network.sql` -> `v2-store-keeper-boundary.sql` after Dealer/referral/repair and dispatch dependencies.
14. CENTRAL ADMIN CONTROL: `v2-admin-central-control.sql` after delivery settings, portal settings, tax settings, app users and audit log exist.
15. PRODUCT DIGITAL CONTENT: `v2-product-digital-content.sql` after catalog items/app_users/audit log -> `v2-public-product-showcase.sql` after approved digital-content fields exist.
16. PRODUCT/DRAFT MEDIA: `v2-media-storage.sql` after `app_users`. Product media is public-read catalog media; customer/dealer private media must use separate PRIVATE storage/policy.
17. AUTH + FINAL DEALER DEVICE BOUNDARIES: `v2-staff-whatsapp-auth.sql` -> `v2-dealer-pin-auth.sql` -> `v2-business-login-routing.sql` -> re-run `v2-customer-dealer-referral-network.sql` -> `v2-referral-to-b2b-order-conversion.sql` -> `v2-dealer-catalog-search.sql` -> `v2-dealer-machine-spares.sql` -> `v2-dealer-missing-part-request.sql`. The final Dealer referral/catalog/fitment/missing-part RPC signatures require `dealer_assert_my_device_session`; legacy unbound signatures must be absent. Dealer PIN trusted worker must verify PIN, start the single active device session, establish real Supabase Dealer identity and validate that device session for private Dealer access.
18. SECURE DESKTOP: audit `v2-secure-desktop-verification.sql` against `v2-staff-whatsapp-auth.sql` before enabling. Do not operate two competing privileged-login/session systems in production.
19. BACKUP: `v2-backup-control.sql` -> `v2-backup-channels.sql` -> `v2-backup-worker-contract.sql`.
20. DEMO RESET: install the OWNER-only demo/fresh-production reset foundation only after backup/audit dependencies.
21. Dashboard/admin/business/reporting RPCs and later conversion/repacking/rewards/GST modules after prerequisites.

## RETIRED / DO NOT ENABLE IN LOCKED PRODUCTION MODEL
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`

## MANDATORY STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER boundaries.
- Public Website/Customer App cannot read Dealer Rate A/B/C, Dealer schemes, private fitment, purchase cost, private inventory internals or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment.
- Customer enquiry can contain multiple approved products and stores only necessary contact/area/consent data.
- Public Dealer referral tracking accepts only PROFILE_VIEW, DEALER_SELECTED, CALL_CLICK, WHATSAPP_CLICK and DIRECTIONS_CLICK. Public caller can never write CONFIRMED_CONVERSION.
- Admin Dealer Referral Performance is OWNER/ADMIN only and reports referrals/contact attempts separately from confirmed conversions.
- Nearby Dealer search returns exact PIN or verified service area only; no fake KM/distance/local-stock claims.
- Public compatibility shows only Admin-verified PUBLIC VISIBLE mappings.
- Public Dealer registration creates only PENDING status and cannot self-approve.
- Public requirement/complaint creation cannot directly set Admin workflow status, linked product or resolution; PRODUCT ADDED/FULFILLED requires a real linked catalog product and RESOLVED/REJECTED complaints require an Admin resolution note.
- Staff OTP cannot be accepted until the external WhatsApp provider/server has actually verified it. Emergency access cannot create a browser-side auth bypass.
- Dealer PIN is exactly 4 digits but stored only as a strong hash; plaintext PIN never persists.
- Dealer account has at most one non-revoked device session; a new-device login revokes the prior device and the prior app must fail its next private-session validation.
- PIN change/recovery revokes any existing Dealer device session.
- Dealer referral verify, benefit confirmation, supply check and TORVO order creation require the current active device proof server-side; a revoked old mobile cannot bypass this with a still-valid Supabase auth session.
- ONE APP routes by authoritative authenticated role. Admin Mobile remains limited; full Admin and Accountant stay Desktop/Laptop.
- Public product showcase exposes only active + explicitly public-visible + Admin-approved content and safe catalog identity fields.
- Referral -> ORDER FROM TORVO creates at most one linked B2B Sales Order and uses authenticated Dealer + private rate group server-side.
- Purchase/payment/Delivery/Return integrity and maker-checker boundaries remain exactly as defined by their final integrity migrations.
- Product AI draft cannot publish itself; only authorized Admin/Owner approval updates approved product content.
- Demo reset must be OWNER-only, backup-first, dry-run/reportable and auditable.
- Dealer Missing Part creation rejects unapproved dealers, non-integer/out-of-range quantity, oversized fields and photo URLs until private media is connected; Dealer history is self-only.
- No direct client write bypass and no secret exposure.

Run staging checklists already in `tests/` and add dedicated customer-enquiry/referral-analytics/privacy tests before production enablement.

## CLEAN PRODUCTION RULE
Development preview/test/migration artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures. Before release, perform dependency-aware code/database cleanup.

## ANDROID / LIVE RELEASE GATE
- GitHub `TORVO V2 Build Check` must pass on the exact release SHA.
- `TORVO V2 Android APK` must pass and its APK artifact must install/open on a real Android device before calling the App production-ready.
- Debug APK is TEST ONLY. Public release requires a private production signing key and a signed release AAB/APK; never commit signing keys/passwords to GitHub.
- Google Play publication requires the TORVO Google Play Developer account.
- WhatsApp OTP requires an approved WhatsApp provider/API and server-side credentials before production staff OTP or Dealer PIN recovery is enabled.
- AI PHOTO -> PRODUCT DETAIL requires an approved vision-capable AI API/server worker.
- Custom domain/DNS must point to the verified production deployment only after final real-use testing.
- Supabase remains the preferred unified DB/Auth/Storage/backend platform; add another provider only when genuinely required.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, referral privacy/idempotency evidence, exact web build/deploy SHA, Android build artifact and real-device install result. No runtime-verified/final-live claim without this evidence.
