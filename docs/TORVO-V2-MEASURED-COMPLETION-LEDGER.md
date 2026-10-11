# TORVO V2 — EVIDENCE-BASED COMPLETION LEDGER

Updated 2026-10-11. Authoritative branch: `torvo-v2-build`. Baseline HEAD: `1a02b90cf31dad41a5166ce3b42b6fb7d361c586`.

## Meaning of percentages
Overall 100% completion: **NOT YET MEASURED**. A successful build or present source file is not a completed runtime acceptance test. No numerical completion percentage may be presented as verified until every checklist item has a defined binary or weighted acceptance criterion, actual evidence, and an audited denominator. Do not substitute an estimated 85–90% foundation score.

## Source and staging evidence at baseline
- Current-HEAD GitHub workflows: Build Check SUCCESS; Cloudflare Preview SUCCESS; Android APK SUCCESS. These are build/deployment checks, not live end-to-end workflow acceptance.
- STAGING `jvmhhngjlaqrfopfavur`: 125 public tables, 125 with RLS enabled; 1 Dealer; 0 sales documents; 0 purchases; 0 dispatches; 0 backup runs; 0 restore manifests; 0 app-release artifacts.
- Brand ticker Option 5 source deployed. Brand Admin name/color editor source exists. STAGING brand_logos item count 0; genuine Admin-save-to-public-color test OPEN.
- Production database, main/V27 and production domain untouched.

## 27 numbered staging acceptance checks
Canonical criteria: `docs/TORVO-V2-STAGING-ACCEPTANCE.md`. The statuses below are **end-to-end acceptance**, not code presence.

| # | Acceptance check | Verified status | Required next evidence |
|---|---|---|---|
| 01 | Canonical SQL install order | OPEN | Exact staging install sequence and error-free audit |
| 02 | OTP / session Edge Functions | OPEN | Deployed versions and live authorized function tests |
| 03 | Dealer two-device invalidation | OPEN | Genuine device A/B test |
| 04 | Dealer private reads / 30-day boundary | OPEN | Active/revoked device runtime calls |
| 05 | Dealer native-app-only access | PARTIAL | Physical app + normal web denial test |
| 06 | Role-specific entry surfaces | PARTIAL | Real native/web routing evidence |
| 07 | Wrong-runtime rejection | OPEN | Cross-platform denial tests |
| 08 | Dealer/staff login entry | PARTIAL | Genuine OTP login for both roles |
| 09 | Staff session and platform rules | OPEN | Role/device matrix runtime |
| 10 | Staff OTP security | PARTIAL | Expiry/reuse/throttle/revoke tests |
| 11 | WhatsApp routing | OPEN | Per-role and public channel runtime |
| 12 | Salesman attendance | OPEN | Real role-based attendance test |
| 13 | Dealer transaction chain | OPEN | PO through delivery with accepted records |
| 14 | Exact-revision Dealer OK | OPEN | Revision/approval runtime test |
| 15 | Add More Items | OPEN | Approval, idempotency, linked order test |
| 16 | Public discovery → dealer referral | OPEN | Live public end-to-end and privacy check |
| 17 | Inventory posting and reversal | OPEN | Exactly-once stock reconciliation |
| 18 | Full role access isolation | OPEN | Authorized and denied data/action matrix |
| 19 | Release Center provenance | OPEN | Trusted-writer runtime evidence |
| 20 | Backup and isolated restore | OPEN | Verified artifact, manifest, restore comparison |
| 21 | Mobile/desktop UX and search | PARTIAL | Full screen/responsive interaction audit |
| 22 | Test APK identity/manifest | OPEN | Exact SHA and downloaded artifact hash evidence |
| 23 | Real Android device review | PARTIAL | Complete real-device screenshots and workflow evidence |
| 24 | Production Android signing | EXTERNAL/OPEN | Owner-authorized signing/release artifacts |
| 25 | App data vs native update rules | OPEN | Live backend-update and app-release tests |
| 26 | Production update safety | OPEN | Release feed provenance and rejection tests |
| 27 | Final exact-SHA acceptance | OPEN | Freeze HEAD and compare build/web/APK evidence |

**Measured acceptance result:** 0/27 **fully verified PASS** in the current evidence ledger; 6/27 PARTIAL (05, 06, 08, 10, 21, 23); 21/27 OPEN including EXTERNAL/OPEN. This is **not** a claim that 0% of code is written or that earlier work was lost. Items may be upgraded only after evidence is recorded.

## Additional unnumbered gates
- Official State/District/City dataset and dependent registration behavior: OPEN.
- Brand Admin save/validation/color persistence/display: OPEN runtime.
- Catalog permanent-delete authorized negative/positive runtime: OPEN.
- Reports reconciliation against genuine transactions: OPEN.
- TORVO-wide cohesive UI/UX for website, Dealer, Salesman, Store, Accountant, Owner/Admin: OPEN final visual and interaction acceptance.
- Production/domain cutover: EXTERNAL/OPEN, Owner approval required.

## Execution order
1. Complete safe source-level audit and resolve defects in bulk; preserve one codebase/backend and accepted business flow.
2. Run real STAGING auth/role and dealer/device gates with genuine authorized identities; never create fabricated evidence.
3. Run genuine B2B purchase/sale/inventory/returns/reports; verify transaction integrity.
4. Verify backup + isolated restore, release metadata, APK hash and physical Android acceptance.
5. Consolidate responsive UI/UX under one shared TORVO theme throughout, preserving Owner-approved Option 5 brand ticker.
6. Freeze final SHA; re-run exact build, preview and Android evidence; request explicit Owner permission for production cutover.

Update each gate with dated evidence, actor/environment, exact SHA, observed result and remaining blocker. Do not count documentation itself as a passed runtime gate.

## 2026-10-11 follow-up: static verifier inventory
The repository contains source-level verifier entrypoints `scripts/verify-v2-final-readiness.mjs`, `scripts/verify-v2-runtime-readiness.mjs`, `scripts/verify-v2-acceptance-bundle.mjs`, `scripts/verify-v2-location-dropdowns.mjs`, and `scripts/verify-v2-admin-managed-experience.mjs`. Their presence does **not** establish execution success or close any of the 27 real-world acceptance checks. Latest pre-ledger exact SHA `1a02b90` had Build/Cloudflare/Android CI success. Ledger-only commit requires its own CI evidence if triggered. Next safe batch should inspect these verifier outputs and fix source defects before requesting genuine role/device acceptance.
