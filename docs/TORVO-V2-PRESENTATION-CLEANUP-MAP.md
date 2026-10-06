# TORVO V2 — PRESENTATION LAYER CLEANUP MAP

Status: ACTIVE CLEANUP AUDIT
Updated: 2026-10-01
Scope: presentation dependencies only. No business logic change.

## Current finding
The V2 entry currently loads a historical CSS chain plus four canonical consolidation layers. Several historical files are large and contain regression fixes or role-specific selectors, so filename age alone is NOT proof that deletion is safe.

## Canonical consolidation layers
- torvo-ui-system.css (RETIRED 06 OCT 2026 — historical visual overrides; must not be runtime-imported) — shared design tokens/foundation
- torvo-component-contract.css — shared controls/product/filter contract
- torvo-operational-ui.css — operational workspace presentation
- torvo-ai-integration-ui.css — AI/integration state presentation

## Current runtime classification (2026-10-01)

The authoritative runtime entries are `src/v2/preview-main.jsx` and `src/v2/main.jsx`. Both finish with the same canonical ownership chain and `torvo-ui-system.css (RETIRED 06 OCT 2026 — historical visual overrides; must not be runtime-imported)` last.

RETIRED FROM RUNTIME (blocked by automated guard, including indirect runtime references):
- workspace-polish.css
- dealer-mobile-fix.css
- premium-ui.css
- compact-cloud-ui.css
- secure-desktop-lock.css
- live-responsive-hotfix.css
- public-desktop-final.css
- dealer-search-lock.css
- final-ui-balance.css
- dealer-rewards-ui.css

ACTIVE STRUCTURAL / FEATURE-SPECIFIC LAYERS remain only where live components still depend on them, including styles.css, login-preview.css, purchase-requirements-ui.css, public-website.css, public-product-showcase.css, public-catalog-browser.css, smart-search-ui.css, smart-product-filters.css, role-app-preview.css, admin-desktop-polish.css, admin-search-v2.css and accountant-search-v2.css. Filename age is not deletion proof.

Current risk rule: do not bulk-delete or bulk-rewrite structural CSS. Some live structural files still contain dense historical override rules. Consolidate selector ownership only with dependency evidence, exact-SHA build verification and responsive regression checks.

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

Active structural compatibility layers remain only where current component structure still depends on them. Final visual authority is now `torvo-ui-system.css (RETIRED 06 OCT 2026 — historical visual overrides; must not be runtime-imported)`, loaded last. New presentation work must modify/consolidate the authoritative system instead of adding another FINAL/HOTFIX/PREMIUM override layer.

Theme rule after Owner final acceptance: keep the accepted TORVO design language fixed; future screens/features must use its components/tokens rather than replacing the theme.


## 2026-09-28 — DUAL ENTRY OWNERSHIP AUDIT

Runtime presentation ownership is now checked across BOTH V2 entries:
- `src/v2/preview-main.jsx` — Cloudflare/public preview entry.
- `src/v2/main.jsx` — app/Android operational entry.

Both entries now load the canonical presentation chain in this order:
1. `torvo-component-contract.css`
2. `torvo-operational-ui.css`
3. `torvo-ai-integration-ui.css`
4. `torvo-ui-system.css (RETIRED 06 OCT 2026 — historical visual overrides; must not be runtime-imported)` (last/final authority)

Removed from the app entry on 2026-09-28:
- `workspace-polish.css`
- `secure-desktop-lock.css`
- `live-responsive-hotfix.css`

The automated dependency guard now fails if any retired override is imported by either entry, if the canonical app ownership order changes, or if `torvo-ui-system.css (RETIRED 06 OCT 2026 — historical visual overrides; must not be runtime-imported)` stops loading last.

### Current app-only compatibility layers — NOT YET SAFE TO DELETE
- `accountant-admin-parity-fix.css`
- `app-install-ui.css`
- `backup-ui.css`
- `backup-close-ui.css`
- `dealer-addon-ui.css`
- `dealer-rewards-ui.css`
- `product-discovery.css`
- `login-ui.css`
- `dealer-search-lock.css`
- `final-ui-balance.css`

These remain dependency-audit candidates. Their presence does NOT make them final visual authority; the canonical chain loads after them. Do not remove them until unique live selectors are migrated or proven unused.

### Current preview-only structural layers
- `public-website.css`
- `role-app-preview.css`

They remain structural compatibility layers and are not deletion candidates without component-selector proof.

This dual-entry audit supersedes the older statement that the presentation verifier only represents the preview entry.


## 2026-10-06 — CLEAN FOUNDATION MIGRATION

Owner cancelled all historical visual locks and authorized a new unified TORVO presentation system.

Current final presentation primitive owner:
- `torvo-design-foundation.css` — tokens, typography, controls, accessibility, responsive baseline, and shared visual language.

Runtime rule:
- Both `main.jsx` and `preview-main.jsx` load `torvo-design-foundation.css` last.
- Historical/feature CSS may remain temporarily for structural selectors only.
- Do not add new FINAL/HOTFIX/PREMIUM layers.
- Migrate required selectors into explicit canonical owners, verify exact-SHA build/runtime, then remove obsolete imports/files.
- Public, Login/Registration, Dealer, Salesman, Store Keeper, Owner/Admin and Accountant must share one design language.
- Business/auth/data contracts remain unchanged by presentation migration.

First unified migration applied to public + authentication primitives at commit 0c5969b122e0d62129cf39597ddb0a4713f36d3e.


### Global Search + Filter acceptance rule — 2026-10-06
- Every primary page/workspace must keep search immediately reachable: PUBLIC WEBSITE, OWNER/ADMIN, ACCOUNTANT, DEALER, SALESMAN and STORE KEEPER.
- Use one TORVO search presentation pattern. Product-oriented search keeps INPUT → CAMERA → MIC → SEARCH where those capabilities are supported.
- Search scope is role/page-aware and server permissions remain authoritative.
- Product/data-heavy lists should pair search with the shared Smart Filter pattern where useful.
- Public search/filter must never expose private dealer rates, private stock, proprietary fitment/compatibility, or other private B2B data.
- Internal search must not broaden a role's existing authorization.
- Mobile search must remain full-width/reachable with touch-safe controls; desktop search must use the available horizontal workspace efficiently.


## 06 OCT 2026 — LEGACY VISUAL AUTHORITY RETIRED
`torvo-ui-system.css` is now a non-runtime archive. It contained historical FINAL/APPROVED/HARD-LOCK public and role presentation overrides that conflicted with the Owner-directed clean rebuild. Runtime visual ownership is structural feature CSS plus `torvo-component-contract.css`, `torvo-operational-ui.css`, `torvo-ai-integration-ui.css`, with `torvo-design-foundation.css` loaded last. Business, auth, data and security contracts are unchanged.
