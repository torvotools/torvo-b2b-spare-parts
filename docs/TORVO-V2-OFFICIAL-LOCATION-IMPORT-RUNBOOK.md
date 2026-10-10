# TORVO V2 — Official LGD location import runbook

**Status: BLOCKED until official matching Government of India CSV exports are available.** Never invent location records.

## Source
- https://lgdirectory.gov.in/demo/downloadDirectory.do
- https://data.gov.in/catalog/local-government-directory-lgd

Obtain full matching official snapshots of states, districts, and urban local bodies. Keep original exports, publication/download dates and SHA-256 hashes outside the repo. The government download interface may require a human CAPTCHA; do not bypass it.

## Procedure
1. Verify file provenance, expected column headers, numeric LGD codes, and local-body type distinguishing urban from rural.
2. Dry-run from repository root:
   `node scripts/import-v2-official-location-master.mjs --states <states.csv> --districts <districts.csv> --local-bodies <local-bodies.csv>`
3. Review counts and validation errors. Refuse unknown local-body types, duplicate LGD codes/names, or missing parent relations.
4. Only after successful dry-run and staging confirmation, securely configure `SUPABASE_URL` for staging project `jvmhhngjlaqrfopfavur` and `SUPABASE_SERVICE_ROLE_KEY` without logging/committing secrets.
5. Run same command with `--apply` **on staging only**. The importer refuses a different project ref and checks LGD code coverage after upload.
6. REST batch upserts are **not atomic**. If interrupted, investigate partial rows and rerun idempotently with the same verified snapshot; do not claim success after partial failure.
7. Reconcile states/districts/cities and public location RPCs. Test State → District → City, OTHER / ADD CITY, saved-form hydration, retry, and actual authorized dealer registration.
8. Record source hashes, exact Git SHA, counts, test screenshots, and runtime evidence in final acceptance ledger.

## Acceptance
As of 2026-10-10, staging counts were states=0, districts=0, cities=0. Recheck immediately before import. An urban-local-body city master does not include all villages; OTHER / ADD CITY remains necessary. `node scripts/verify-v2-location-dropdowns.mjs` checks source contracts only, not live data. No production changes, fake data or unverified PASS claims.
