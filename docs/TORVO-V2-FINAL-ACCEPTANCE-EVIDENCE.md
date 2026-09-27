# TORVO V2 FINAL ACCEPTANCE EVIDENCE

Status: OPEN — evidence ledger for the remaining runtime/external gates.
Branch: `torvo-v2-build`.

This file prevents source completion from being confused with production acceptance. A gate becomes PASS only when the listed real evidence exists. Never manufacture identities, transactions, backup artifacts, signing evidence or deployment evidence merely to mark a gate complete.

| Gate | Required real evidence | Current verified state |
| --- | --- | --- |
| Dealer auth/device | Approved real staging Dealer; registered-email OTP path; Device B invalidates Device A; revoked device fails private reads/writes | OPEN — staging currently has no active Dealer acceptance identity |
| Staff auth/role | Authorized staging Owner/Admin/Accountant/Salesman/Store Keeper as applicable; master-email OTP/device/runtime boundary tests | PARTIAL — genuine Owner OR@000 bootstrap and master-email OTP verification/session creation have succeeded in STAGING; protected Owner workspace runtime acceptance remains OPEN, and no fake secondary Staff identities are created |
| B2B transaction | Real staging PO -> Sales Order -> exact Dealer OK -> Estimate -> payment/fulfilment -> dispatch -> delivery, including retry/idempotency checks | OPEN — no qualifying staging transaction evidence recorded |
| Purchase/inventory/returns | Real receipt/stock movement/delivery deduction/return or reversal with exactly-once and role checks | OPEN — no qualifying staging transaction evidence recorded |
| Reports | Reports Center totals/details reconciled against the accepted staging transactions and role privacy checked | OPEN — requires accepted transaction data |
| Backup/restore | Trusted-worker backup artifact + SHA-256/integrity + manifest + exact code/schema identity + isolated clean-target restore + core/security/runtime comparison | OPEN — no verified backup/restore rehearsal artifact recorded |
| Android test | Exact-SHA TEST-DEBUG APK installed on real Android device; package/hash/build SHA recorded; core login/business/UI checks | OPEN until real-device evidence is recorded |
| Android production | Privately signed release AAB/APK, preserved signing identity, version/build, store/release evidence and Owner acceptance | EXTERNAL/OPEN |
| Cloudflare exact SHA | Build Check + Cloudflare live evidence for the exact final accepted commit | CI EVIDENCE ONLY — exact final accepted SHA must be recorded after the branch is frozen; later commits supersede earlier CI evidence without converting runtime gates to PASS |
| Production/domain | Production backup/readiness, explicit Owner acceptance, production Supabase migration/deploy, domain/DNS cutover, post-cutover smoke test | EXTERNAL/OPEN; production must remain untouched before approval |

## Recorded CI evidence — 2026-09-19
- Exact Git SHA: `67ccd428a4191094d1c3c445b4c33a7a63052790`.
- Build Check #2095: SUCCESS.
- Cloudflare Preview #1421: SUCCESS.
- Android APK #1389: SUCCESS (build evidence only; this does **not** satisfy the real-device Android test gate or production signing gate).
- No production/domain acceptance is inferred from these CI results.

### Current verified code CI evidence — 2026-09-19
- Exact Git SHA: `2839fcb4e00b1d4de7d685b79d38966dbcec1a01`.
- Build Check #2114: SUCCESS.
- Cloudflare Preview #1440: SUCCESS; live worker exact-SHA body, no-store header, X-Torvo-V2 marker and build manifest verification passed.
- Android APK: no new run was triggered by this Cloudflare-workflow-only commit. The latest Android build evidence remains the prior successful run; real-device and production-signing gates remain OPEN.
- The canonical source preserves the three verified helper search-path hardenings: `torvo_is_staff_role(text)`, `reward_scheme_year()`, and `reward_scheme_period(integer)`.
- Install-order CI now explicitly protects the catalog permanent-delete runtime gate, so its required runtime verification cannot silently disappear from the authoritative install contract.
- Catalog permanent-delete RPC installation prerequisite is VERIFIED in STAGING: `permanently_delete_catalog_master(uuid,text)` is installed. The destructive-behavior acceptance gate remains OPEN until a real authorized Owner/Admin staging test proves wrong-confirmation, not-in-trash, in-use rejection, zero-usage deletion, post-delete absence and audit evidence.
- Dealer/Staff and business transaction runtime gates remain OPEN because STAGING has no acceptance identities or qualifying transactions; no fake records are to be created merely to close gates.
- This supersedes prior SHA CI evidence only; it does not convert runtime/external gates to PASS.

## Latest exact-HEAD CI evidence — 2026-09-19
- Exact Git SHA: `7592d05a1d33f5060dce54bc0daa93fe21aee896`.
- Build Check #2115: SUCCESS.
- Cloudflare Preview #1441: SUCCESS.
- Android APK #1408: SUCCESS (CI/build evidence only; real-device installation and production signing remain OPEN).
- This confirms the repaired Cloudflare live-evidence path on the current branch HEAD. Runtime identity/transaction, backup/restore rehearsal, catalog permanent-delete destructive-behavior acceptance, real-device Android, production signing, and production/domain gates remain OPEN.

## Current exact-HEAD CI evidence — 2026-09-19
- Exact Git SHA: `6c25ee538e0a92aaed9a4459cdf30af2df3e57ce`.
- Build Check #2120: SUCCESS.
- Cloudflare Preview #1446: SUCCESS.
- Android APK #1413: SUCCESS (CI/build evidence only; real-device installation and production signing remain OPEN).
- The final-readiness verifier includes fail-closed checks for real staging Dealer/Staff authentication acceptance, approved staging business/report reconciliation, secret-free restore packaging, and exact-SHA real-device Android review.
- Runtime/external gates remain OPEN until their real evidence exists; this CI result does not substitute for them.

## Evidence recording rule
For each completed gate record: UTC timestamp, environment/project ID, exact Git commit SHA, actor/test identity reference without secret values, test/result summary, artifact/checksum/run reference where applicable, and PASS/FAIL. A FAIL returns to `torvo-v2-build`, is fixed at root cause, and the affected gate is repeated.

## Non-substitutes
The following do NOT prove runtime acceptance by themselves:
- source code exists;
- migration file exists;
- RLS is enabled;
- CI workflow exists;
- backup request row exists;
- debug APK was built;
- documentation says PASS;
- a UI button rendered.

## Final 100% rule
TORVO V2 is called 100% only after every applicable gate above has real PASS evidence, final exact-SHA acceptance is complete, and the explicitly approved production/domain cutover has passed its smoke test. Until then, report the remaining gates truthfully.


## Acceptance tooling added — 2026-09-19
- Backup artifact integrity can now be checked with `npm run verify:v2-backup-artifact -- <manifest.json> <artifact>`; this validates real artifact bytes/checksum and manifest boundaries only, not restore success.
- Android real-device evidence can now be structure-checked with `npm run verify:v2-android-device-evidence -- <release-manifest.json> <evidence.json>`; this cross-validates package/channel/signing state, exact commit SHA and APK SHA-256 against the CI-generated release manifest; it does not perform or fabricate the physical device test.
- Both verifier contracts are enforced by the final-readiness CI verifier. Their presence does not change the OPEN state of backup/restore or Android real-device acceptance.
- Runtime evidence commands now cover Dealer/Staff auth, B2B flow, inventory, returns, report reconciliation, catalog destructive actions, restore rehearsal, Android production release and pre-production cutover. Each verifier validates supplied evidence only and does not manufacture staging identities, transactions, destructive actions, backup restores, signing or production cutover.
- Reports reconciliation command: `npm run verify:v2-report-reconciliation -- <evidence.json>`.
- Catalog destructive runtime command: `npm run verify:v2-catalog-destructive-evidence -- <evidence.json>`; RPC installation is verified in STAGING, while the behavior gate remains OPEN until an authorized staging Owner/Admin runtime test is recorded.


## Verified staging/runtime state refresh — 2026-09-19
- Source baseline before this documentation-only refresh: `cab8cfd7686ba01f4b619c4e65146ceea2b97467`.
- Build Check #2189: SUCCESS.
- Cloudflare Preview #1518: SUCCESS.
- Android APK #1478: SUCCESS (TEST-DEBUG CI evidence only; real-device and production-signing gates remain OPEN).
- STAGING project: `jvmhhngjlaqrfopfavur`.
- Public regular tables: 132; RLS enabled: 132/132.
- `permanently_delete_catalog_master(uuid,text)`, `get_report_summary()`, canonical `get_report_detail(...)`, public Dealer registration and trusted backup completion RPC prerequisites are installed in STAGING.
- STAGING remains clean for acceptance: no real acceptance Dealer/Staff identities, qualifying business transactions, verified backup runs/restore manifests or release-artifact rows are recorded. These gates therefore remain OPEN and must not be converted to PASS from source/CI evidence.
- Production project `gckafjiitjocodlrwanm`, V27/main and LOCK 1 remain untouched.


## Current auth/acceptance alignment — 2026-09-27
- Exact source SHA before this ledger update: `ed8ab60f53652c33f2044bacea21e24946520e16`.
- Build Check: SUCCESS; Cloudflare Preview: SUCCESS for this exact SHA. Android APK workflow was still running when this evidence note was written, so no Android PASS is claimed here.
- Canonical Dealer authentication is registered-email OTP plus one-active-device enforcement; retired Dealer PIN wording is not acceptance evidence.
- Canonical Staff authentication is Staff User ID plus server-generated OTP delivered only to the Owner/Admin-managed master security email; retired staff one-time-password/WhatsApp/emergency-login paths are not acceptance evidence.
- Initial Owner bootstrap is identity-only and fail-closed: it creates the first `OR@000` staff identity only, with no manual device registration/approval. Staff runtime acceptance remains OPEN until a genuine master-email OTP begin/receive/verify/session/revoke test is completed.
- Production, `main`, V27 and the locked Business Login UI remain outside this staging acceptance work.


## Auth architecture cleanup CI — 2026-09-27
- Exact Git SHA: `0a5c62721797e02586b2d3e35c35dfd9f178efa8`.
- Build Check #2828: SUCCESS.
- Cloudflare Preview #2159: SUCCESS.
- Android APK #2117 was still running when this ledger note was written; no Android PASS is claimed by this note.
- Manual Staff device registration/approval is retired. Hidden installation/device ID remains security/session metadata only.
- Staff: User ID + server-generated 6-digit OTP to the Owner/Admin-managed master security email; one active verified session per Staff ID.
- Dealer: registered email + server-generated 6-digit OTP; one active Dealer session.
- Legacy staging Edge Functions `dealer-pin-login` and `staff-one-time-login` remain deployed historically but canonical source has no caller; the available recent staging log audit found no usage. Removal remains pending a supported staging-only deletion path and must not touch production.
- Customer/Missing Product canonical public write remains `public_create_product_demand`; the legacy `public_create_product_requirement` grant is revoked. Historical support/complaint dependencies prevent blind deletion of its table/migration.
- Runtime auth, business, backup/restore, real-device Android, production signing and production/domain gates remain OPEN.


## Canonical Customer Demand cleanup acceptance — 2026-09-27
- Exact Git SHA: `4eb442b4a453b9f19901398e3c1da29c85fa68b3`.
- Build Check #2838: SUCCESS.
- Cloudflare Preview #2169: SUCCESS.
- Android APK #2127: SUCCESS (CI/build evidence only; physical-device installation and production signing remain OPEN).
- Public Product Enquiry and Product Requirement service paths now persist through the canonical `public_create_product_demand` flow instead of the retired enquiry/requirement public-write RPCs.
- Customer marketing opt-out uses the canonical global `public_stop_customer_marketing` contract.
- Retired enquiry/requirement/referral RPC execution is blocked in STAGING for anon/authenticated callers; canonical Product Demand and global STOP remain executable as intended.
- No fake Dealer, Staff, customer transaction, backup, restore or release evidence was created. Production, `main` and V27 remain untouched.
- This closes source/CI/staging-grant acceptance for the canonical public-write cleanup only. Genuine auth runtime, business transaction, backup/restore, Android real-device, production signing and production/domain gates remain OPEN.


## Current protected-routing CI evidence — 2026-09-27
- Exact Git SHA: `2ebedf21faa58e6dc14f9ccee8ec74163760d88b`.
- Build Check: SUCCESS.
- Cloudflare Preview: SUCCESS; exact live worker SHA verification and deployment evidence steps passed.
- Owner/Admin post-login navigation now targets the protected `/admin-workspace?auth=required` route; Accountant targets its protected workspace.
- STAGING has a genuine active Owner `OR@000`; Owner master-email OTP verification and authenticated session creation have been observed successfully. This is PARTIAL staff-auth evidence only: protected Owner workspace rendering still requires final runtime confirmation, and Admin/Accountant/Salesman/Store Keeper must not be fabricated merely to close acceptance.
- Dealer Hostinger TORVO OTP source/runtime is installed, but Dealer acceptance remains OPEN until a genuine approved staging Dealer exists.
- Production, `main`, V27 and production/domain cutover remain untouched.
