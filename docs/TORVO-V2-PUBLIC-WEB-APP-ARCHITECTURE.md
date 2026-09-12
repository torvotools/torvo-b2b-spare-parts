# TORVO V2 — WEBSITE + ROLE APP + DESKTOP ARCHITECTURE

Approved direction: 12-09-2026

## CORE MODEL
TORVO has three clearly separated experiences over ONE authoritative backend/database:

1. PUBLIC WEBSITE = discovery, company information, public requirement/inquiry, Dealer registration and support.
2. TORVO APP = daily operational workspace for approved DEALER, SALESMAN and STORE KEEPER (and any future mobile operational role explicitly authorized by Owner).
3. SECURE DESKTOP = OWNER / ADMIN and ACCOUNTANT control workspace.

The interfaces are separate. Authoritative business data is not duplicated into separate conflicting databases.

## PUBLIC WEBSITE
The website is public and may be viewed by anyone. Existing staff/Dealers are not technically blocked from reading public information, but NO internal daily business work, private rates, orders, accounting, stock-control or Admin controls are performed through the public website.

Public website purpose:
- ABOUT TORVO / trust / company information
- MACHINE -> SPARE PART -> ACCESSORY range discovery
- SEND REQUIREMENT / BUSINESS INQUIRY
- BECOME A DEALER / DEALER REGISTRATION
- CONTACT / SUPPORT
- authorized-role sign-in entry may redirect the user to the correct TORVO experience; the website itself does not become their business workspace.

A new visitor may submit a requirement without Dealer approval. Capture may include name, firm/shop, Mobile/WhatsApp, location, customer/business type, product type, product/model/item details, quantity, notes and photo where supported.

## VISITOR CLASSIFICATION
A public inquiry never automatically becomes a Dealer account. TORVO verifies/classifies the visitor as Customer/Retail Buyer, Retailer/Prospective Dealer or approved Dealer.

Dealer rates, Dealer schemes, private compatibility, internal stock/control data and other B2B-private information are never exposed by public inquiry submission.

## DIRECT NON-DEALER CUSTOMER SALE
A verified non-Dealer Customer can buy from TORVO without Dealer App access or Dealer pricing.

Controlled flow:
PUBLIC REQUIREMENT -> TORVO REVIEW -> REAL AVAILABILITY + FINAL QUOTE -> CUSTOMER CONFIRMATION -> AUTHORITATIVE PAYMENT CONFIRMATION -> DISPATCH/DELIVERY.

No fake availability, rate, payment success, dispatch or delivery state. Commercial truth remains server-authoritative.

## TORVO APP — OPERATIONAL ROLES
The TORVO App is an authenticated role-based business application, not a public shopping app.

### DEALER
DEALER REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> APP ACCESS.
Dealer App modules may include Product Search, private Dealer Rates, Purchase Orders, Estimates, Additional Orders, Delivery/Tracking, Schemes/Rewards, Missing Product Requests, Messages and supported notifications.

### SALESMAN
Salesman uses the App for only Owner/Admin-authorized field/sales work: mapped Dealers/areas, assisted orders, allowed sales workflows, requests/messages and other permitted operational actions. Salesman must never receive Owner-only profit/cost or Accountant-private controls merely because the App is installed.

### STORE KEEPER
Store Keeper uses the App for only authorized stock/warehouse operations such as stock lookup where permitted, Pick, Pack, Dispatch/Tracking and related operational tasks. Financial/accounting data remains hidden.

### ROLE ROUTING
The same App shell may serve multiple operational roles, but the UI and server permissions are role-specific. Hiding a button is not security. Every sensitive read/write must be authorized server-side.

After authenticated identity resolution:
- DEALER -> DEALER APP WORKSPACE
- SALESMAN -> SALESMAN APP WORKSPACE
- STORE KEEPER -> STORE APP WORKSPACE
- OWNER / ADMIN -> SECURE DESKTOP WORKSPACE
- ACCOUNTANT -> SECURE DESKTOP ACCOUNTING WORKSPACE
- unauthorized/inactive/blocked identity -> NO PRIVATE WORKSPACE ACCESS

Do not rely on user-selected role buttons as authorization. Role comes from authoritative identity/profile/permission data.

## SESSION + DEVICE SECURITY
Operational App users should have secure long-lived sessions for normal daily use. Logout, expiry, revoked access, suspicious/new device, PIN reset or defined security event may require re-verification. WhatsApp OTP remains preferred for onboarding/re-verification when a real provider is integrated and verified.

Role/access changes must take effect server-side even if an old App session exists. Blocked/inactive users must not retain private access.

## SECURE DESKTOP — OWNER / ADMIN + ACCOUNTANT
OWNER / ADMIN and ACCOUNTANT use the secure Desktop/Laptop workspace rather than the daily operational App.

Owner/Admin controls business configuration, approvals, users/roles, Dealer approvals, catalog/master controls, reports, backup/recovery, audit and other authorized management modules.

Accountant uses only accounting/payment/estimate/financial modules explicitly authorized for ACCOUNTANT. Owner-only confidential cost/profit or other restricted data remains permission-controlled.

Mobile/tablet can show an ADMIN/ACCOUNTING ACCESS REQUIRES DESKTOP gate for these workspaces. Device restriction is UX, not security. Real protection is authentication, server roles/permissions, protected RPC/API, secure sessions, audit and additional verification for sensitive actions.

## ONE AUTHORITATIVE PLATFORM
Website, App and Secure Desktop share one authoritative TORVO backend/business platform. Dealer, customer, product, inventory, order, payment and other authoritative records must not be maintained as conflicting duplicates.

Centralized backup/restore remains mandatory. GitHub code/migrations + verified database backup + restore manifest form disaster recovery.

## NOTIFICATIONS
App notifications are role-aware. Dealer may receive Estimate/action, order, dispatch/tracking, delivery, scheme/reward and relevant range notifications. Salesman and Store Keeper receive only operational notifications relevant to their permissions/work queue. Do not send financial/private notifications to unauthorized roles. Never claim provider delivery unless provider confirms it.

## APP DELIVERY STRATEGY
Retain install-ready PWA/web-app foundation for rapid development/testing. Native Android/iOS packaging can reuse the same backend, role model and business logic after core stability. Do not create duplicate native business logic or a second business database. Do not show fake store links.

## DESIGN RULES
PUBLIC WEBSITE: premium TORVO company identity; easy public discovery and requirement capture.
TORVO APP: fast mobile-first daily operational UI; role-specific first screen; minimal scrolling; large enough touch/text; offline-tolerant shell for non-critical catalog use where safe; never fake success for server-critical operations.
SECURE DESKTOP: dense professional cloud-business UI optimized for keyboard/mouse, wide screens, approvals, finance/control and reporting.

## PRODUCT PRIORITY
MACHINE -> SPARE PART -> ACCESSORY remains TORVO product priority. Private fitment/compatibility remains protected.

## SECURITY PRINCIPLE
PUBLIC WEBSITE != AUTHORIZATION.
APP INSTALLATION != AUTHORIZATION.
DESKTOP DEVICE != AUTHORIZATION.
SERVER-VERIFIED IDENTITY + ROLE + PERMISSION + BUSINESS RULES = AUTHORIZATION.
