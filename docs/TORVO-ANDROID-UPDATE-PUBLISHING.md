# TORVO ANDROID UPDATE PUBLISHING

## LOCKED IDENTITY
- APP: TORVO TOOLS
- PACKAGE: `com.torvotools.app`
- A production update must use the same package and the approved production signing identity.
- The package ID must never change between installed production versions.

## TWO DIFFERENT CHANNELS
- `TEST-DEBUG`: CI test APK only. Never publish it as an installed-user production update.
- `PRODUCTION` / `PLAY` / `STABLE`: signed release only.
- The durable TEST prerelease is intentionally separate from the production update RPC and production release table state.

## DURABLE VERIFIED TEST APK
The Android CI workflow publishes the latest successful TEST-DEBUG APK as a GitHub prerelease using the stable tag `torvo-v2-test-latest` and stable asset name `TORVO-TOOLS-TEST-latest.apk`.

The TEST release must always:
- be a GitHub prerelease;
- contain `TORVO-TOOLS-TEST-latest.apk` and `release-manifest.json`;
- identify package `com.torvotools.app`;
- identify channel `TEST-DEBUG`;
- identify `production_signed=false`;
- identify status `VERIFIED_TEST`;
- contain the exact build commit SHA and APK SHA-256;
- verify that the durable APK byte hash matches the APK produced by the current workflow run.

This stable TEST link replaces temporary ChatGPT attachment links for device testing. It is not a production app-update source and must never be inserted into `public_android_app_update()` metadata.

## DURABLE PRODUCTION DOWNLOAD REQUIREMENT
The production APK URL stored in `app_release_artifacts.artifact_url` must be a durable HTTPS URL. A ChatGPT temporary attachment URL, GitHub Actions artifact redirect, signed expiring blob URL, or TEST prerelease URL must never be stored as the production update URL.

Recommended production storage is a controlled object-storage/CDN location (for example a TORVO-owned Cloudflare R2 bucket/custom download domain) or the Play Store release channel. Storage credentials and signing keys must be provided as protected deployment secrets; they must never be committed to this repository.

## PUBLISH RECORD
A production Android record must contain:
- `platform=android_apk`
- `status=published`
- `package_id=com.torvotools.app`
- `channel=production|play|stable`
- `production_signed=true`
- positive `build_number`
- exact 40-character commit SHA
- durable HTTPS `artifact_url`
- exact lowercase 64-character APK SHA-256
- optional positive `min_supported_build` not greater than the published build
- non-null `published_at`

The public app-update RPC exposes only a record satisfying these gates.

## UPDATE BEHAVIOR
- DATA / CONTENT / RATES / STOCK / DEALER / COMPATIBILITY changes come from the central backend and do not require reinstalling the app.
- Native PROGRAM / CODE / UI changes require a new signed app version.
- Play Store installations can use the Play Store update mechanism.
- Direct APK installations can show an UPDATE AVAILABLE action to a verified durable production APK, but Android still requires the user/device to approve installation unless an authorized managed-device mechanism is used.
- A production update is accepted only when package identity, signing identity, release metadata and artifact integrity all remain valid.
