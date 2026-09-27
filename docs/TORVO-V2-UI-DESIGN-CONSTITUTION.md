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
LOCKed business/UI requirements remain respected.
"22" means restore/reference the pre-redesign visual baseline at commit `47eb263662d7a4e552bbb73e18483d35435e90e7`.
