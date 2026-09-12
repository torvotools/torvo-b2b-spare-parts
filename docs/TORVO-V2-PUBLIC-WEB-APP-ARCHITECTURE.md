# TORVO V2 — WEBSITE + ROLE APP + DESKTOP ARCHITECTURE

Approved direction: 12-09-2026

## CORE MODEL
TORVO has three clearly separated experiences over ONE authoritative backend/database:
1. PUBLIC WEBSITE = TORVO identity + public retail e-commerce + discovery + inquiry + Dealer registration.
2. TORVO APP = daily operational workspace for approved DEALER, SALESMAN and STORE KEEPER (and future mobile operational roles explicitly authorized by Owner).
3. SECURE DESKTOP = OWNER / ADMIN and ACCOUNTANT control workspace.
The interfaces are separate. Authoritative business data is not duplicated into conflicting databases.

## PUBLIC WEBSITE + RETAIL CUSTOMER
The website is public and may be viewed by anyone, including Dealers. Existing staff/Dealers may read public information, but internal daily business, private Dealer rates, accounting, stock-control and Admin controls are not performed through it.
Public website purpose includes ABOUT TORVO, MACHINE -> SPARE PART -> ACCESSORY catalog/search, HIGH PUBLIC CUSTOMER RETAIL PRICE, CART/BUY, SEND REQUIREMENT, DEALER REGISTRATION and SUPPORT.

## PUBLIC CUSTOMER PRICE VS DEALER PRICE — FINAL COMMERCIAL RULE
PUBLIC E-COMMERCE CUSTOMER RATE IS THE HIGHER RETAIL SELLING RATE and is separate from private Dealer Rate A/B/C. Public promotions must not accidentally undercut the protected Dealer commercial price. Dealer quantity slabs, schemes/rewards and private B2B commercial data remain private. Browser/client supplied price, discount, rate class or final amount is never authoritative.

### PRICE SAFETY RULE
For the same comparable product and quantity/tax basis, checkout pricing must validate the active PUBLIC CUSTOMER RATE against the protected Dealer price rule. Invalid pricing configuration fails safely for Admin correction; no fake fallback price is permitted.

## PUBLIC RETAIL PAYMENT MODES — FINAL DIRECTION
The public checkout supports two controlled payment modes when enabled by Owner/Admin:

### 1. FULL PREPAID
PUBLIC CATALOG -> CART -> DELIVERY ADDRESS -> SERVER FINAL TOTAL -> FULL ONLINE PAYMENT -> SERVER/PROVIDER PAYMENT VERIFICATION -> ORDER CONFIRMED -> PICK -> PACK -> DISPATCH -> DELIVERY.

### 2. LOGISTICS ADVANCE + BALANCE ON DELIVERY
This is not zero-advance COD. The Customer must first pay a server-calculated LOGISTICS ADVANCE before the order can enter fulfilment. The remaining authorized order balance may then be collected on delivery through the supported collection method.

The logistics advance is intended to protect TORVO against applicable forward and return-to-origin logistics exposure if a Customer refuses/does not accept the shipment. Owner/Admin can configure the commercial calculation by supported rules such as product class, weight/value, destination/serviceability or other verified logistics inputs.

The checkout must clearly disclose before payment:
- LOGISTICS ADVANCE payable now;
- BALANCE payable on delivery;
- the applicable cancellation/refusal/RTO treatment;
- that normal Customer refusal/non-acceptance may cause applicable logistics advance to be retained against logistics cost;
- statutory/TORVO-fault exceptions remain controlled separately.

No UI may label this mode as free/zero-advance COD. No order may enter the applicable fulfilment state until the required advance payment is authoritatively verified.

## PAYMENT INTEGRITY
Payment button clicks, redirects or client success messages are not proof of payment. Full payment and logistics advance payments must be verified server-side and handled idempotently. Duplicate provider callbacks/retries must not create duplicate orders, duplicate payment credit or duplicate inventory effects.

The system stores separately: order merchandise amount, tax where applicable, forward delivery/logistics charge, protected logistics advance, amount paid online, balance due on delivery, payment mode, payment verification reference/status, and RTO/exception treatment where applicable.

## RTO / REFUSAL / REFUND CONTROL
Normal Customer refusal/non-acceptance may use the paid logistics advance against applicable forward + return logistics cost according to the disclosed policy. The system must not automatically promise a refund merely because the parcel returned.

However, 'non-refundable' is not an unconditional technical override of law or TORVO responsibility. Admin-controlled exception/refund handling remains available for TORVO cancellation/non-supply, duplicate payment, wrong shipment, verified damage/defect, legally required remedies or other approved cases. Every exception/refund must be auditable.

## PUBLIC RETAIL RETURN / EXCEPTION POLICY
Normal public e-commerce UI does NOT show a routine RETURN button/no-reason return workflow. A controlled CLAIM / EXCEPTION route remains for wrong item, transit damage, verified defect, duplicate payment/shipment, TORVO fault or applicable legal obligation. Final policy text at launch must match applicable law and actual warranty/claim rules.

## VISITOR / QUERY FLOW
A public inquiry never automatically becomes a Dealer account. TORVO may classify Customer/Retail Buyer, Retailer/Prospective Dealer or approved Dealer. A Customer who cannot find a product may use PUBLIC REQUIREMENT -> TORVO REVIEW -> REAL AVAILABILITY + HIGH CUSTOMER RETAIL QUOTE -> CUSTOMER CONFIRMATION -> APPROVED PAYMENT MODE -> VERIFIED PAYMENT/ADVANCE -> FULFILMENT. No fake availability, rate, payment or delivery state.

## TORVO APP — OPERATIONAL ROLES
The TORVO App is an authenticated role-based business application, not the public Customer shopping website.
DEALER: WEBSITE REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> DEALER APP. Private Dealer Rates, Purchase Orders, Estimates, Additional Orders, Delivery/Tracking, Schemes/Rewards, requests/messages stay in the App.
SALESMAN: only authorized field/sales work.
STORE KEEPER: only authorized stock/warehouse Pick/Pack/Dispatch work. Financial/accounting data remains hidden.

## ROLE ROUTING
- DEALER -> DEALER APP WORKSPACE
- SALESMAN -> SALESMAN APP WORKSPACE
- STORE KEEPER -> STORE APP WORKSPACE
- OWNER / ADMIN -> SECURE DESKTOP WORKSPACE
- ACCOUNTANT -> SECURE DESKTOP ACCOUNTING WORKSPACE
- unauthorized/inactive/blocked identity -> NO PRIVATE WORKSPACE ACCESS
Role comes from authoritative identity/profile/permission data, never user-selected buttons.

## SESSION + DEVICE SECURITY
Operational App users use secure sessions. Logout, expiry, revoked access, suspicious/new device, PIN reset or defined security event may require re-verification. WhatsApp OTP remains preferred when a real provider is integrated and verified. Blocked/inactive users must not retain private access.

## SECURE DESKTOP — OWNER / ADMIN + ACCOUNTANT
Owner/Admin controls configuration, approvals, users/roles, Dealer approvals, public retail/payment/logistics settings, catalog/master controls, reports, backup/recovery and audit. Accountant receives only explicitly authorized accounting/payment/financial modules. Mobile/tablet may show ADMIN/ACCOUNTING ACCESS REQUIRES DESKTOP; server authorization remains the actual security boundary.

## ONE AUTHORITATIVE PLATFORM
Website, App and Secure Desktop share one authoritative backend. Customer, Dealer, product, inventory, order and payment records must not be conflicting duplicates. Centralized backup/restore remains mandatory.

## NOTIFICATIONS
Notifications are role-aware. Public Customer order/payment/dispatch notifications use authorized channels when implemented. Never claim provider delivery or payment success unless provider/server state confirms it.

## APP DELIVERY STRATEGY
Retain install-ready PWA/web-app foundation for development/testing. Native Android/iOS can reuse the same backend, role model and business logic after core stability. No duplicate business database.

## DESIGN RULES
PUBLIC WEBSITE: premium TORVO identity + retail e-commerce + requirement capture.
TORVO APP: fast mobile-first role-specific daily operational UI.
SECURE DESKTOP: professional keyboard/mouse cloud-business UI for control, finance and reporting.

## PRODUCT PRIORITY
MACHINE -> SPARE PART -> ACCESSORY. Private fitment/compatibility remains protected.

## SECURITY PRINCIPLE
PUBLIC WEBSITE != DEALER AUTHORIZATION.
APP INSTALLATION != AUTHORIZATION.
DESKTOP DEVICE != AUTHORIZATION.
CLIENT-SENT PRICE != FINAL PRICE.
PAYMENT REDIRECT != VERIFIED PAYMENT.
ZERO-ADVANCE COD != APPROVED TORVO PUBLIC FLOW.
SERVER-VERIFIED IDENTITY + CHANNEL + ROLE + PERMISSION + PRICE + PAYMENT + BUSINESS RULES = AUTHORIZATION AND COMMERCIAL TRUTH.
