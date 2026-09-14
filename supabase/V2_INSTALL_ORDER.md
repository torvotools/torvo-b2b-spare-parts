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
- OWNER/ADMIN RECOVERY REMAINS SEPARATE FROM EMPLOYEE ONE-TIME ACCESS. OWNER RECOVERY MUST USE VERIFIED OWNER RECOVERY CHANNELS; EMPLOYEES CANNOT USE IT.
- MASTER SALESMAN MAY HAVE ALL RETAILERS/DEALERS MAPPED; NORMAL SALESMAN REMAINS LIMITED TO ASSIGNED RETAILERS/AREA.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, plaintext passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- Server derives authenticated role/user/dealer identity; never trust browser-supplied role/dealer identity.
- Staff temporary passwords are stored only as hashes and are atomically consumed on first successful login.
- Admin may reset staff employee name, issue a replacement one-time password, approve a replacement device or revoke all staff access/sessions.

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
13. FIELD/STORE ROLE BOUNDARIES: salesman field network -> store keeper boundary.
14. CENTRAL ADMIN CONTROL after delivery/settings/app users/audit dependencies.
15. PRODUCT DIGITAL CONTENT and public showcase.
16. PRODUCT/DRAFT MEDIA after app_users.
17. AUTH FOUNDATION: `v2-staff-whatsapp-auth.sql` (retained for OWNER/ADMIN verified recovery/legacy transition only) -> `v2-admin-issued-staff-access.sql` -> `v2-dealer-pin-auth.sql` -> `v2-business-login-routing.sql` -> final Dealer device-bound referral/catalog/fitment/missing-part migrations. Do not enable WhatsApp OTP as normal SALESMAN/STORE KEEPER/ACCOUNTANT login after the Admin-issued access model is active.
18. SECURE DESKTOP: audit `v2-secure-desktop-verification.sql` against the Admin-issued Accountant desktop/device boundary before enabling. Do not operate competing Accountant login systems.
19. BACKUP control -> channels -> worker contract.
20. DEMO RESET after backup/audit dependencies.
21. Dashboard/admin/business/reporting and later modules after prerequisites.

## MANDATORY STAFF ACCESS GATE
- `SM@01`-style username is Admin-managed and independent of employee mobile number.
- Employee name can be changed by Owner/Admin without reusing another employee's active credentials.
- Only one unused, unrevoked one-time password may remain current for a staff ID; issuing another revokes the previous password.
- First successful password verification marks it used atomically; replay fails.
- SALESMAN and STORE KEEPER accept only an Admin-approved `mobile_app` device.
- ACCOUNTANT accepts only an Admin-approved `desktop` device.
- Replacement-device approval revokes the previous device before enabling the new one.
- Logout/revocation invalidates the staff session; next login requires a fresh Admin-issued one-time password.
- Admin `REVOKE STAFF ACCESS` revokes unused passwords, authorized device and active staff sessions together.
- Password hashes are never returned to client and plaintext passwords are never persisted.
- Trusted server must establish the real Supabase Auth identity/session only after one-time password + device verification succeeds.
- MASTER SALESMAN all-dealer visibility must be an explicit server-side permission/mapping, never a client-only switch.

## RETIRED / DO NOT ENABLE IN LOCKED PRODUCTION MODEL
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`

## MANDATORY GENERAL STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER.
- Public Website/Customer App cannot read Dealer Rate A/B/C, private fitment, purchase cost or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment.
- Staff credentials cannot create a browser-side auth bypass.
- Dealer PIN is hashed and one active Dealer device rule is enforced server-side.
- Dealer referral/catalog/fitment/missing-part private RPCs require current active Dealer device proof.
- ONE APP routes by authoritative authenticated role. Full Admin and Accountant stay Desktop/Laptop where required by locked role policy.
- Purchase/payment/Delivery/Return integrity and maker-checker boundaries remain final authority.
- No direct client write bypass and no secret exposure.

## CLEAN PRODUCTION RULE
Development artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures. Perform dependency-aware cleanup before release.

## ANDROID / LIVE RELEASE GATE
- Exact release SHA Build Check must pass.
- Android artifact must install/open on a real Android device before production-ready claim.
- Debug APK is TEST ONLY; public release requires private signing and signed AAB/APK.
- External WhatsApp provider is still required for OWNER/ADMIN recovery or any explicitly retained WhatsApp flow.
- Custom domain/DNS only after final verified production deployment.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exact web build/deploy SHA, Android artifact and real-device test evidence. No final-live claim without it.
