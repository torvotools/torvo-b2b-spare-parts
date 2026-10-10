## OWNER FINAL EXECUTION CONTRACT — 2026-10-09
- Replace arbitrary 30-block countdown with TEN LARGE ACCEPTANCE PHASES: (1) code/database/error audit; (2) unified six-surface responsive UI/UX; (3) public homepage/search/filter/catalog/official locations/registration; (4) dealer/staff OTP and role/session runtime; (5) PO/Quotation/Estimate/Marg Bill/Sale; (6) purchase/inventory/dispatch/delivery/returns; (7) accounting/reports/rewards; (8) service book/notifications/referrals/masters; (9) Android/update/backup/restore/performance/security; (10) all-surface final acceptance/release/live readiness.
- These are work packages, NOT promises of completion in exactly ten turns. Do not count audits, docs, or isolated CI scripts as completed phases.
- Each phase requires source changes where needed, green CI for exact SHA, actual UI/functional testing, staging runtime evidence, and external device/release evidence where applicable. Do not declare a phase PASS merely because source exists.
- Track 12 canonical acceptance workstreams separately. Verified completion = 100 * fully accepted workstreams / 12; verified remaining = 100 minus completion. Current baseline 0/12 = 0.0% verified, 100.0% remaining. This is acceptance completion, NOT fraction of existing code built.
- Owner delegates all ordinary UI/UX decisions; preserve original TORVO brand/logo and canonical business/security boundaries. Improve existing screens comprehensively, avoiding repetitive cosmetic-only commits.
- Production Supabase/domain cutover and destructive production operations require explicit Owner authorization. Do not invent official location data, staff/dealer identities, sales, device tests, signing, or backup/restore evidence.
- Report actual work, evidence, blockers, and both percentages with each meaningful delivery. Do not claim 100% or live-ready before all gates pass.

# TORVO V2 — FINALIZATION PROGRESS LEDGER

Started: 2026-10-09. Owner command: N advances numbered finalization blocks automatically.
Source branch: `torvo-v2-build`. Production/domain cutover is explicitly excluded from this completion denominator.

## Measurement
The denominator is **12 acceptance workstreams**, not commit count or CSS patch count.
A workstream earns 1 completed unit only when its own source, CI, staging runtime and relevant UI/device evidence are recorded in `docs/TORVO-V2-FINAL-ACCEPTANCE-EVIDENCE.md` or equivalent linked artifact. Partial source implementation is tracked as PARTIAL but does not count as complete. Do not claim 100% while any workstream is OPEN. Percentage = (fully accepted workstreams / 12) × 100, rounded to one decimal. Report both completed and remaining after each owner N.

Initial evidence-based baseline: **0 / 12 newly fully accepted workstreams = 0.0% complete, 100.0% remaining**. This is NOT the proportion of source code already written; it is a conservative acceptance score for the remaining finalization work. Existing source and prior green CI are retained.

## Workstreams
| # | Workstream | Initial acceptance | Required evidence |
|---|---|---|---|
| 1 | Codebase, CI, deployment and canonical architecture | PARTIAL | Current exact SHA build, Cloudflare, Android, duplicate/dead-code and route audit |
| 2 | Shared UI/UX and all six surfaces | OPEN | Mobile/desktop visual matrix, consistent tokens/components, working controls |
| 3 | Registration and official location data | OPEN | Official State→District→City import, Other City, mobile E2E |
| 4 | Dealer and staff auth/session/role security | PARTIAL | Real OTP, role and device revocation E2E |
| 5 | Catalog, products, fitment, media and search | PARTIAL | Public/private discovery, verified photos, filter E2E |
| 6 | Dealer PO→Quotation→Estimate→Marg Bill→Sale | OPEN | Real staging transaction, idempotency and role gates |
| 7 | Purchase, inventory, dispatch, delivery, returns | OPEN | Reconciled stock movements and genuine E2E |
| 8 | Accounting, financial privacy and reports | OPEN | Reconciled staging financial data and permissions |
| 9 | Rewards, service book, notifications and referrals | OPEN | Role-based complete user journeys |
| 10 | Catalog destructive actions and other privileged admin operations | OPEN | Safe staging runtime tests, audit/confirmation gates |
| 11 | Backup, restore and portable final system package | OPEN | Real verified backup artifact and isolated restore rehearsal |
| 12 | Android real-device, signed release and pre-production acceptance | OPEN | Physical install/login/UI, signing, release evidence; production cutover excluded |

## Block #1 — baseline audit
- Verified latest branch HEAD at block start: `88486e19c48c21fee2f589adf8832339d4b12c70`.
- The matching Build Check was SUCCESS; Android/Cloudflare were still in progress at that observation.
- Canonical source reviewed: Master Handover, Final Acceptance Evidence, V2 Install Order, UI Design Constitution and Staging Acceptance.
- Existing `verify-v2-final-readiness.mjs` is a source/preflight checker; it cannot substitute for physical-device and staging transaction evidence.
- Current known hard blocker: official location tables had zero rows in the last verified staging audit; do not invent Government location records.
- Previous visual LOCK decisions were superseded by the Owner's 2026-10-09 design-unlock directive. Business security and production boundaries remain protected.
- No new completion credit is assigned without actual workstream acceptance.

## Block #2 — Mobile registration information architecture
- Registration app-access explanatory notice was moved into a native, keyboard-accessible `details/summary` disclosure; required text and install control remain reachable. This eliminates a large always-open notice ahead of the form on mobile.
- Unified disclosure presentation in the canonical design foundation with focus-visible treatment.
- The registration still contains many required inputs and official location controls; do not promise a single viewport on all phone sizes or while the keyboard is open.
- Build/Cloudflare/Android checks for this block and physical Android acceptance are pending at commit time.
- Workstream #2 (shared UI/UX) and #3 (registration/location) remain OPEN until cross-surface and official-location E2E evidence. Completion credit: 0/12 = 0.0%, remaining 100.0%.

## Block #3 — Cascading location request integrity
- Fixed stale asynchronous district and city fetches in `PublicLocationDropdowns.jsx`: user-driven state/district changes increment request versions and ignore outdated responses, including stale error/finally updates.
- Clearing a state or district also clears pending loading and resets `cityOther` so a prior manually entered city cannot survive a changed location hierarchy.
- Official State/District/City master import remains OPEN. Source-level fix is not a runtime PASS and requires fresh CI plus actual mobile acceptance.
- Workstream #3 remains OPEN. Completed 0/12 = 0.0%; remaining 100.0%.

## Block #4 — Batch execution / location hydration safety
- Owner requests maximum safe compatible work per N, fewer fragmented micro-fixes, and faster completion. Thirty numbered blocks remain a planning estimate, not a guaranteed end date; consolidate related tasks into bulk batches.
- Existing direct user-driven State/District request race protection was extended to the **saved-value hydration effects** that load dependent options, and to component unmount cleanup. A version check now prevents obsolete async results from repopulating the wrong location after a selection change.
- Previous HEAD `98fa47119a5f13f9c6fd5c4198c7a208334dd776`: latest Build Check for code SHA `7c292e67644adbc640c0213071155b1c564fc368` SUCCESS; Cloudflare/Android for ledger HEAD were still in progress when checked.
- No official location data was fabricated or imported; this remains a real deployment gate.
- Progress 0/12 accepted workstreams = **0.0% verified complete / 100.0% remaining**. Source fixes are PARTIAL until runtime/mobile evidence exists.

## Block #5 — Registration regression guard and real staging location audit
- Added explicit checks to `scripts/verify-v2-location-dropdowns.mjs` for async request-version guards, mounted/unmount protection, reset of Other City, and accessible expandable app-install disclosure.
- Read-only staging query confirmed `location_states=0`, `location_districts=0`, `location_cities=0` on 2026-10-09. Official GoI location import remains a hard runtime blocker; no placeholder rows were inserted.
- At observation: previous `758ecaba...` Build Check in progress; prior `7c292e...` Build Check SUCCESS; Android/Cloudflare for `98fa471...` in progress. Do not infer current SHA deployment PASS.
- Workstreams #2 and #3 remain OPEN. Completed 0/12 = 0.0%, remaining 100.0%.

## Block #6 — Read-only staging database/security and CI audit
- Verified STAGING project `jvmhhngjlaqrfopfavur` on 2026-10-09 using read-only SQL: 125 public tables, all 125 have RLS enabled; dealers=1, sales_documents=0, purchase_headers=0, backup_runs=0, backup_restore_manifests=0, app_release_artifacts=0.
- RLS enabled is not a substitute for per-role permission acceptance. No dealer OTP, staff OTP, financial transaction, stock, backup or release artifacts were fabricated.
- CI observation: Build Check for code SHA `758ecaba1d2b54cf5d270aa39b88560a31fb7baa` SUCCESS; Cloudflare for ledger SHA `98fa47119a5f13f9c6fd5c4198c7a208334dd776` SUCCESS. Later CI runs for `9b507b6b1ebf9bfeb71815a739d834edc9c3da9d` still pending/in progress.
- This is an audit/evidence block, not a database migration. Workstreams #4, #6, #7, #8, #11, #12 remain OPEN. Completion 0/12 = 0.0%, remaining 100.0%.

## Block #7 — Read-only staging OTP/session RPC privilege audit
- Confirmed staging `public.dealer_email_otp_begin`, `dealer_email_otp_verify`, `staff_email_otp_begin`, `staff_email_otp_verify`, and v2 variants exist and are executable by service_role, **not** anon or authenticated.
- Confirmed dealer session create/revoke/validate and staff verified session creation are service-only; dealer self-assert and staff session validate/touch/revoke are authenticated-only.
- Canonical `approve_dealer(p_dealer uuid,p_rate_group text)` allows authenticated calls (internal authorization must still be enforced); legacy three-argument variant service-only.
- This is an ACL/metadata audit, not a live OTP challenge, role impersonation, verified session E2E or production security proof. No auth users or transactions were created.
- Workstream #4 remains PARTIAL; 0/12 workstreams accepted, 0.0% complete and 100.0% remaining.

## Block #9 — Corrected counting policy and dealer approval regression checks
- Owner correctly flagged that audit-only blocks were being counted too quickly. From this point, number a completion block only for a meaningful implemented change with an accompanying verification plan. Read-only audits alone are status work, not new completed blocks.
- Reviewed source verification contracts: `verify-v2-final-dealer-approval.mjs` already checks owner/admin gate, accountant verification, server-generated dealer code, canonical 2-arg RPC, and role UI visibility. `verify-v2-auth-runtime-evidence.mjs` explicitly requires real staging device/OTP evidence.
- Extended dealer approval regression verifier with explicit server-side auth identity check, active accountant review gate, and legacy approval RPC authenticated-access restriction.
- Source checks are not live role-impersonation proof. Workstream #4 remains PARTIAL; accepted 0/12 (0.0%), remaining 100.0%.

## Ten-phase execution — Phase 1 evidence snapshot (2026-10-09)
- Fresh staging read-only count: location_states=0, location_districts=0, location_cities=0, dealer_device_sessions=0, staff_auth_sessions=11 (total records, not active count), sales_documents=0, purchase_headers=0, dispatches=0, backup_runs=0, backup_restore_manifests=0, app_release_artifacts=0.
- Inspected canonical install-order contract, acceptance bundle verifier, final-readiness verifier, and runtime-readiness verifier. Source checks exist; no runtime acceptance can be inferred from their existence.
- Critical path: official location dataset; genuine Dealer OTP/device and role-based staff login; real PO-to-delivery/purchase/report reconciliation; verified backup/isolated restore; physical Android acceptance and signed release; exact final SHA and explicit Owner production cutover approval.
- Phase 1 status IN PROGRESS, not PASS. Canonical 12-workstream acceptance 0/12 (0.0% verified), 100.0% remaining. This is not percentage of source implementation.

## 2026-10-10 — Parallel completion lane status (Owner-directed bulk execution)
- Latest verified SHA before this note: `989e441ea530195f497f1237570e5445c5be61c3`. Build Check PASS; Cloudflare Preview PASS; Android APK workflow still in progress at the time of inspection. Do not extrapolate Android PASS.
- Catalog ↔ active draft cross-table database guards both ENABLED on staging. Rollback-only SQL tests confirmed catalog INSERT/code UPDATE and draft INSERT conflict rejection, with zero persistent test rows. Owner-authenticated conversion, concurrent transactions and UI E2E remain OPEN.
- Registration locations remain empty in staging (states/districts/cities all zero). Never invent official location rows. Genuine OTP/device, PO→delivery, purchase/report reconciliation, backup/restore, Android physical install and final UI cross-surface audit remain OPEN.
- Owner instruction: progress multiple compatible workstreams in parallel, not one small bug indefinitely. Maintain lanes: (A) security/catalog, (B) locations/onboarding, (C) B2B transactions/reports, (D) UI/UX six surfaces, (E) backup/Android/release. Track each with actual evidence, blockers, next action; never claim PASS based solely on source/CI.
- Unified final acceptance remains 0/12 fully signed-off workstreams (0% final accepted, NOT 0% implementation). No public/production launch before full verified handover and separate Owner approval.
