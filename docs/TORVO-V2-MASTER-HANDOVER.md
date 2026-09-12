# TORVO V2 MASTER HANDOVER

Last updated: 12-09-2026
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## START HERE IN EVERY NEW CHAT
Continue actual development from `torvo-v2-build`. Fetch current repository state before changing anything. V27/main is old/live and MUST remain untouched. Do not merge/replace main without full verification plus explicit Owner permission. Work in large compatible batches where safe. Premium modern responsive UI is non-negotiable.

## FINAL PRODUCT STRUCTURE — OWNER APPROVED
TORVO V2 is one business platform with three role-separated experiences over one authoritative backend/database.

### 1. PUBLIC WEBSITE — CUSTOMER DISCOVERY + DEALER REFERRAL
For everyone: TORVO public Home Page, company/range discovery, MACHINE -> SPARE PART -> ACCESSORY search/catalog, SEND REQUIREMENT, BECOME A DEALER / Dealer Registration, Support and OPEN TORVO APP.

### FINAL PUBLIC CUSTOMER COMMERCIAL MODEL
TORVO Website does NOT sell directly to the normal public Customer and does NOT display public selling prices. Its job is to help a Customer find the required TORVO-listed product and route that Customer to a suitable nearby active TORVO Dealer.

Canonical Customer flow:
`PRODUCT SEARCH -> PRODUCT SELECT -> FIND NEARBY DEALER -> CUSTOMER NAME + MOBILE/WHATSAPP + PIN CODE/MINIMUM LOCATION -> NEARBY ACTIVE TORVO DEALERS -> DEALER PROFILE -> SALES/SERVICE FACILITIES + ADDRESS + MAP/DIRECTIONS + CALL/WHATSAPP + SEND PRODUCT REQUIREMENT -> CUSTOMER AND DEALER COMPLETE THE COMMERCIAL TRANSACTION DIRECTLY.`

Rules:
- No TORVO public retail price, Dealer A/B/C rate, Dealer purchase rate, scheme or private commercial data is shown on the public Website.
- No normal TORVO public cart/payment/COD/refund/return transaction is required for this referral model.
- Dealer and Customer decide final retail selling price, payment, delivery and retail transaction terms directly, subject to applicable law and their own transaction.
- Customer selects the product first; product identity should carry into the Dealer referral/requirement so the Dealer knows what the Customer is asking for.
- Nearby Dealer discovery must use reliable Dealer service location data. PIN code is the minimum Customer location input; distance/ranking must not be fabricated.
- Only active/approved Dealers opted into Customer referrals are eligible to appear.
- If no suitable nearby Dealer is available, offer CONTACT TORVO CUSTOMER CARE / SEND REQUIREMENT rather than a fake Dealer result.
- Dealer profile may expose approved customer-facing shop name, address, map/directions, call/WhatsApp and capabilities.
- Capabilities may include PRODUCT SALES and REPAIR & SERVICE. `AUTHORIZED SERVICE CENTER` or equivalent brand-authorized wording may be shown only when actual authorization has been verified/approved.
- Do not create a public price marketplace in the current release. Dealer price entry/min-max/fixed public pricing is intentionally deferred because TORVO's approved role is referral, not retail-price control.

### CUSTOMER DATA + REFERRAL CRM
The referral flow may save the minimum useful Customer data needed to serve and measure the referral, including name, mobile/WhatsApp, PIN code/location, selected product/requirement, referral timestamp and Dealer selected/contacted where available.

Customer data rules:
- Data collection must be clearly disclosed and minimized to useful fields.
- Product/dealer referral may use the data needed to complete the Customer's request.
- Promotional WhatsApp/SMS/marketing requires a clear separate opt-in/consent; do not silently convert referral consent into marketing consent.
- Store marketing consent status, consent timestamp/source and unsubscribe/opt-out status for auditability.
- Provide a practical STOP/UNSUBSCRIBE path and respect opt-out.
- Marketing may include genuine TORVO products, new machines, schemes/updates and nearby Dealer calls-to-action; avoid excessive messaging.
- Referral analytics should let TORVO understand which products/areas generate demand and which Dealers receive Customer referrals without requiring TORVO to capture the Dealer's private final sale price.
- Customer data and referral history are protected business/customer data; access must be role-authorized and not publicly enumerable.

### DEALER BENEFIT
The Website is designed to generate and retain demand for the TORVO Dealer network. TORVO helps Dealers by discovering Customers, routing product-specific leads to nearby Dealers and periodically bringing opted-in Customers back to the Dealer network. Dealer B2B purchasing from TORVO remains private and separate.

### RETIRE SUPERSEDED DIRECT-CHECKOUT FOUNDATION
Earlier source foundations for TORVO-direct public retail pricing, FULL PREPAID and LOGISTICS ADVANCE checkout are superseded by the approved Dealer Referral model. Do NOT continue building them into production. Before final release, dependency-audit and safely retire/remove obsolete direct-public-checkout code/schema from the production migration path. Preserve migration/recovery history where needed; never delete blindly.

### 2. TORVO APP
After authorization, daily operational business is through the App:
- DEALER: private Dealer Rates, Product Search, Purchase Orders, Estimates, Additional Orders, Delivery/Tracking, Schemes/Rewards, Requests/Messages, Dealer customer-referral profile/location/service settings and incoming referral/requirement visibility when authorized.
- SALESMAN: only mapped/authorized sales and field workflows.
- STORE KEEPER: only authorized stock/Pick/Pack/Dispatch workflows.
- future operational roles only when explicitly authorized.
Dealer onboarding starts on the Website: REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> APP ACCESS.

### 3. SECURE DESKTOP/LAPTOP
OWNER / ADMIN and ACCOUNTANT use the secure Desktop/Laptop workspace for privileged controls, approvals, accounting/payment controls, reports, users/roles, catalog/master configuration, Dealer referral/location/service verification, Customer/referral CRM controls, consent/audit and backup/recovery. Desktop-only UX is not security; server-side authentication/permissions remain mandatory.

Canonical shorthand:
WEBSITE = PUBLIC HOME + PRODUCT DISCOVERY + CUSTOMER-TO-DEALER REFERRAL + REQUIREMENT + DEALER REGISTRATION.
APP = APPROVED DEALER + SALESMAN + STORE KEEPER + AUTHORIZED OPERATIONAL DAILY BUSINESS.
DESKTOP = OWNER/ADMIN + ACCOUNTANT CONTROL.

## NON-NEGOTIABLE SAFETY
- Remote `torvo-v2-build` is source of truth; fresh-fetch SHA before every write.
- V27/main remains untouched.
- No fake data/counts/rates/availability/distance/map/service authorization/WhatsApp sent states, secrets, insecure shortcuts or client-trusted financial rules.
- GitHub SQL is NOT runtime verified until executed/tested in Supabase staging.
- Dealer/private fitment, pricing and role financial privacy remain server-enforced.
- Public Customer data/referral history is protected; public endpoints must not expose an enumerable Customer/Dealer database.

## SALES FLOW — DEALER B2B
Purchase Order -> Sales Order -> controlled revision -> exact latest Dealer OK -> Estimate -> internal payment/fulfilment -> Delivery. Dealer rates are server-calculated. TORVO revision invalidates old Dealer OK. Estimate locks direct revision. ADD MORE ITEMS creates a separate linked Additional Purchase Order after TORVO approval and never mutates the original order/Estimate. Duplicate catalog item lines are blocked in UI and database integrity.

## DEALER PRIVACY
Dealer App shows no Owner-only confidential cost/profit. Private Suitable/cross-compatibility remains TORVO-private unless explicitly shared. Dealer pricing is never exposed through public referral. Final Customer/Dealer retail price is not required in TORVO referral analytics.

## PURCHASE / INVENTORY
Purchase Entry is the single supplier stock-receipt path. Owner/Admin enter Supplier + Invoice + items/qty/rate; duplicate Supplier+Invoice blocked. Save adds inventory exactly once and writes movement. Purchase correction uses audited reversal. Purchase Requirement never independently receives the same supplier stock. Purchase Rate History/Cost is Owner-only after save. Purchase Requirements support staff submission, Admin review, secure Item Master linking, partial/full Purchase fulfilment, exact Dealer allocation tracking and audited tracking reversal without stock duplication.

## UI / UX
Public Website: premium TORVO identity, fast public product discovery, FIND NEARBY DEALER, Dealer profile/map/contact/service capability, SEND REQUIREMENT, BECOME A DEALER and OPEN TORVO APP. No public price/payment UI in the approved referral release.
Dealer/staff App: premium mobile-first daily-use app UI, strong search/filter, popup/bottom-sheet secondary actions, readable touch targets/text, no horizontal overflow.
Secure Desktop: compact professional cloud-business UI optimized for keyboard/mouse and wide screens; main daily actions visible quickly.
Use action-specific button labels (SAVE, SUBMIT, APPROVE, UPDATE, CONFIRM, SEND, FIND NEARBY DEALER, GET DIRECTIONS, CALL DEALER, WHATSAPP DEALER, CANCEL, CLOSE); do not put OK on every button.
Main daily-use actions/status/search should fit the first screen where practical without microscopic text.

### ENGLISH DISPLAY CASE RULE
English business-facing UI text is UPPERCASE across TORVO V2. Case-sensitive/protocol/identity values are exceptions: EMAIL, PASSWORD/PIN, URL/WEBSITE, technical IDs, tokens/keys and similar machine-sensitive identifiers.

## DELIVERY
Existing TORVO-to-Dealer B2B delivery policy remains: Machines/Accessories delivery charge applies. Spare Parts delivery free only when spare-parts subtotal >= Rs 10,000. Public Customer retail delivery is between Customer and Dealer in the referral model and must not be confused with TORVO-to-Dealer B2B delivery rules.

## ROLES
OWNER full. ADMIN operational/admin but not Owner-only confidential cost/profit. SALESMAN mapped Dealer/area/order/sales. ACCOUNTANT secure desktop accounting/payment + authorized flows. STORE KEEPER stock/pick/pack/dispatch with no unauthorized financials. DEALER approved linked App. Compatibility/private Suitable Owner/Admin. Purchase Cost/Profit Owner-only.

## BACKUP & DISASTER RECOVERY
Website, App and Desktop share one authoritative backend; avoid conflicting duplicate business databases. Backup is a core Owner/Admin function. A backup request is not success: only trusted worker completion + integrity verification can mark it verified. Portable backup must be encrypted; secrets/passwords/service-role credentials are excluded. Full Restore Point carries DB backup + code branch/commit + schema version + checksum + restore manifest. GitHub code/migrations + verified DB backup + restore manifest together form disaster recovery. Restore must be staging-tested.

## WHATSAPP / OTP / SESSION
Dealer onboarding preference: WhatsApp OTP. TORVO support currently 7027751533, Admin-changeable. Automatic WhatsApp sending requires real provider/API + testing. Customer promotional WhatsApp requires separate recorded opt-in and opt-out handling. Approved operational App users should support secure long-lived sessions; logout, expiry, revoked/blocked access, suspicious/new device, PIN reset or defined security events may require re-verification.

## APP DELIVERY STRATEGY
Install-ready PWA/web-app foundation is retained for rapid development/testing. Native Android/iOS packaging can reuse the same backend, role/security model and business logic after core stability. Do not create duplicate native business logic/database or fake store links.

## CLEAN PRODUCTION RULE
Development preview/test/migration artifacts may exist while building, but final production must not carry unnecessary duplicate business logic/data structures. Before release, perform dependency-aware code/database cleanup. Never delete an old table/function/file merely because its name looks unused; prove dependencies and preserve migration/audit history needed for recovery. The superseded direct-public-checkout foundation is specifically included in this audit.

## MAJOR RELEASE BLOCKERS
- Supabase migration chain must be compiled/executed/tested in staging.
- Public Customer referral CRM + secure Dealer locator/location/serviceability backend must be built and staging-tested.
- Dealer customer-facing profile/location/map/service capability management and Admin verification must be built.
- Customer consent/marketing opt-in/opt-out audit flow must be built before promotional messaging.
- Authenticated role routing: Dealer/Salesman/Store Keeper -> App; Owner/Admin/Accountant -> Desktop; blocked/inactive -> no private access, then runtime-test it.
- WhatsApp OTP/provider, secure long-lived sessions and suspicious-device flow need runtime integration.
- Premium CSS layering/readability regression must be corrected safely.
- Browser alerts/confirms in remaining workspaces should become in-app validation/confirmation.
- Backup trusted worker/storage/export and actual restore drill remain.
- Exact current GitHub build + Netlify deploy SHA must be verified before calling a release live.

## FAST DEVELOPMENT PRIORITY — OWNER REQUESTED ASAP
Do not restart planning on every turn. Continue maximum safe compatible batches from current branch. Priority order:
1. Public Customer -> Dealer referral data model/RPCs: Customer capture, consent, product interest, Dealer referral event.
2. Dealer locator: approved referral participation, PIN/location/coordinates, service capabilities, safe public result projection and map/directions data.
3. Public Website PRODUCT -> FIND NEARBY DEALER -> DEALER PROFILE/CONTACT/REQUIREMENT UI.
4. Dealer App referral profile/settings + incoming referral/requirement workflow.
5. Desktop Customer/referral CRM + Dealer location/service verification controls.
6. Safely retire superseded direct-public-price/payment/checkout production path after dependency audit.
7. Complete/runtime-test authenticated role routing and Desktop gate.
8. CSS/readability/layering cleanup and removal of browser alerts/confirms.
9. Staging migrations/runtime tests, WhatsApp/session integration, responsive QA, backup restore drill.
10. Exact deploy verification, then domain/release transition with old site preserved as backup/reference.

## SQL INSTALL
`supabase/V2_INSTALL_ORDER.md` is authoritative. Never run migrations alphabetically. Update it to the Dealer Referral model before staging/production migration execution; superseded direct-public-checkout migrations must not be blindly applied.

## NEW CHAT RECOVERY INSTRUCTION
In a new chat, tell ChatGPT: `Continue TORVO V2 from docs/TORVO-V2-MASTER-HANDOVER.md on branch torvo-v2-build. Inspect current GitHub first. Never touch V27/main. Continue actual work in large safe batches and keep reports short.` This file plus current repository state is authoritative over old chat assumptions.
