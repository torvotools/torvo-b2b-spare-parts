# TORVO V2 — PUBLIC WEBSITE + APP ARCHITECTURE

Approved direction: 12-09-2026

## PURPOSE
TORVO public website is primarily the public brand, discovery and onboarding surface. Day-to-day approved Dealer business is handled through the TORVO App. TORVO Admin is a separate secure Desktop/Laptop workspace.

## PUBLIC WEBSITE
The public website must clearly explain TORVO, its Machine -> Spare Part -> Accessory range, supported business model, contact/support and why a buyer or Dealer should work with TORVO.

Public actions:
- SEND REQUIREMENT / BUSINESS INQUIRY
- BECOME A DEALER / DEALER REGISTRATION
- DEALER LOGIN / OPEN TORVO APP
- CONTACT / SUPPORT

A new visitor may submit a requirement without Dealer approval. Requirement capture may include name, firm/shop, Mobile/WhatsApp, location, product type, product/model/item details, quantity, notes and photo where supported.

## VISITOR CLASSIFICATION
A public inquiry does not automatically become a Dealer account. TORVO verifies the inquiry and classifies the person/business appropriately, including normal Customer/Retail Buyer, Retailer/Prospective Dealer or approved Dealer.

Dealer rates, Dealer schemes and private B2B information must never be exposed merely because a public inquiry was submitted.

## DIRECT CUSTOMER SALE
A verified non-Dealer Customer may buy directly from TORVO without receiving Dealer App access or Dealer pricing.

Controlled flow:
PUBLIC REQUIREMENT -> TORVO REVIEW -> AVAILABILITY/FINAL QUOTE -> CUSTOMER CONFIRMATION -> PAYMENT -> DISPATCH/DELIVERY.

No fake availability, price, payment success or dispatch state may be shown. Final commercial values and payment state must come from authoritative server-side business logic.

## DEALER FLOW
DEALER REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> TORVO APP ACCESS.

Approved Dealer day-to-day business runs in the TORVO App, including product search, Dealer rates, Purchase Orders, Estimates, controlled additional orders, fulfilment/delivery status, schemes/rewards, missing-product requests, messages and supported notifications.

Dealer login should support a secure long-lived session so normal users are not forced to log in every visit. Logout, session expiry, security events, suspicious/new device, PIN reset or other defined risk conditions may require re-verification. WhatsApp OTP remains the preferred onboarding/re-verification channel when the real provider integration is available.

## NOTIFICATIONS
The App should support useful business notifications such as Estimate/approval actions, order status, payment-related business updates where Dealer-visible, dispatch/tracking, delivery, schemes/rewards and relevant new-range announcements. Notifications must be permission-based and must not claim delivery unless the notification provider confirms it.

## ADMIN
Admin is a separate Desktop/Laptop-focused secure workspace. Mobile/tablet presentation may block the full Admin business UI with an ADMIN ACCESS REQUIRES DESKTOP message.

Device/UI restriction is not a security boundary. Real Admin security remains server-side authentication, role/permission enforcement, protected RPC/API access, secure sessions, audit trails and additional verification for sensitive actions.

## ONE AUTHORITATIVE PLATFORM
Website, Dealer App and Admin are different interfaces over one authoritative TORVO backend/business platform. Dealer, product, order, inventory, payment and other authoritative business records must not be maintained as conflicting duplicate databases.

Backup/restore remains centrally controlled. GitHub code/migrations plus verified database backups and restore manifests form the disaster-recovery system.

## APP DELIVERY STRATEGY
Keep the current install-ready PWA/web-app foundation so development and testing are not blocked by app-store packaging. Native Android/iOS packaging can reuse the same backend/security/business rules after the core platform is stable. Approved Dealers should be strongly guided to OPEN/INSTALL TORVO APP for business use; no fake Play Store/App Store links.

## PUBLIC WEBSITE DESIGN RULE
The public homepage must feel like a premium TORVO company website, not an internal software dashboard. It should build trust quickly and make the main actions obvious: SEND REQUIREMENT, BECOME A DEALER and DEALER LOGIN / OPEN APP.

## PRODUCT PRIORITY
Machine -> Spare Part -> Accessory remains the TORVO product priority. Private fitment/compatibility rules remain protected and are not made public by this architecture.
