# TORVO V2 FINAL DEMO AND OPERATING RUNBOOK

This is the final owner-facing order for checking and learning the system. Do not switch the main production domain until the owner accepts the demo.

## 1. PUBLIC WEBSITE
Check mobile first, then desktop: header/search, CAMERA before MIC, search suggestions, MACHINE / SPARE PART / ACCESSORY discovery, compatible/suitable messaging, dealer registration, nearby dealer enquiry, CALL/WHATSAPP, and no public TORVO dealer selling rate.

## 2. DEALER LOGIN AND SECURITY
Register/approve a dealer, first login through WhatsApp OTP and 4-digit PIN setup, normal mobile + PIN login, forgot PIN, blocked/inactive behavior, suspicious/new-device verification, then prove one-device-only behavior by signing in on Device B and confirming Device A loses protected access.

## 3. DEALER B2B ORDER FLOW
Search product → enter quantity → server dealer rate → SUBMIT PURCHASE ORDER → TORVO prepares/revises SALES ORDER → dealer reviews exact revision → GIVE DEALER OK → ESTIMATE → fulfilment/dispatch → tracking → DELIVERY SUCCESSFUL. Also test MODIFY ORDER, REQUEST MODIFICATION and ADD MORE ITEMS. Old dealer OK must never survive a TORVO revision.

## 4. ADMIN / STAFF
Check Owner/Admin access, dealer approval, A/B/C dealer rates, quantity tiers, product masters, compatibility, purchase-cost privacy, staff roles, notifications, delivery/tracking, scheme/reward/referral screens, missing-range/opportunity data, reports and APP RELEASE CENTER. Staff must see only permitted functions.

## 5. BUSINESS LOGIC
Verify spare-parts free delivery only when spare-parts subtotal is ₹10,000 or more. Machines/accessories retain delivery charge. Verify duplicate-item blocking, server-calculated rates, no browser override of private rates, estimate revision locks, dealer inactivity warning, and private compatibility defaults.

## 6. BUTTON CHECK
Tap every visible primary/secondary/icon action on mobile and desktop. Buttons must use their real action names such as SAVE, SUBMIT, APPROVE, UPDATE, CONFIRM, DOWNLOAD or CANCEL; generic OK is not accepted. Disabled/busy/error/success states must be understandable and double-submit must be blocked.

## 7. UI CHECK
Check 360px-class mobile width and desktop: no horizontal overflow, no clipped text, no modal overflow, readable red/black/white/grey contrast, consistent headings, image refresh behavior, search caret/suggestions, card spacing, full-width VIEW DETAIL where specified, and English business labels in UPPERCASE where required.

## 8. ANDROID TEST
Use only the verified TEST prerelease for device testing. Confirm package `com.torvotools.app`, launch/login/search/order flow, one-device security and update-link behavior. TEST-DEBUG is not production signed and must never become the public production update.

## 9. PRODUCTION RELEASE
Only after staging acceptance: apply Supabase migrations in `supabase/V2_INSTALL_ORDER.md` order, deploy required Edge Functions/secrets, complete real-device tests, create production-signed Android APK/AAB with the same package/signing identity, publish durable production metadata, then move approved domain/DNS. iOS/TestFlight/App Store signing remains an external Apple release step.

## OWNER DEMO SEQUENCE
PUBLIC → DEALER REGISTRATION → ADMIN APPROVAL → DEALER LOGIN → PRODUCT SEARCH → PURCHASE ORDER → SALES ORDER → DEALER OK → ESTIMATE → DELIVERY/TRACKING → REPORTS → APP RELEASE → STAFF ROLES → SECURITY/ONE-DEVICE TEST → MOBILE/DESKTOP UI REVIEW.

Any failure found in this sequence is fixed on `torvo-v2-build` and rechecked before production approval.
