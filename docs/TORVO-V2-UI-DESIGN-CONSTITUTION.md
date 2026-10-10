# TORVO V2 — UI/UX DESIGN CONSTITUTION

Status: ACTIVE for the post-"22" redesign.
Rollback baseline "22": Git commit `47eb263662d7a4e552bbb73e18483d35435e90e7`.
This document governs visual presentation only. Existing approved business logic is not changed by this redesign.

## 1. One product, one visual language
Website, Owner/Admin, Accountant, Dealer, Salesman and Store use the same TORVO tokens and component rules. Layout density may differ by job and device, but equivalent controls must look equivalent.

## 2. Core visual tokens
- Palette: TORVO RED for primary/action/attention; near-black for navigation/authority; white surfaces; neutral greys for hierarchy.
- Typography: one sans-serif stack; normal-weight entered text; restrained bold only for headings, totals and primary labels.
- Geometry: square to lightly softened. No random pill/large rounded cards.
- Borders: normal control/card 1px medium grey; focused/selected TORVO red; disabled light grey; destructive/error red. Same semantic state = same border everywhere.
- Shadows: subtle elevation only for overlays, menus and floating panels. Normal cards do not use heavy shadows.
- Spacing: 4/8px rhythm. No arbitrary page-specific spacing.
- Icons: one stroke family and standard sizes. Prefer real product photography over generic product icons whenever genuine product media exists.

## 3. Search and filter
Search + Filter is a first-class TORVO working surface.
- Search order: INPUT -> CAMERA -> MIC -> SEARCH.
- Desktop: logo left, maximum useful search width center, prominent Filter adjacent.
- Filter uses the same shell everywhere, while available fields are role/data appropriate.
- Common product drill-down: Product Type -> Brand -> Machine Type -> Machine/Model -> Category/Part -> Item.
- Active filters remain visible and clearable.
- Mobile filter opens a full usable sheet; desktop filter opens a wide working panel.
- Do not expose private rates, private stock or restricted data on public website.

## 4. Product-first presentation
- Product photo is the primary visual when genuine media is available.
- Cards reserve a consistent image area; no image stretching.
- Item No. and compatibility remain legible.
- Generic icons are fallbacks, not the preferred product representation.
- Lists/tables may use compact thumbnails where useful.

## 5. Public website hierarchy
Header/Search -> Hero advertisement -> moving brand rail -> exactly three primary categories:
MACHINES / SPARE PARTS / ACCESSORIES -> filter/product discovery -> featured/products -> dealer/customer flow -> support/company information -> premium footer.
Subcategories stay inside the three primary categories, not as extra top-level category buttons.

## 6. Secure desktop
Owner/Admin and Accountant use a professional information-dense desktop shell:
- stable dark navigation rail
- consistent top search/filter
- white work surfaces on neutral background
- compact KPI/cards
- clear tables/forms
- no oversized marketing decoration in operational screens.

## 7. Role apps
Dealer, Salesman and Store are mobile-first:
- compact TORVO header
- search/filter near the top
- product photography where applicable
- thumb-friendly actions
- consistent bottom navigation
- desktop/tablet adaptation without changing role logic.

## 8. Forms
All forms share label, helper, validation and control rules.
Normal = medium-grey 1px.
Focus/selected = TORVO red.
Disabled/read-only = light grey.
Error = red plus readable message.
Required state is explicit.
No page may invent its own border darkness/radius.

## 9. Tables, reports and operational data
Consistent header height, row density, alignment, status chips and filters. Financial columns stay right-aligned. Long tables prioritize readability over decorative cards.

## 10. Buttons
Primary = TORVO red.
Secondary = white/neutral border.
Navigation/authority = black when appropriate.
Destructive = red only with destructive context.
Equivalent action = equivalent height, radius and weight across TORVO.

## 11. Responsive rule
Mobile is intentionally designed, not a squeezed desktop. Desktop is intentionally dense, not an enlarged mobile screen.

## 12. Change control
No new business logic is introduced as part of UI modernization unless Owner explicitly requests it.
Business, security, privacy, data-integrity and production-safety constraints remain authoritative.
The Owner has explicitly unlocked prior visual/UI locks for the current deep-audit modernization: obsolete, inconsistent or weaker visual presentation may be corrected without preserving historical styling merely because it was previously visually locked. Functional/business behavior must not be changed merely for cosmetics.
"22" remains a historical rollback/reference baseline at commit `47eb263662d7a4e552bbb73e18483d35435e90e7`; it is not the current visual ceiling.

## OWNER RULE — NO DUPLICATE UI ACTIONS (2026-09-28)
- New UI/UX must REPLACE or CONSOLIDATE an older button/option when both perform the same job on the same surface.
- Never stack a new presentation control on top of an older equivalent merely to preserve historical UI.
- Preserve the underlying business capability; remove only redundant presentation entry points after confirming equivalent access remains.
- The same capability may appear in genuinely different contexts (for example desktop finder vs modal/mobile flow) when each context needs its own entry point; this is not a duplicate.
- One surface should have one clear primary action for one job. Secondary entry points must have a distinct context or purpose.
- Before final UI acceptance, audit Website, Dealer, Salesman, Store Keeper, Owner/Admin and Accountant for duplicate buttons, duplicate navigation, duplicate cards and obsolete presentation layers.

## OWNER RULE — FLUID RESPONSIVE + REFRESH STABILITY (2026-09-28)
- Every TORVO page and component must adapt to the actual viewport; no desktop-sized content on small screens and no unnecessarily narrow mobile-sized shell on large screens.
- Refresh must preserve the same canonical structure: no white flash caused by competing presentation owners, no duplicate/vanishing sections, no stray content, and no breakpoint-dependent stacking surprises.
- Images/product cards reserve stable geometry so loading does not cause avoidable layout jumps.
- Final responsive visibility ownership is deterministic: mobile and desktop variants must never be visible together at the same breakpoint.
- Historical CSS/presentation rules that conflict with the final design system must be quarantined, consolidated, or retired dependency-safely rather than layered indefinitely.

## OWNER RULE — FULL DESKTOP CANVAS (2026-09-28)
- Public Website must use the available desktop/laptop viewport instead of behaving like a fixed narrow centered page.
- Laptop, standard desktop, large desktop and ultra-wide layouts must fluidly adjust gutters, columns, hero proportions and product grids to the actual viewport.
- Full-width does not mean stretched text: readable copy widths and component proportions remain controlled while sections use the available canvas.
- Mobile/tablet responsive behavior remains independently protected.

## OWNER OVERRIDE — 10 OCTOBER 2026: PROFESSIONAL DESIGN FREEDOM
Owner explicitly authorizes professional redesign and color changes across TORVO V2. The earlier RED/BLACK/WHITE/GREY palette and visual locks are no longer mandatory restrictions where an improved cohesive professional design is justified. This supersedes visual-only constraints, including prior LOCK-1 styling, but NOT functional/security requirements, original TORVO brand identity/logo, approved business workflows, public privacy boundaries or production-release gates. Select one premium accessible palette and unified reusable design system across all six surfaces; do not make arbitrary per-screen color changes. Preserve usable responsiveness, search order, form behavior and functional controls. Implement changes in reviewed compatible batches with exact-SHA CI and device/visual acceptance, avoiding needless disruption. Owner's goal: best professional quality, not a fixed color.


## CONTINUOUS DEVELOPMENT + OWNER FEEDBACK RULE (2026-10-10)
Owner direction: Keep the full TORVO V2 premium redesign and functional-completion program moving forward. The owner will refresh staging and send visual or behavioral feedback as needed. Each new feedback item is an addition to the active plan, not a replacement for the unfinished work.

Mandatory execution discipline:
1. At each NEXT/N, read fresh remote HEAD, CI state, this constitution and relevant source; continue the highest-priority safe unfinished module.
2. Maintain two parallel tracks: (A) main six-surface screen-to-screen premium UI/UX, working backend flows and acceptance; (B) owner-reported issues integrated into the relevant module.
3. Fix owner-reported regressions promptly, then resume track A automatically. Do not get stuck endlessly polishing one component while other screens remain unfinished.
4. Cover every click-through screen, form, dialog, empty/loading/error/success state and mobile/tablet/desktop layout. Do not claim that CSS-only changes complete functional acceptance.
5. Preserve the approved logo, data, permissions and business rules. Never invent business transactions or success states; keep unconnected controls explicitly unavailable until implemented.
6. For each batch record exact commit, verified CI/deployment status, what changed, what remains and the next continuation point. Avoid claiming 100% until actual device and end-to-end acceptance.
7. Work only on torvo-v2-build and staging. Production changes require explicit owner approval.
