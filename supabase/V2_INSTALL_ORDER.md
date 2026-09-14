# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## LOCKED BUSINESS ARCHITECTURE
- PUBLIC CUSTOMER HAS NO TORVO RETAIL PRICE, CHECKOUT, COD, PAYMENT OR PUBLIC RETURN FLOW.
- CUSTOMER DISCOVERS PRODUCTS -> PRICE-FREE ENQUIRY -> APPROVED DEALER; CUSTOMER AND DEALER FINALIZE RETAIL RATE/PAYMENT/DELIVERY.
- DEALER PROCUREMENT REMAINS PRIVATE B2B WITH A/B/C RATE GROUPS.
- WEBSITE, ONE APP AND SECURE DESKTOP USE ONE AUTHORITATIVE BACKEND.
- ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION AT A TIME.
- SALESMAN / STORE KEEPER / ACCOUNTANT NORMAL LOGIN = ADMIN USERNAME + ONE-TIME PASSWORD; NO EMPLOYEE MOBILE REQUIRED.
- SALESMAN / STORE KEEPER PASSWORD IS CONSUMED ON FIRST LOGIN; APPROVED APP SESSION CONTINUES UNTIL LOGOUT/REVOKE. NEXT LOGIN NEEDS A NEW ADMIN PASSWORD.
- ACCOUNTANT IS DESKTOP-ONLY AND NEEDS A NEW ADMIN-ISSUED ONE-TIME PASSWORD FOR EACH NEW LOGIN SESSION.
- NEW STAFF DEVICE REQUIRES OWNER/ADMIN APPROVAL; REPLACEMENT DEVICE REVOKES PREVIOUS DEVICE.
- MASTER SALESMAN IS EXPLICIT SERVER-SIDE GRANT; NORMAL SALESMAN IS MAPPED-ONLY.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, plaintext passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- `SUPABASE_SERVICE_ROLE_KEY` exists only as a Supabase Edge Function secret/environment variable.
- Server derives authenticated role/user/dealer identity; never trust browser-supplied role/dealer identity.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql`, role/profile/dealer-link and base RLS/security dependencies.
2. CATALOG: catalog/item/master/rate/search foundations + dependent RPCs.
3. SALES: sales/order foundations -> `v2-sales-order-integrity.sql` -> `v2-additional-purchase-order.sql`.
4. PURCHASE + INVENTORY: inventory + canonical movement and final Purchase integrity migrations.
5. PURCHASE REQUIREMENTS: base -> RPC -> item link -> fulfilment -> receipt integrity.
6. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`.
7. RETURNS BASE after Delivery + received Purchase integrity.
8. CENTRAL MAKER-CHECKER and final approval boundaries.
9. Inventory movement, low-stock/reorder, Purchase Cost History/reporting read layers.
10. Private Suitable/fitment and Dealer/role privacy foundations, including `v2-knowledge-rewards.sql` base.
11. CUSTOMER/DEALER NETWORK BASE and public referral/repair/registration/service-area/support foundations.
12. REFERRAL TO B2B BASE DEPENDENCIES.
13. FIELD/STORE: salesman field network -> dealer-salesman mapping -> `v2-master-salesman-access.sql` -> store keeper boundary.
14. CENTRAL ADMIN CONTROL.
15. PRODUCT DIGITAL CONTENT and public showcase.
16. PRODUCT/DRAFT MEDIA after app_users.
17. AUTH: `v2-staff-whatsapp-auth.sql` -> `v2-admin-issued-staff-access.sql` -> `v2-dealer-pin-auth.sql` -> `v2-auth-worker-runtime-grants.sql` -> `v2-business-login-routing.sql`.
18. FINAL DEALER DEVICE BOUNDARIES after auth assertion exists: `v2-dealer-catalog-search.sql` -> `v2-dealer-machine-spares.sql` -> `v2-dealer-missing-part-request.sql` -> `v2-customer-dealer-referral-network.sql` -> `v2-referral-to-b2b-order-conversion.sql` -> `v2-dealer-knowledge-device-bound.sql` -> `v2-dealer-order-device-bound.sql` -> `v2-dealer-procurement-device-bound.sql`.
19. DEPLOY AUTH EDGE FUNCTIONS only after DB auth boundary: `_shared/torvo-auth.ts`, `dealer-pin-login`, `dealer-session-valid`, `dealer-session-revoke`, `staff-one-time-login`. Configure server secrets only.
20. SECURE DESKTOP verification against Accountant desktop/device boundary.
21. BACKUP control -> channels -> worker contract.
22. APP RELEASE CENTER: `v2-app-release-center.sql`; release metadata writes remain CI/trusted-worker only and Owner/Admin can read verified release status.
23. DEMO RESET after backup/audit dependencies; Dashboard/admin/business/reporting and later modules after prerequisites.

## MANDATORY DEALER DEVICE GATE
- Dealer item-rate resolution and Purchase Order submission require current device proof server-side; browser cannot select another Dealer/rate group.
- Purchase Order quantities are integer 1..9999 and duplicate catalog item lines fail.
- Machine-spare, fitment, referral, missing-part and protected order actions require current device proof.
- Sales Order confirmation, Additional Purchase Order request and 30-day order history require current device proof.
- Legacy no-device signatures must be absent after final migrations.
- Revoked old mobile must fail every protected Dealer mutation/read even while its Supabase Auth token has not yet expired.

## MANDATORY STAFF ACCESS GATE
- `SM@01`-style username is Admin-managed and independent of employee mobile number.
- Only one current unused one-time password; issuing another revokes previous.
- SALESMAN/STORE KEEPER = approved `mobile_app`; ACCOUNTANT = approved `desktop`.
- Logout/revocation means next login needs a fresh Admin-issued password.
- MASTER SALESMAN grant/revoke is Owner/Admin controlled and audited server-side.

## RETIRED / DO NOT ENABLE
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`

## MANDATORY GENERAL STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER.
- Public cannot read Dealer Rate A/B/C, private fitment, purchase cost or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment.
- Dealer PIN is hashed and one active Dealer device rule is server-enforced.
- ONE APP routes by authoritative authenticated role.
- Purchase/payment/Delivery/Return integrity and maker-checker remain final authority.

## APP RELEASE GATE
- Owner/Admin APP RELEASE tab reads release metadata through `admin_app_release_center()` only.
- Browser cannot write release metadata or mark an artifact verified.
- APK/AAB/iOS download is shown only when status is VERIFIED/PUBLISHED and a trusted artifact URL exists.
- DATA/CONTENT changes flow from the central backend without native reinstall; PROGRAM/CODE changes require a new verified native release.

## ANDROID / LIVE RELEASE GATE
- Exact release SHA Build Check must pass.
- Android artifact must install/open on a real Android device before production-ready claim.
- Debug APK is TEST ONLY; public release requires private signing and signed AAB/APK.
- External provider credentials and custom domain/DNS remain deployment gates.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exact web build/deploy SHA, Android artifact and real-device test evidence. No final-live claim without it.
