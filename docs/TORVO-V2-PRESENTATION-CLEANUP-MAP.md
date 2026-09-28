# TORVO V2 — PRESENTATION LAYER CLEANUP MAP

Status: ACTIVE CLEANUP AUDIT
Updated: 2026-09-27
Scope: presentation dependencies only. No business logic change.

## Current finding
The V2 entry currently loads a historical CSS chain plus four canonical consolidation layers. Several historical files are large and contain regression fixes or role-specific selectors, so filename age alone is NOT proof that deletion is safe.

## Canonical consolidation layers
- torvo-ui-system.css — shared design tokens/foundation
- torvo-component-contract.css — shared controls/product/filter contract
- torvo-operational-ui.css — operational workspace presentation
- torvo-ai-integration-ui.css — AI/integration state presentation

## Historical layers still ACTIVE BY IMPORT
styles.css
workspace-polish.css
login-preview.css
dealer-mobile-fix.css
premium-ui.css
compact-cloud-ui.css
admin-desktop-polish.css
admin-search-v2.css
accountant-search-v2.css
purchase-requirements-ui.css
public-website.css
public-product-showcase.css
public-catalog-browser.css
smart-search-ui.css
smart-product-filters.css
role-app-preview.css
secure-desktop-lock.css
live-responsive-hotfix.css
public-desktop-final.css

These are NOT safe-to-delete merely because newer layers load after them.

## Risk finding
live-responsive-hotfix.css and public-website.css are very large and likely contain accumulated regression ownership. Removing or merging them blindly is high risk.
secure-desktop-lock.css explicitly protects privileged desktop geometry.
login-preview.css remains role/auth presentation-specific.
dealer-mobile-fix.css remains responsive/registration-specific.
Therefore the safe strategy is selector-by-selector consolidation, not bulk deletion.

## Cleanup protocol
1. Inventory actual component class names.
2. Map each historical selector to a live component or mark unreferenced.
3. Move still-required shared rules into the canonical layer that owns them.
4. Remove an import only after its required rules have migrated.
5. Build and exact-SHA preview verification after every removal batch.
6. Keep Git history as rollback/audit evidence.
7. Never change business logic during presentation cleanup.

## Deletion classification
ACTIVE: imported and not yet proven redundant.
RETIRED: no runtime import, retained only in Git history.
SAFE TO DELETE: zero required selectors/dependencies + replacement verified by build/runtime checks.

At this audit point, no historical CSS file is yet classified SAFE TO DELETE.


## Automated retirement gate
The V2 preflight now runs `scripts/verify-v2-presentation-dependencies.mjs`.

A presentation layer may move from ACTIVE to SAFE TO DELETE only when all of the following are true:
1. its required live selectors have been migrated to a named canonical owner;
2. no live component depends on a unique selector/rule from that layer;
3. its import is removed deliberately together with the dependency-guard inventory update;
4. V2 Build Check passes for the exact resulting SHA;
5. Cloudflare Preview passes for the exact resulting SHA;
6. Android APK CI passes when the change affects shared/app presentation.

Current exact-SHA evidence before any retirement:
- SHA `b098eb955c5a690ace21a083af41e4e1cf7634aa`
- TORVO V2 Build Check #2898 — SUCCESS
- TORVO V2 Cloudflare Preview #2229 — SUCCESS
- TORVO V2 Android APK #2187 — SUCCESS (build evidence only; not real-device acceptance)

Current classification remains: no historical presentation file is yet proven SAFE TO DELETE.


## 2026-09-28 — NEW TORVO DESIGN OWNERSHIP
Owner requested a genuine full-system presentation replacement rather than continued old-theme polishing.

Retired from runtime imports (files retained temporarily only as historical/reference until dependency-safe deletion):
- workspace-polish.css
- dealer-mobile-fix.css
- premium-ui.css
- compact-cloud-ui.css
- secure-desktop-lock.css
- live-responsive-hotfix.css
- public-desktop-final.css

Active structural compatibility layers remain only where current component structure still depends on them. Final visual authority is now `torvo-ui-system.css`, loaded last. New presentation work must modify/consolidate the authoritative system instead of adding another FINAL/HOTFIX/PREMIUM override layer.

Theme rule after Owner final acceptance: keep the accepted TORVO design language fixed; future screens/features must use its components/tokens rather than replacing the theme.
