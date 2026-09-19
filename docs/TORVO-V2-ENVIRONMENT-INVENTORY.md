# TORVO V2 ENVIRONMENT VARIABLE INVENTORY

Status: canonical names-only handover inventory. Never place secret values in this file.

## Public web / Vite build
- `VITE_SUPABASE_URL` — authoritative TORVO backend URL supplied to the V2 web/app build.
- `VITE_SUPABASE_ANON_KEY` — Supabase browser anon/publishable credential. This is not the service-role credential.
- `VITE_BUILD_SHA` — exact source commit stamped into a verified build.

## Cloudflare deployment
- `CLOUDFLARE_API_TOKEN` — protected CI secret used by Wrangler deployment.
- `CLOUDFLARE_ACCOUNT_ID` — protected Cloudflare account identifier used by CI.

## GitHub Actions runtime
GitHub-provided values such as `GITHUB_SHA`, `GITHUB_REF_NAME`, `GITHUB_RUN_ID` and `GITHUB_RUN_NUMBER` are runtime metadata, not TORVO secrets. They are used for exact-build evidence and release traceability.

## Supabase Edge Functions / trusted server runtime
Supabase platform-provided project/runtime credentials and any service-role credential must stay in the platform secret store. WhatsApp/OTP provider credentials, backup-worker/storage credentials, signing keys and other third-party secrets must also remain server-side. Do not prefix privileged credentials with `VITE_` and do not expose them to browser bundles.

## Android / store release
Production signing keystore/passwords and Play/App Store credentials are external protected secrets. They are intentionally not stored in this repository or portable backup package.

## Restore rule
A portable TORVO handover contains environment-variable NAMES and setup instructions only. Secret VALUES are recreated/configured in the destination provider secret stores after restore. Never copy production secrets into staging merely to make a rehearsal pass.

## Environment separation
- Production Supabase: `gckafjiitjocodlrwanm` — do not use for restore rehearsal.
- TORVO V2 STAGING: `jvmhhngjlaqrfopfavur` — current staging acceptance target.
- Source branch: `torvo-v2-build`.
- Fixed Cloudflare V2 address: `https://torvo-b2b-spare-parts.torvotools.workers.dev`.
- Netlify is retired/disabled and is not an alternate deployment path.

## Acceptance
Before production cutover, confirm the accepted exact commit has matching build/deploy evidence and that required secrets are configured in the intended target environment without being printed into logs, manifests, source files or backup artifacts.
