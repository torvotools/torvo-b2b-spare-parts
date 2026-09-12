# TORVO V2 MASTER HANDOVER

Last updated: 12-09-2026
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## START HERE IN EVERY NEW CHAT
Continue actual development from `torvo-v2-build`. Fetch current repository state before changing anything. V27/main is old/live and MUST remain untouched. Do not merge/replace main without full verification plus explicit Owner permission. Work in large compatible batches where safe; do not inflate task counts with cosmetic micro-edits. Keep progress reports compact to preserve chat space. Premium modern responsive UI is non-negotiable across Home/Login/Admin/Salesman/Accountant/Store Keeper/Dealer.

## NON-NEGOTIABLE SAFETY
- Remote `torvo-v2-build` is source of truth; fresh-fetch SHA before every write.
- No fake data/counts/rates/availability/WhatsApp sent states, secrets, insecure shortcuts or client-trusted financial rules.
- GitHub SQL is NOT runtime verified until executed/tested in Supabase staging.
- Stock deduction: payment requirement + actual delivery, exactly once. Estimate/Picked/Packed never deduct stock.
- Dealer/private fitment and role financial privacy must remain server-enforced.

## BUSINESS DIRECTION
TORVO V2 is a B2B operational portal, not accounting software. Product priority: Machine -> Spare Part -> Accessory. Approved Dealers only. Dealer-facing order name is PURCHASE ORDER; TORVO internal equivalent is SALES ORDER.

## SALES FLOW
Purchase Order -> Sales Order -> controlled revision -> exact latest Dealer OK -> Estimate -> internal payment/fulfilment -> Delivery. Dealer rates are server-calculated. Direct Dealer modification has a controlled allowance; after exhaustion use audited request/review. TORVO revision invalidates old Dealer OK. Estimate locks direct revision. ADD MORE ITEMS creates a separate linked Additional Purchase Order after TORVO approval and never mutates the original order/Estimate. Duplicate catalog item lines are blocked in UI and by database integrity migration.

## DEALER PRIVACY
Dealer Portal shows no internal payment/outstanding/accounting data. Normal Dealer history is latest 30 days. Private Suitable/cross-compatibility remains TORVO-private unless explicitly shared. Dealer fitment suggestions earn ZERO points and are private between Dealer and TORVO.

## PURCHASE / INVENTORY
Purchase Entry is the single supplier stock-receipt path. Owner/Admin enter Supplier + Invoice + items/qty/rate; duplicate Supplier+Invoice blocked. Save adds inventory exactly once and writes movement. Purchase correction uses audited reversal. Reorder/Purchase Requirement never independently receives the same supplier stock. Purchase Rate History/Cost is Owner-only after save. Purchase Requirements support staff submission, Admin review, secure Item Master linking, partial/full Purchase fulfilment, exact Dealer allocation tracking and audited tracking reversal without stock duplication.

## UI
Premium contemporary app-style TORVO design, mobile-first but fully responsive tablet/laptop/desktop/large monitor. Strong search/filter, especially Spare Parts. Popup-first Add/Edit/Approve/Hold/Send actions. TORVO red accent with coherent palette. Buttons should be wired UI -> logic -> authorized RPC -> DB -> success/error wherever backend exists. No horizontal mobile overflow. App-ready/PWA foundation exists; native Play Store/App Store packaging comes after core system is stable so business logic is not duplicated.

### ENGLISH DISPLAY CASE RULE
English business-facing UI text is UPPERCASE across TORVO V2. Case-sensitive or protocol/identity values are exceptions and must retain their required case, including EMAIL values, PASSWORD/PIN values, URL/WEBSITE values, technical IDs, tokens/keys and similar machine-sensitive identifiers.

## BACKUP & DISASTER RECOVERY — AUTHORITATIVE
- Backup is a core Admin/Owner function, not an afterthought.
- Admin panel must prominently warn when there has been no VERIFIED backup within 24 hours; >=48 hours is critical.
- Backup Control Center supports Database Backup, Full Restore Point and Configuration Export requests plus history/status.
- `backup_runs` is metadata/control only. Actual database dump/archive creation must run in a trusted server/backup worker, NEVER browser JS.
- A request is not success. Only worker completion + integrity verification may mark it verified.
- Portable backup must be encrypted; secrets/passwords/service-role credentials are excluded from backup artifacts and GitHub.
- Full Restore Point must carry database backup + code branch/commit + database/schema version + checksum + restore manifest so a destroyed environment can be rebuilt from a known point.
- Desktop/mobile download and Email/WhatsApp share/export are desired Admin actions, but must use a trusted signed/secure export path. Never claim Email/WhatsApp sent until provider integration succeeds.
- GitHub code/migrations + verified DB backup + restore manifest together form disaster recovery. Restore must be staging-tested before being trusted.
- Current source foundation: `supabase/v2-backup-control.sql`, `supabase/v2-backup-channels.sql`, `src/v2/config/backupPolicy.js`, `src/v2/services/backupService.js`, `src/v2/components/BackupControlCenter.jsx`, `src/v2/backup-ui.css`; Backup module is Owner/Admin-only.
- Staging contract/checklist: `supabase/tests/v2-backup-control-security-checklist.sql`.
- Trusted worker/restore manifest contract: `docs/TORVO-V2-BACKUP-WORKER-CONTRACT.md`.

## WHATSAPP / OTP
Dealer onboarding preference: WhatsApp OTP. TORVO support currently 7027751533, Admin-changeable. Automatic WhatsApp sending requires real provider/API + testing; prepared links/messages are not delivery proof.

## DELIVERY
Machines/Accessories delivery charge applies. Spare Parts delivery free only when spare-parts subtotal >= Rs 10,000. Delivery rules should be Admin-controlled/audited where designed.

## ROLES
OWNER full. ADMIN operational/admin but not Owner-only confidential cost/profit. SALESMAN mapped Dealer/area/order/sales. ACCOUNTANT internal estimate/payment/accounting + authorized flows. STORE KEEPER stock/pick/pack/dispatch with no financials. DEALER approved linked portal. Compatibility/private Suitable Owner/Admin. Purchase Cost/Profit Owner-only.

## APP STATUS
Install-ready web-app foundation exists: manifest, service worker, install bridge and honest device-supported INSTALL TORVO control in Dealer/staff shells. It is not yet a published Android APK/Play Store/iPhone App Store app. Do not show fake store links. Reuse the same backend/security/business logic when native packaging is added.

## CURRENT MILESTONE
Still within 20-40% Dealer + Sales milestone until materially implemented AND runtime-verified. Do not fake percentage. Source-level work includes premium role shell; Dealer rates/cart/PO/history; Sales revisions/Dealer OK/Estimate; change requests/Add More Items linked orders; scalable Sales/Dealer item finders; Salesman mapping/assisted foundation; Purchase Entry; Purchase Requirements fulfilment; Item Movement/Low Stock foundation; fitment/private Suitable foundation; app-ready foundation; and Backup & Recovery control foundation.

## MAJOR RUNTIME/RELEASE BLOCKERS
- Supabase migration chain has not been fully compiled/executed in staging.
- Latest Vite/Netlify branch build/runtime is not verified by a reliable CI/deploy result.
- WhatsApp OTP/provider/secure-link not fully integrated.
- Single-active Dealer session + inactivity PIN/OTP runtime flow pending.
- End-to-end payment -> delivery -> exactly-once stock deduction proof pending.
- Stock Conversion/Repacking, remaining rewards/GST/advanced modules and final responsive QA remain.
- Backup trusted worker/storage, encrypted artifact download/share and actual restore drill remain to implement/test.

## SQL INSTALL
`supabase/V2_INSTALL_ORDER.md` is authoritative. Never run migrations alphabetically. Backup migration dependency wiring and staging backup security/restore gates are now documented. Mandatory staging gate must test every role, sales revision/Dealer OK/Add More Items, duplicate line guard, Purchase/reversal, Purchase Requirements, Item Movement/Low Stock privacy, payment idempotency, stock exactly-once, fitment privacy/no-points, secret checks, backup role access, verified-age status, trusted-worker integrity and restore drill.

## NEXT DEVELOPMENT PRIORITIES
1. Continue Dealer/Sales milestone core blockers and runtime-safe scalable finders.
2. Implement the trusted backup worker/storage/export path when a server/runtime target is available; keep browser non-authoritative.
3. Staging SQL compile/test when staging action becomes available.
4. Verify actual Vite/Netlify build and repair runtime UI errors.
5. Complete Stock Conversion/Repacking + remaining advanced modules.
6. Complete WhatsApp onboarding/security/session runtime.
7. Final responsive premium UI QA + disaster recovery restore drill.

## LATEST COMPLETED SOURCE BATCH — 12-09-2026
- Wired backup/recovery into the authoritative staging install/release gate.
- Added backup role/security, verified-age, idempotency, integrity and restore-drill staging checklist.
- Defined trusted backup worker boundary, encryption/checksum and Full Restore Point manifest contract.
- Reconfirmed English business-facing UI text UPPERCASE rule with case-sensitive exceptions.
- Runtime Supabase execution/restore verification is still pending; source work is not represented as runtime proof.

## NEW CHAT RECOVERY INSTRUCTION
In a new chat, tell ChatGPT: `Continue TORVO V2 from docs/TORVO-V2-MASTER-HANDOVER.md on branch torvo-v2-build. Inspect current GitHub first. Never touch V27/main. Continue actual work in large safe batches and keep reports short.` This file plus current repository state is authoritative over old chat assumptions.
