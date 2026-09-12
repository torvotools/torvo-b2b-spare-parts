# TORVO V2 — WEBSITE + ROLE APP + DESKTOP ARCHITECTURE

Approved direction: 12-09-2026

## CORE MODEL
TORVO has three clearly separated experiences over ONE authoritative backend/database:

1. PUBLIC WEBSITE = TORVO identity + public retail e-commerce + discovery + inquiry + Dealer registration.
2. TORVO APP = daily operational workspace for approved DEALER, SALESMAN and STORE KEEPER (and future mobile operational roles explicitly authorized by Owner).
3. SECURE DESKTOP = OWNER / ADMIN and ACCOUNTANT control workspace.

The interfaces are separate. Authoritative business data is not duplicated into conflicting databases.

## PUBLIC WEBSITE + RETAIL CUSTOMER
The website is public and may be viewed by anyone, including Dealers. Existing staff/Dealers may read the public website, but internal daily business, private Dealer rates, accounting, stock-control and Admin controls are not performed through it.

Public website purpose:
- ABOUT TORVO / trust / company information
- MACHINE -> SPARE PART -> ACCESSORY public catalog/search
- PUBLIC CUSTOMER RETAIL PRICE
- CART / BUY flow for public Customers where product is enabled for online retail sale
- SEND REQUIREMENT / BUSINESS INQUIRY
- BECOME A DEALER / DEALER REGISTRATION
- CONTACT / SUPPORT
- authorized-role sign-in may route to the correct private TORVO experience.

A visitor may submit a requirement without Dealer approval. Capture may include name, firm/shop, Mobile/WhatsApp, location, customer/business type, product type, product/model/item details, quantity, notes and photo where supported.

## PUBLIC CUSTOMER PRICE VS DEALER PRICE
Public Customer pricing and Dealer pricing are separate commercial channels.

PUBLIC CUSTOMER:
- sees only the public/retail selling price authorized for the website;
- never receives Dealer Rate A/B/C merely by creating an account or sending a query;
- never receives Dealer-only quantity slabs, private schemes/rewards or private B2B commercial data unless a future explicit business rule says otherwise.

DEALER:
- sees only their authorized Dealer pricing in the TORVO App after Dealer approval;
- Dealer Rate A/B/C, quantity pricing and schemes remain server-authoritative and private.

The browser/client must not be trusted to choose which price channel applies. Server-side identity/channel/business rules determine the final payable price.

## PUBLIC RETAIL E-COMMERCE FLOW — PREPAID
Normal online Customer sale flow:
PUBLIC CATALOG / SEARCH -> PRODUCT -> CART -> CUSTOMER + DELIVERY ADDRESS -> SERVER-CALCULATED FINAL TOTAL -> PAYMENT -> PAYMENT PROVIDER/SERVER VERIFICATION -> ORDER CONFIRMED -> PICK -> PACK -> DISPATCH -> DELIVERY.

NO CASH-ON-DELIVERY flow is assumed in this approved model. The order must not enter normal paid fulfilment until authoritative payment verification succeeds.

A payment button click, browser redirect or client success message is NOT proof of payment. Payment state must be verified server-side and processed idempotently so duplicate callbacks/retries cannot create duplicate paid orders or duplicate stock effects.

Stock reservation/deduction timing must be explicitly transactional and consistent with TORVO inventory rules. The UI must never show PAYMENT SUCCESS, ORDER CONFIRMED, DISPATCHED or DELIVERED without authoritative backend state.

## PUBLIC RETAIL RETURN / EXCEPTION POLICY
Normal public e-commerce UI does NOT show a routine RETURN button/return workflow under the approved TORVO commercial model.

However, the system must retain an Admin-controlled EXCEPTION / CLAIM path for cases TORVO is legally or commercially required to resolve, including wrong item supplied, transit damage, verified defect, duplicate shipment/payment issue or other applicable consumer/legal obligation. This exception path must not silently become a normal no-reason return feature.

Any final website policy text must remain consistent with applicable law and the actual product/warranty/claim rules in force at launch.

## VISITOR CLASSIFICATION
A public inquiry never automatically becomes a Dealer account. TORVO verifies/classifies the visitor as Customer/Retail Buyer, Retailer/Prospective Dealer or approved Dealer.

Dealer rates, Dealer schemes, private compatibility, internal stock/control data and other B2B-private information are never exposed by public inquiry submission.

## QUERY-TO-SALE FLOW
A Customer who cannot find the product or prefers an inquiry may use:
PUBLIC REQUIREMENT -> TORVO REVIEW -> REAL AVAILABILITY + CUSTOMER FINAL QUOTE -> CUSTOMER CONFIRMATION -> AUTHORITATIVE PAYMENT -> DISPATCH/DELIVERY.

The quote uses Customer commercial rules, not Dealer pricing. No fake availability, rate, payment success or delivery state.

## TORVO APP — OPERATIONAL ROLES
The TORVO App is an authenticated role-based business application, not the public Customer shopping website.

### DEALER
DEALER REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> APP ACCESS.
Dealer App modules may include Product Search, private Dealer Rates, Purchase Orders, Estimates, Additional Orders, Delivery/Tracking, Schemes/Rewards, Missing Product Requests, Messages and supported notifications.

### SALESMAN
Salesman uses the App for only Owner/Admin-authorized field/sales work: mapped Dealers/areas, assisted orders, allowed sales workflows, requests/messages and other permitted operational actions. Salesman never receives Owner-only profit/cost or Accountant-private controls merely because the App is installed.

### STORE KEEPER
Store Keeper uses the App for only authorized stock/warehouse operations such as stock lookup where permitted, Pick, Pack, Dispatch/Tracking and related operational tasks. Financial/accounting data remains hidden.

### ROLE ROUTING
The same App shell may serve multiple operational roles, but UI and server permissions are role-specific. Hiding a button is not security. Every sensitive read/write must be authorized server-side.

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

Owner/Admin controls business configuration, approvals, users/roles, Dealer approvals, Customer retail settings, catalog/master controls, reports, backup/recovery, audit and other authorized management modules.

Accountant uses only accounting/payment/estimate/financial modules explicitly authorized for ACCOUNTANT. Owner-only confidential cost/profit or other restricted data remains permission-controlled.

Mobile/tablet can show an ADMIN/ACCOUNTING ACCESS REQUIRES DESKTOP gate for these workspaces. Device restriction is UX, not security. Real protection is authentication, server roles/permissions, protected RPC/API, secure sessions, audit and additional verification for sensitive actions.

## ONE AUTHORITATIVE PLATFORM
Website, App and Secure Desktop share one authoritative TORVO backend/business platform. Customer, Dealer, product, inventory, order, payment and other authoritative records must not be maintained as conflicting duplicates.

Centralized backup/restore remains mandatory. GitHub code/migrations + verified database backup + restore manifest form disaster recovery.

## NOTIFICATIONS
App notifications are role-aware. Dealer may receive Estimate/action, order, dispatch/tracking, delivery, scheme/reward and relevant range notifications. Salesman and Store Keeper receive only operational notifications relevant to their permissions/work queue. Public Customer order notifications may be delivered through the authorized website/contact notification channel when implemented. Do not send private financial notifications to unauthorized roles. Never claim provider delivery unless provider confirms it.

## APP DELIVERY STRATEGY
Retain install-ready PWA/web-app foundation for rapid development/testing. Native Android/iOS packaging can reuse the same backend, role model and business logic after core stability. Do not create duplicate native business logic or a second business database. Do not show fake store links.

## DESIGN RULES
PUBLIC WEBSITE: premium TORVO company identity + fast retail product discovery + clean e-commerce purchase + requirement capture.
TORVO APP: fast mobile-first daily operational UI; role-specific first screen; minimal scrolling; readable touch targets/text; offline-tolerant shell only for safe non-critical functions; never fake success for server-critical operations.
SECURE DESKTOP: dense professional cloud-business UI optimized for keyboard/mouse, wide screens, approvals, finance/control and reporting.

## PRODUCT PRIORITY
MACHINE -> SPARE PART -> ACCESSORY remains TORVO product priority. Private fitment/compatibility remains protected.

## SECURITY PRINCIPLE
PUBLIC WEBSITE != DEALER AUTHORIZATION.
APP INSTALLATION != AUTHORIZATION.
DESKTOP DEVICE != AUTHORIZATION.
CLIENT-SENT PRICE != FINAL PRICE.
PAYMENT REDIRECT != VERIFIED PAYMENT.
SERVER-VERIFIED IDENTITY + CHANNEL + ROLE + PERMISSION + PRICE + PAYMENT + BUSINESS RULES = AUTHORIZATION AND COMMERCIAL TRUTH.
