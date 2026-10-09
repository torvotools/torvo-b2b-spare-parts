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
