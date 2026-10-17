# TORVO V2 — Five-platform Hero Management (Owner decision)

Status: OWNER REQUIREMENT LOCKED; implementation and screen-fit measurements pending. Development branch only: torvo-v2-build. Do not modify production.

## Independent publishing targets
1. Public mobile website
2. Public desktop website
3. Dealer app home
4. Salesman app home
5. Store keeper app home

Each target has its own upload, preview, published asset and previous-version restore. Never share a hero across targets implicitly. Never show pricing, inventory, checkout or private dealer data on public heroes.

## Image dimensions — not yet locked
Do NOT enforce speculative pixel dimensions. Inspect actual header, navigation, safe area, device widths and existing screens first. Then publish a single fixed-size template per target with aspect ratio, content-safe zone and export instructions. A source image is not to be stretched; use contain/fill rules appropriate to the verified layout. Check 320px, 375px, 390px and 430px mobile widths, desktop 1280px and 1920px, and app screens with bottom navigation.

## Required functional actions
Buttons must be REAL accessible UI elements layered above the artwork, not painted into the bitmap. Per-target action schema must be explicitly mapped to existing, authorized navigation routes. Fixed normalized button coordinates must be locked per target after visual QA. If required action, label, route or coordinates are missing, prevent publication with actionable error. Cannot reliably detect whether a button is painted into an arbitrary uploaded image; provide safe-area templates and preview to prevent visual overlap.

## Owner workflow
Select platform → upload complete JPG/PNG/WebP artwork → validate type/size/aspect and image resolution → render responsive preview with real locked buttons → validate required actions → save draft → publish → allow rollback to previous published hero. Publishing one target must not change the other four.

## Migration / compatibility
Keep the existing public Hero unchanged until the owner-approved asset is published and previewed. The previous four independent hexagon-photo upload slots are retired from the desired UI; do not reactivate them. Preserve original TORVO branding, public search flow, and existing role permissions. Avoid duplicate backend/database/deployment. Audit logs must record actor, target, old/new asset, and time.

## Acceptance gates
1. Real screen dimensions verified and target-specific templates documented.
2. Independent uploads/permissions tested in staging.
3. Responsive preview and mandatory real button actions verified for all five targets.
4. Publish, rollback and failure behavior verified without affecting other targets.
5. Build, Cloudflare preview and Android test builds passed; owner reviews visuals.
