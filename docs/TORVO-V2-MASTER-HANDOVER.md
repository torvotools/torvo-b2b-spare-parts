# TORVO V2 MASTER HANDOVER

Last updated: 12-09-2026
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## START HERE IN EVERY NEW CHAT
Continue actual development from `torvo-v2-build`. Fetch current repository state before changing anything. V27/main is old/live and MUST remain untouched. Do not merge/replace main without full verification plus explicit Owner permission. Work in large compatible batches where safe; do not inflate task counts with cosmetic micro-edits. Keep progress reports compact. Premium modern responsive UI is non-negotiable.

## FINAL PRODUCT STRUCTURE — OWNER APPROVED
TORVO V2 is one business platform with three role-separated experiences over one authoritative backend/database.

### 1. PUBLIC WEBSITE
For everyone: TORVO public Home Page, company/range discovery, MACHINE -> SPARE PART -> ACCESSORY search/catalog, Direct Customer e-commerce, SEND REQUIREMENT, Dealer Registration and Support.

Direct Customer commercial model:
- PUBLIC E-COMMERCE CUSTOMER RATE is a separate HIGH retail rate and remains commercially above protected Dealer pricing for the same comparable commercial basis.
- Dealer Rate A/B/C, Dealer slabs/schemes and private B2B data are never exposed through public checkout.
- Two controlled payment modes may be enabled: FULL PREPAID, or LOGISTICS ADVANCE + BALANCE ON DELIVERY.
- There is no zero-advance COD.
- Required online payment/advance must be authoritatively verified before fulfilment.
- Logistics advance is intended to protect applicable forward/RTO logistics exposure when a Customer refuses/non-accepts delivery, subject to the disclosed policy and Admin/legal exceptions.
- No routine/no-reason RETURN button. Controlled CLAIM/EXCEPTION handling remains for wrong item, damage, verified defect, TORVO fault, duplicate payment/shipment or legally required remedy.
- Browser/client price, discount, payment-success message or role selection is never authoritative.

### 2. TORVO APP
After authorization, daily operational business is through the App:
- DEALER: private Dealer Rates, Product Search, Purchase Orders, Estimates, Additional Orders, Delivery/Tracking, Schemes/Rewards, Requests/Messages.
- SALESMAN: only mapped/authorized sales and field workflows.
- STORE KEEPER: only authorized stock/Pick/Pack/Dispatch workflows.
- future operational roles only when explicitly authorized.
Dealer onboarding starts on the Website: REGISTRATION -> TORVO VERIFICATION -> APPROVAL -> APP ACCESS.

### 3. SECURE DESKTOP/LAPTOP
OWNER / ADMIN and ACCOUNTANT use the secure Desktop/Laptop workspace for privileged controls, approvals, accounting/payment controls, reports, users/roles, catalog/master configuration, public retail/payment/logistics configuration, audit and backup/recovery. Desktop-only UX is not security; server-side authentication/permissions remain mandatory.

Canonical shorthand:
WEBSITE = PUBLIC HOME + DIRECT CUSTOMER E-COMMERCE/QUERY + DEALER REGISTRATION.
APP = APPROVED DEALER + SALESMAN + STORE KEEPER + AUTHORIZED OPERATIONAL DAILY BUSINESS.
DESKTOP = OWNER/ADMIN + ACCOUNTANT CONTROL.

Detailed architecture: `docs/TORVO-V2-PUBLIC-WEB-APP-ARCHITECTURE.md`.

## NON-NEGOTIABLE SAFETY
- Remote `torvo-v2-build` is source of truth; fresh-fetch SHA before every write.
- V27/main remains untouched.
- No fake data/counts/rates/availability/payment/WhatsApp sent states, secrets, insecure shortcuts or client-trusted financial rules.
- GitHub SQL is NOT runtime verified until executed/tested in Supabase staging.
- Stock deduction follows authoritative payment/fulfilment business rules and must occur exactly once.
- Dealer/private fitment, pricing and role financial privacy remain server-enforced.
- Public price and checkout totals are server-authoritative.
- Payment callbacks are idempotent; duplicate callbacks/retries cannot duplicate paid state/orders/stock effects.

## SALES FLOW — DEALER B2B
Purchase Order -> Sales Order -> controlled revision -> exact latest Dealer OK -> Estimate -> internal payment/fulfilment -> Delivery. Dealer rates are server-calculated. TORVO revision invalidates old Dealer OK. Estimate locks direct revision. ADD MORE ITEMS creates a separate linked Additional Purchase Order after TORVO approval and never mutates the original order/Estimate. Duplicate catalog item lines are blocked in UI and database integrity.

## PUBLIC CUSTOMER FLOW
PUBLIC SEARCH/CATALOG or REQUIREMENT -> HIGH CUSTOMER RETAIL PRICE/QUOTE -> CART/CONFIRMATION -> DELIVERY DETAILS -> FULL PREPAID OR REQUIRED LOGISTICS ADVANCE -> SERVER/PROVIDER PAYMENT VERIFICATION -> ORDER CONFIRMATION -> PICK -> PACK -> DISPATCH -> DELIVERY / AUTHORIZED BALANCE COLLECTION.

Normal refusal/non-acceptance may apply the paid logistics advance against applicable forward + return logistics cost under the disclosed policy. TORVO cancellation/non-supply, duplicate payment, wrong shipment, verified damage/defect and legal exceptions remain Admin-controlled/auditable.

## DEALER PRIVACY
Dealer App shows no Owner-only confidential cost/profit. Private Suitable/cross-compatibility remains TORVO-private unless explicitly shared. Dealer fitment suggestions earn ZERO points and are private between Dealer and TORVO. Dealer pricing is never inferred from public pricing client-side.

## PURCHASE / INVENTORY
Purchase Entry is the single supplier stock-receipt path. Owner/Admin enter Supplier + Invoice + items/qty/rate; duplicate Supplier+Invoice blocked. Save adds inventory exactly once and writes movement. Purchase correction uses audited reversal. Purchase Requirement never independently receives the same supplier stock. Purchase Rate History/Cost is Owner-only after save. Purchase Requirements support staff submission, Admin review, secure Item Master linking, partial/full Purchase fulfilment, exact Dealer allocation tracking and audited tracking reversal without stock duplication.

## UI / UX
Public Website: premium TORVO identity, fast public product discovery, Direct Customer e-commerce, SEND REQUIREMENT, BECOME A DEALER and DEALER LOGIN/OPEN APP.
Dealer/staff App: premium mobile-first daily-use app UI, strong search/filter, popup/bottom-sheet secondary actions, readable touch targets/text, no horizontal overflow.
Secure Desktop: compact professional cloud-business UI optimized for keyboard/mouse and wide screens; main daily actions visible quickly.
Use action-specific button labels (SAVE, SUBMIT, APPROVE, UPDATE, CONFIRM, SEND, CREATE ESTIMATE, CANCEL, CLOSE); do not put OK on every button.
Main daily-use actions/status/search should fit the first screen where practical without microscopic text. Secondary/history/details belong in popup, bottom-sheet, drawer, tabs or VIEW DETAIL.

### ENGLISH DISPLAY CASE RULE
English business-facing UI text is UPPERCASE across TORVO V2. Case-sensitive/protocol/identity values are exceptions: EMAIL, PASSWORD/PIN, URL/WEBSITE, technical IDs, tokens/keys and similar machine-sensitive identifiers.

## DELIVERY
Existing B2B delivery policy: Machines/Accessories delivery charge applies. Spare Parts delivery free only when spare-parts subtotal >= Rs 10,000. Public e-commerce checkout has its own server-authoritative logistics/advance calculation and must not accidentally reuse Dealer-only pricing rules without explicit configuration.

## ROLES
OWNER full. ADMIN operational/admin but not Owner-only confidential cost/profit. SALESMAN mapped Dealer/area/order/sales. ACCOUNTANT secure desktop accounting/payment + authorized flows. STORE KEEPER stock/pick/pack/dispatch with no unauthorized financials. DEALER approved linked App. Compatibility/private Suitable Owner/Admin. Purchase Cost/Profit Owner-only.

## BACKUP & DISASTER RECOVERY
Website, App and Desktop share one authoritative backend; avoid conflicting duplicate business databases. Backup is a core Owner/Admin function. A backup request is not success: only trusted worker completion + integrity verification can mark it verified. Portable backup must be encrypted; secrets/passwords/service-role credentials are excluded. Full Restore Point carries DB backup + code branch/commit + schema version + checksum + restore manifest. GitHub code/migrations + verified DB backup + restore manifest together form disaster recovery. Restore must be staging-tested.

## WHATSAPP / OTP / SESSION
Dealer onboarding preference: WhatsApp OTP. TORVO support currently 7027751533, Admin-changeable. Automatic WhatsApp sending requires real provider/API + testing. Approved operational App users should support secure long-lived sessions; logout, expiry, revoked/blocked access, suspicious/new device, PIN reset or defined security events may require re-verification.

## APP DELIVERY STRATEGY
Install-ready PWA/web-app foundation is retained for rapid development/testing. Native Android/iOS packaging can reuse the same backend, role/security model and business logic after core stability. Do not create duplicate native business logic/database or fake store links.

## CURRENT SOURCE FOUNDATION
Source-level foundations already cover significant Dealer/Sales, Purchase, Purchase Requirement, Inventory, Returns, Approval, Backup/Recovery, Public Website preview, role App previews, protected public retail pricing and public checkout payment-mode structures. These are not all runtime/staging verified.

Important public retail SQL foundations:
- `supabase/v2-public-retail-pricing-foundation.sql`
- `supabase/v2-public-checkout-payment-modes.sql`

## MAJOR RELEASE BLOCKERS
- Supabase migration chain must be compiled/executed/tested in staging.
- Public checkout needs production-grade cart/address/order/payment-provider integration and server-authoritative quote/order RPCs.
- Logistics advance/RTO calculation needs Admin configuration and real courier/serviceability inputs when available.
- Authenticated role routing must be finalized: Dealer/Salesman/Store Keeper -> App; Owner/Admin/Accountant -> Desktop; blocked/inactive -> no private access.
- WhatsApp OTP/provider, secure long-lived sessions and suspicious-device flow need runtime integration.
- End-to-end payment/advance -> fulfilment -> delivery -> exactly-once stock proof remains mandatory.
- Public Customer controlled claim/exception workflow needs authorized backend/Admin UI.
- Premium CSS layering/readability regression must be corrected safely.
- Browser alerts/confirms in remaining workspaces should become in-app validation/confirmation.
- Backup trusted worker/storage/export and actual restore drill remain.
- Exact current GitHub build + Netlify deploy SHA must be verified before calling a release live.

## FAST DEVELOPMENT PRIORITY — OWNER REQUESTED ASAP
Do not restart planning on every turn. Continue maximum safe compatible batches from current branch. Priority order:
1. Server-authoritative Public Customer cart/quote/address/order/payment foundation including FULL PREPAID and LOGISTICS ADVANCE modes.
2. Authenticated role routing and Desktop gate.
3. Dealer App core end-to-end business flow.
4. Public Customer claim/exception + RTO/refund controls.
5. Admin public-retail/logistics/payment configuration.
6. CSS/readability/layering cleanup and removal of browser alerts/confirms.
7. Staging migration/runtime tests, payment/stock E2E, WhatsApp/session integration.
8. Exact deploy verification, responsive QA, backup restore drill, then domain/release transition with old site preserved as backup/reference.

## SQL INSTALL
`supabase/V2_INSTALL_ORDER.md` is authoritative. Never run migrations alphabetically. New public retail/checkout migrations must be added to the controlled install sequence and staging-tested before production.

## NEW CHAT RECOVERY INSTRUCTION
In a new chat, tell ChatGPT: `Continue TORVO V2 from docs/TORVO-V2-MASTER-HANDOVER.md on branch torvo-v2-build. Inspect current GitHub first. Never touch V27/main. Continue actual work in large safe batches and keep reports short.` This file plus current repository state is authoritative over old chat assumptions.
