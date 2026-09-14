# TORVO ANDROID UPDATE PUBLISHING

## LOCKED IDENTITY
- APP: TORVO TOOLS
- PACKAGE: `com.torvotools.app`
- A production update must use the same package and the approved production signing identity.

## TWO DIFFERENT CHANNELS
- `TEST-DEBUG`: CI test APK only. Never publish it as an installed-user production update.
- `PRODUCTION` / `PLAY` / `STABLE`: signed release only.

## DURABLE DOWNLOAD REQUIREMENT
The production APK URL stored in `app_release_artifacts.artifact_url` must be a durable HTTPS URL. A ChatGPT temporary attachment URL or a GitHub Actions artifact redirect must never be stored as the production update URL.

Recommended storage is a controlled object-storage/CDN location (for example a TORVO-owned Cloudflare R2 bucket/custom download domain) or the Play Store release channel. Storage credentials and signing keys must be provided as protected deployment secrets; they must never be committed to this repository.

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
- optional positive `min_supported_build`

The public app-update RPC exposes only a record satisfying these gates. Data/content/rate/stock changes continue to come from the backend and do not require reinstalling the app.
