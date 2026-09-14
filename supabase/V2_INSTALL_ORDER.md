# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## LOCKED BUSINESS ARCHITECTURE
- PUBLIC CUSTOMER HAS NO TORVO RETAIL PRICE, CHECKOUT, COD, PAYMENT OR PUBLIC RETURN FLOW.
- CUSTOMER DISCOVERS PRODUCTS -> PRICE-FREE ENQUIRY -> APPROVED DEALER; CUSTOMER AND DEALER FINALIZE RETAIL RATE/PAYMENT/DELIVERY.
- DEALER PROCUREMENT REMAINS PRIVATE B2B WITH A/B/C RATE GROUPS.
- WEBSITE, ONE APP AND SECURE DESKTOP USE ONE AUTHORITATIVE BACKEND.
- ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION AT A TIME.
- SALESMAN / STORE KEEPER / ACCOUNTANT DO NOT REQUIRE A MOBILE NUMBER FOR NORMAL LOGIN. ADMIN ASSIGNS USERNAME + EMPLOYEE NAME + ONE-TIME PASSWORD.
- SALESMAN / STORE KEEPER PASSWORD IS CONSUMED ON FIRST SUCCESSFUL LOGIN; THE APPROVED MOBILE APP SESSION MAY CONTINUE UNTIL LOGOUT/REVOKE. AFTER LOGOUT/REINSTALL/DEVICE CHANGE A NEW ADMIN-ISSUED PASSWORD IS REQUIRED.
- ACCOUNTANT IS DESKTOP-ONLY AND REQUIRES AN ADMIN-ISSUED ONE-TIME PASSWORD FOR EACH NEW LOGIN SESSION.
- STAFF PASSWORD SHARING ALONE MUST NEVER AUTHORIZE ANOTHER DEVICE. NEW STAFF DEVICE REQUIRES OWNER/ADMIN DEVICE APPROVAL; APPROVING A REPLACEMENT DEVICE REVOKES THE PREVIOUS DEVICE.
- OWNER/ADMIN RECOVERY REMAINS SEPARATE FROM EMPLOYEE ONE-TIME ACCESS.
- MASTER SALESMAN IS AN EXPLICIT SERVER-SIDE GRANT. MASTER MAY SEE ALL APPROVED DEALERS; NORMAL SALESMAN REMAINS LIMITED TO ACTIVE DEALER MAPPINGS.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, plaintext passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Server derives authenticated role/user/dealer identity; never trust browser-supplied role/dealer identity.
- Staff temporary passwords are stored only as hashes and are atomically consumed on first successful login.

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
10. Private Suitable/fitment and Dealer/role privacy foundations.
11. CUSTOMER/DEALER NETWORK BASE and public referral/repair/registration/service-area/support foundations.
12. REFERRAL TO B2B BASE DEPENDENCIES.
13. FIELD/STORE ROLE BOUNDARIES: salesman field network -> dealer-salesman mapping foundation -> `v2-master-salesman-access.sql` -> store keeper boundary.
14. CENTRAL ADMIN CONTROL after delivery/settings/app users/audit dependencies.
15. PRODUCT DIGITAL CONTENT and public showcase.
16. PRODUCT/DRAFT MEDIA after app_users.
17. AUTH FOUNDATION: `v2-staff-whatsapp-auth.sql` (OWNER/ADMIN recovery/legacy transition only) -> `v2-admin-issued-staff-access.sql` -> `v2-dealer-pin-auth.sql` -> `v2-business-login-routing.sql` -> final Dealer device-bound migrations.
18. SECURE DESKTOP: audit `v2-secure-desktop-verification.sql` against Admin-issued Accountant desktop/device boundary before enabling.
19. BACKUP control -> channels -> worker contract.
20. DEMO RESET after backup/audit dependencies.
21. Dashboard/admin/business/reporting and later modules after prerequisites.

## MANDATORY STAFF ACCESS GATE
- `SM@01`-style username is Admin-managed and independent of employee mobile number.
- Employee name can be changed by Owner/Admin.
- Only one current unused one-time password; issuing another revokes previous.
- First successful password verification consumes it; replay fails.
- SALESMAN/STORE KEEPER = Admin-approved `mobile_app`; ACCOUNTANT = Admin-approved `desktop`.
- Replacement-device approval revokes previous device.
- Logout/revocation means next login needs a fresh Admin-issued one-time password.
- Trusted server establishes real Supabase Auth identity only after password + device verification.
- MASTER SALESMAN grant/revoke is Owner/Admin controlled and audited server-side.
- MASTER SALESMAN all-dealer visibility comes only from `salesman_visible_dealers()`; normal salesman receives only active mapped dealers.

## RETIRED / DO NOT ENABLE IN LOCKED PRODUCTION MODEL
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`

## MANDATORY GENERAL STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER.
- Public Website/Customer App cannot read Dealer Rate A/B/C, private fitment, purchase cost or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment.
- Staff credentials cannot create a browser-side auth bypass.
- Dealer PIN is hashed and one active Dealer device rule is enforced server-side.
- Dealer private RPCs require current active Dealer device proof.
- ONE APP routes by authoritative authenticated role.
- Purchase/payment/Delivery/Return integrity and maker-checker boundaries remain final authority.

## CLEAN PRODUCTION RULE
Development artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures.

## ANDROID / LIVE RELEASE GATE
- Exact release SHA Build Check must pass.
- Android artifact must install/open on a real Android device before production-ready claim.
- Debug APK is TEST ONLY; public release requires private signing and signed AAB/APK.
- External WhatsApp provider is still required for OWNER/ADMIN recovery or explicitly retained WhatsApp flow.
- Custom domain/DNS only after final verified production deployment.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exact web build/deploy SHA, Android artifact and real-device test evidence. No final-live claim without it.
