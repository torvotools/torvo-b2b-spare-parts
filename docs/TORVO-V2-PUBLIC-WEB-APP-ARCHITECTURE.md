# TORVO V2 — WEBSITE + ROLE APP + DESKTOP ARCHITECTURE

Current approved architecture: 19-09-2026

## CORE MODEL
TORVO V2 is ONE business platform over ONE authoritative backend/database:
1. PUBLIC WEBSITE = TORVO identity + public product discovery + Customer-to-Dealer referral + requirement capture + Dealer registration + support.
2. TORVO APP = private daily operational workspace for approved DEALER, SALESMAN and STORE KEEPER.
3. SECURE DESKTOP = OWNER / ADMIN and ACCOUNTANT control workspace.

The interfaces are role-separated; business truth is not duplicated into parallel databases or competing logic.

## PUBLIC WEBSITE — FINAL CUSTOMER MODEL
The public Website does NOT sell directly to the normal public Customer and does NOT show TORVO public selling prices.

Canonical flow:
`PRODUCT SEARCH -> PRODUCT SELECT -> FIND NEARBY DEALER -> CUSTOMER NAME + MOBILE/WHATSAPP + PIN/MINIMUM LOCATION -> ELIGIBLE NEARBY DEALERS -> DEALER PROFILE -> CALL/WHATSAPP/MAP/SEND REQUIREMENT -> CUSTOMER AND DEALER COMPLETE THEIR COMMERCIAL TRANSACTION DIRECTLY.`

Rules:
- No public TORVO retail price, Dealer A/B/C rate, Dealer purchase rate, scheme or private commercial data.
- No normal TORVO public cart, checkout, COD, payment or refund transaction.
- Customer and Dealer decide retail price, payment and delivery directly.
- Product identity travels with the referral/requirement.
- Nearby results use verified Dealer service/location data; never fabricate distance, stock, availability or authorization.
- Only approved/active referral-enabled Dealers with verified customer-facing data are eligible.
- If no suitable Dealer is available, offer TORVO support / SEND REQUIREMENT rather than a fake result.
- PRODUCT SALES and REPAIR & SERVICE capabilities may be shown when verified. Brand-authorized service wording requires actual verified authorization.

## CUSTOMER DATA + CONSENT
Collect only useful referral fields. Customer/referral history is protected and must not be publicly enumerable.
Promotional WhatsApp/SMS consent is separate from service/referral consent. Store opt-in status/source/time and opt-out status. Respect STOP/UNSUBSCRIBE. Do not claim a message was delivered unless provider/server state confirms it.

## DEALER B2B APP
Dealer onboarding starts on the Website:
`REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> APP ACCESS`.

Private Dealer flow:
`SEARCH -> SERVER DEALER RATE -> PURCHASE ORDER -> TORVO SALES ORDER/REVISION -> DEALER OK -> ESTIMATE -> PAYMENT/FULFILMENT -> DELIVERY/TRACKING`.

Dealer A/B/C rates, quantity slabs, schemes/rewards, order history, messages and referral operations remain private. TORVO revision invalidates an old Dealer OK. ADD MORE ITEMS creates a separate linked Additional Purchase Order after approval and never mutates the original order/Estimate.

## SALESMAN APP
Only mapped/authorized field and sales workflows. Attendance and role identity are server-bound. No client-selected role or unauthorized Dealer/accounting data.

## STORE KEEPER APP
Only authorized stock, pick, pack and dispatch workflows. Unauthorized financial/cost/profit data remains hidden.

## SECURE DESKTOP
OWNER / ADMIN and ACCOUNTANT use secure Desktop/Laptop access for their authorized controls. This includes approvals, accounting/payment controls, reports, users/roles, catalog/master configuration, Dealer referral/location/service verification, Customer/referral CRM, consent/audit and backup/recovery. Desktop-only presentation is not the security boundary; server authorization is mandatory.

## ROLE ROUTING
- DEALER -> DEALER APP.
- SALESMAN -> SALESMAN APP.
- STORE KEEPER -> STORE APP.
- OWNER / ADMIN -> SECURE DESKTOP.
- ACCOUNTANT -> SECURE DESKTOP ACCOUNTING.
- inactive/blocked/unauthorized identity -> NO PRIVATE WORKSPACE.

Role is derived from authoritative server identity/session data, never a user-selected role button.

## SESSION + DEVICE SECURITY
Dealer private access is app-only and device-bound. Staff access follows the approved one-time-password/device policy. Logout, expiry, revoke, blocked/inactive status, suspicious/new device, PIN reset and defined security events must invalidate or re-verify access as specified by the auth contract. WhatsApp OTP is used only when the real provider path is configured and verified.

## ONE AUTHORITATIVE PLATFORM
Website, App and Desktop share one authoritative backend. Product, Dealer, Customer/referral, inventory, order, payment and audit records must not become conflicting duplicates. Backup/restore and release evidence remain centralized.

## RETIRED — DO NOT ENABLE
The superseded TORVO-direct public retail foundation is not part of the approved release:
- public retail selling-price flow;
- public cart/checkout;
- FULL PREPAID public checkout;
- LOGISTICS ADVANCE / balance-on-delivery public checkout;
- routine TORVO public return/refund transaction flow.

Historical migration/recovery evidence may remain, but retired public pricing/checkout migrations must stay excluded from the active install path. Never re-enable them from this document.

## DELIVERY
TORVO-to-Dealer B2B rule remains: Spare Parts free delivery only when spare-parts subtotal is at least Rs 10,000; Machines and Accessories carry delivery charge. Public Customer delivery is a Customer/Dealer transaction and must not be confused with TORVO B2B delivery logic.

## APP DELIVERY
PWA/web-app foundation may support development/testing. Native Android/iOS reuse the same authoritative backend, role/security model and business rules. Do not create a second native business database or parallel business logic. Debug/test APK is not production; production requires signed release + real-device acceptance.

## DESIGN / UI CONTRACT
PUBLIC WEBSITE: premium TORVO identity, product discovery, FIND NEARBY DEALER, Dealer profile/contact/map, SEND REQUIREMENT, BECOME A DEALER and OPEN TORVO APP.
APP: mobile-first role-specific daily operations.
DESKTOP: compact professional keyboard/mouse control, finance and reporting.
Preserve registered UI locks. Current LOCK 1 protects the approved public top contact strip.

## SECURITY PRINCIPLE
PUBLIC WEBSITE != DEALER AUTHORIZATION.
APP INSTALLATION != AUTHORIZATION.
DESKTOP DEVICE != AUTHORIZATION.
CLIENT-SENT ROLE/RATE/FINANCIAL VALUE != AUTHORITATIVE BUSINESS TRUTH.
SERVER-VERIFIED IDENTITY + DEVICE/SESSION + ROLE + PERMISSION + BUSINESS RULES = AUTHORIZATION.

## SOURCES OF TRUTH
- Business/architecture master: `docs/TORVO-V2-MASTER-HANDOVER.md`.
- Database dependency order: `supabase/V2_INSTALL_ORDER.md`.
- Runtime acceptance: `docs/TORVO-V2-STAGING-ACCEPTANCE.md`.
- Release gates: `docs/TORVO-V2-RELEASE-GATES.md`.
- Portable restore: `docs/TORVO-V2-PORTABLE-RESTORE-RUNBOOK.md`.
- Environment names/boundaries: `docs/TORVO-V2-ENVIRONMENT-INVENTORY.md`.
