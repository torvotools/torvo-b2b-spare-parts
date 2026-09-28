# TORVO V2 — LIVING MASTER PROJECT REPORT

Status: CANONICAL CURRENT TRUTH INDEX
Updated: 2026 09-28
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## RULE
This file is the first current-state index for TORVO V2. It does not replace evidence history; it prevents old/superseded instructions from being mistaken for current requirements.

Before every material change:
1. Fetch current remote HEAD; never write from a remembered SHA.
2. Read this report plus the relevant canonical contract.
3. Preserve Owner-locked business logic.
4. Update this report when a decision changes project truth.
5. Keep audit/history in Git instead of deleting evidence needed for rollback.

## CURRENT PROJECT IDENTITY
- ONE TORVO V2 codebase.
- ONE authoritative backend/database architecture.
- Public Website + role-based operational apps + secure desktop.
- V27/main are legacy/reference and are not development targets.
- Production and domain cutover require explicit Owner approval.
- Current preview remains Cloudflare Workers until production cutover is accepted.
- UI rollback reference "22" = commit 47eb263662d7a4e552bbb73e18483d35435e90e7.

## LOCKED BUSINESS PRINCIPLES
- Existing Owner-approved business logic must not be changed merely for UI modernization.
- Public Website is discovery/dealer-referral, not public e-commerce checkout.
- Private dealer rates, private stock/financial data and role-restricted information stay protected.
- Dealer private workspace is app-first/private.
- B2B canonical flow remains DEALER -> PO -> SALES ORDER -> DEALER OK -> ESTIMATE -> PAYMENT/FULFILMENT -> STORE/DISPATCH -> DELIVERY/TRACKING.
- No fake users, stock, prices, availability, distance, transactions or acceptance evidence.

## CURRENT UI/UX DIRECTION
- Entire platform uses one TORVO premium design language: RED / BLACK / WHITE / GREY.
- Search + Filter + Fast Action are first-class.
- Product photography is primary where genuine media exists; icon/placeholder is fallback.
- Desktop is information-dense and clean; mobile is intentionally mobile-first.
- Forms, borders, buttons, tables, status, spacing, Back/navigation and filters must be consistent across roles.
- Public Website header has no old phone/email/social top strip.
- Public top-level product categories are exactly MACHINES / SPARE PARTS / ACCESSORIES.
- Current UI contracts: docs/TORVO-V2-UI-DESIGN-CONSTITUTION.md plus final CSS layers under src/v2.

## AI/API APPROVED DIRECTION
Canonical contract: docs/TORVO-V2-AI-API-INTEGRATION-ARCHITECTURE.md
Integration-ready scope: Product Vision/AI, Accounting, WhatsApp Business, existing Email, GST/e-Invoice/e-Way Bill, Logistics/Tracking, Payments/Reconciliation, Maps/Address and Monitoring.
TORVO remains system of record. Provider secrets stay server-side. AI uncertain/critical facts require review; compatibility becomes authoritative only after authorized human confirmation.
Paid provider activation/production credentials require Owner approval.

## DEALER SERVICE / REPAIR BOOK — OWNER APPROVED 2026-09-27
Dealer App will include a private operational SERVICE / REPAIR BOOK to increase daily dealer utility and capture genuine repair-demand intelligence.
Canonical flow: CUSTOMER DETAILS -> MACHINE PHOTO -> BRAND/MODEL -> STRUCTURED COMPLAINT + OPTIONAL NOTE -> MACHINE IN / TOKEN -> REPAIR PARTS USED -> DEALER COST + SELLING RATE VIEW -> REPAIR BILL -> CUSTOMER WHATSAPP READY/BILL NOTICE -> MACHINE OUT / DELIVERY HISTORY.
Dealer dashboard must show machines currently IN, repair status/reason, READY and DELIVERED/history. Complaint choices should be structured and extensible rather than free-text only.
Repair parts should link to genuine TORVO catalog items where possible. Do not invent parts, rates or fitment. Dealer financial visibility remains dealer-scoped; TORVO background analytics must remain role/privacy controlled.
Customer data collected for repair operations is operational data; do not silently treat it as marketing consent. WhatsApp operational notifications and marketing consent remain distinct.
This is an approved addition to Dealer App business logic. Do not build it as a separate app/project.\nImplementation foundation now exists in `supabase/v2-dealer-service-book.sql`, private-media contracts/workers, `src/v2/services/dealerServiceBook.js` and Dealer App `SERVICE BOOK` UI. The core Service Book migration, server bill-integrity migration, private-media boundary and Dealer-bound media-path hardening are installed in STAGING; private upload/read/orphan-delete workers are deployed there with JWT verification. Genuine Dealer runtime acceptance remains OPEN because no fake Dealer/job/catalog data may be created to close it. Owner direction on 2026-09-28 supersedes the earlier PENDING note: Service Book is ACTIVE PARALLEL work and must progress alongside the main TORVO V2 completion path without blocking it. Closed repair bills are server-derived, delivered/cancelled jobs are immutable against reopening, and private repair media must remain Dealer/device-bound. UI must not fabricate saved jobs or acceptance.

## CURRENT AUTH / SECURITY
- Genuine staging Owner bootstrap completed for OR@000.
- Staff master-email OTP path has genuine staging evidence.
- Protected Owner workspace final browser runtime acceptance remains OPEN until verified.
- Do not create fake Admin/Dealer/staff identities to close gates.
- Production backend remains untouched until approved.

## CURRENT ACCEPTANCE TRUTH
Canonical ledger: docs/TORVO-V2-FINAL-ACCEPTANCE-EVIDENCE.md
Runtime/external gates still OPEN include Dealer auth/device, full staff role/browser acceptance, B2B transaction, purchase/inventory/returns reconciliation, reports reconciliation, backup/restore rehearsal, Android real-device, Android production signing and production/domain cutover.
CI success is not real-device or business-runtime acceptance.

## CLEANUP / SUPERSESSION POLICY
When a newer Owner-approved decision supersedes an older implementation:
- mark the old path RETIRED/SUPERSEDED;
- dependency-audit before physical deletion;
- remove obsolete runtime/code/database paths only when safe;
- preserve necessary Git history and acceptance evidence;
- do not keep two active implementations of the same business capability.
V27/legacy resources are candidates for dependency-safe retirement, not blind deletion.

## DOCUMENT AUTHORITY ORDER
For current decisions use:
1. this Living Master Project Report;
2. docs/TORVO-V2-MASTER-HANDOVER.md for detailed business/system requirements;
3. docs/TORVO-V2-UI-DESIGN-CONSTITUTION.md for UI;
4. docs/TORVO-V2-AI-API-INTEGRATION-ARCHITECTURE.md for integrations;
5. docs/TORVO-V2-FINAL-ACCEPTANCE-EVIDENCE.md for PASS/OPEN evidence;
6. supabase/V2_INSTALL_ORDER.md for database installation order.
If an older note conflicts with a later explicit Owner-approved rule recorded here, the later rule controls. Do not erase historical evidence merely to hide the conflict.

## REPORT MAINTENANCE
Every future meaningful batch should update current truth when it changes one of: architecture, locked logic, active/retired path, acceptance state, production status, domain status, integration/provider decision or rollback baseline.
Do not churn this report for cosmetic commits that do not change project truth.
