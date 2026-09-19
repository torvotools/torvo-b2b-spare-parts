# TORVO V2 FINAL ACCEPTANCE EVIDENCE

Status: OPEN — evidence ledger for the remaining runtime/external gates.
Branch: `torvo-v2-build`.

This file prevents source completion from being confused with production acceptance. A gate becomes PASS only when the listed real evidence exists. Never manufacture identities, transactions, backup artifacts, signing evidence or deployment evidence merely to mark a gate complete.

| Gate | Required real evidence | Current verified state |
| --- | --- | --- |
| Dealer auth/device | Approved real staging Dealer; PIN/OTP path; Device B invalidates Device A; revoked device fails private reads/writes | OPEN — staging currently has no active Dealer acceptance identity |
| Staff auth/role | Authorized staging Salesman/Store Keeper/Accountant; one-time password/device/runtime boundary tests | OPEN — staging currently has no active Staff acceptance identity |
| B2B transaction | Real staging PO -> Sales Order -> exact Dealer OK -> Estimate -> payment/fulfilment -> dispatch -> delivery, including retry/idempotency checks | OPEN — no qualifying staging transaction evidence recorded |
| Purchase/inventory/returns | Real receipt/stock movement/delivery deduction/return or reversal with exactly-once and role checks | OPEN — no qualifying staging transaction evidence recorded |
| Reports | Reports Center totals/details reconciled against the accepted staging transactions and role privacy checked | OPEN — requires accepted transaction data |
| Backup/restore | Trusted-worker backup artifact + SHA-256/integrity + manifest + exact code/schema identity + isolated clean-target restore + core/security/runtime comparison | OPEN — no verified backup/restore rehearsal artifact recorded |
| Android test | Exact-SHA TEST-DEBUG APK installed on real Android device; package/hash/build SHA recorded; core login/business/UI checks | OPEN until real-device evidence is recorded |
| Android production | Privately signed release AAB/APK, preserved signing identity, version/build, store/release evidence and Owner acceptance | EXTERNAL/OPEN |
| Cloudflare exact SHA | Build Check + Cloudflare live evidence for the exact final accepted commit | VERIFIED CI EVIDENCE — current verified code SHA `2839fcb4e00b1d4de7d685b79d38966dbcec1a01`: Build Check #2114 SUCCESS; Cloudflare Preview #1440 SUCCESS. Final acceptance remains OPEN until this SHA (or a later accepted SHA) is frozen with all other applicable gates PASS |
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
- Catalog permanent-delete runtime gate remains OPEN: `permanently_delete_catalog_master(uuid,text)` is not installed in STAGING; source presence or CI protection is not accepted as runtime evidence.
- Dealer/Staff and business transaction runtime gates remain OPEN because STAGING has no acceptance identities or qualifying transactions; no fake records are to be created merely to close gates.
- This supersedes prior SHA CI evidence only; it does not convert runtime/external gates to PASS.

## Latest exact-HEAD CI evidence — 2026-09-19
- Exact Git SHA: `7592d05a1d33f5060dce54bc0daa93fe21aee896`.
- Build Check #2115: SUCCESS.
- Cloudflare Preview #1441: SUCCESS.
- Android APK #1408: SUCCESS (CI/build evidence only; real-device installation and production signing remain OPEN).
- This confirms the repaired Cloudflare live-evidence path on the current branch HEAD. Runtime identity/transaction, backup/restore rehearsal, catalog permanent-delete runtime installation, real-device Android, production signing, and production/domain gates remain OPEN.

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
