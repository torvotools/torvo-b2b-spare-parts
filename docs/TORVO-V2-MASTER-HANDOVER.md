# TORVO V2 MASTER HANDOVER

Last updated: 12-09-2026
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## NON-NEGOTIABLE SAFETY
- V27/main is old/live and must remain untouched while V2 is developed.
- Never merge/replace main without final verification and explicit owner permission.
- Remote torvo-v2-build is the code source of truth. Fetch current SHA before every write.
- No fake data, fake WhatsApp sent states, fake prices, fake availability, secrets or insecure shortcuts.
- SQL committed to GitHub is NOT considered Supabase-runtime verified until actually executed/tested in staging.

## FINAL BUSINESS DIRECTION
TORVO V2 is a B2B operational portal, not accounting software. Product priority: Machine -> Spare Part -> Accessory. Registered/approved dealers only.

## DEALER SALES FLOW — CURRENT AUTHORITATIVE RULE
- Dealer sees server-calculated applicable rate and amount before submitting.
- Dealer-facing name: PURCHASE ORDER. TORVO internal name for the same business document: SALES ORDER.
- Active flow is Purchase Order -> TORVO Sales Order -> controlled revision if required -> latest Dealer OK -> Estimate -> internal payment/fulfilment -> delivery.
- Query/Quotation is retired from the active V2 API. Historical rows may remain; do not build new workflow on Query/Quotation.
- Owner/Admin/authorized Accountant may revise a Sales Order before Estimate. Every revision is audited and rates are recalculated server-side from the Dealer's current A/B/C rate group; client-supplied rates are not trusted.
- Any TORVO revision invalidates previous Dealer OK and requires the Dealer to review/confirm the exact latest revision again.
- Dealer OK is accepted only for the linked Dealer's own Sales Order, only while status is awaiting Dealer OK, and only when the submitted revision equals the current revision.
- Estimate creation requires exact latest Dealer OK and is blocked if an Estimate already exists. Creating Estimate locks direct Sales Order revision.
- Dealer Portal now has latest-revision review and Give Dealer OK UI. SalesWorkspace has active Modify Order, Send for Dealer OK and Create Estimate controls wired to repository RPC calls.
- Salesman-assisted order foundation exists and is server-scoped to mapped Dealers/areas. Runtime staging verification remains mandatory.
- Future enhancement still required: Dealer self-modification allowance/default count, modification-request-after-limit, and linked ADD MORE ITEMS/NEXT ORDER without corrupting prior/final documents.

## DEALER PAYMENT PRIVACY — FINAL
- Dealer Portal shows NO payment data: no pending/received/cash/UPI/bank/outstanding/accounting-entry number.
- Payment communication/transaction happens outside portal via WhatsApp/offline/accounting process.
- TORVO Owner/Admin/Accountant may internally note payment information.
- Outstanding/balance is TORVO-private. External accounting entry number may be stored internally with actor/time/audit; this does not mean Dealer paid.
- Payment changes must remain auditable. Payment idempotency migration requires a unique request key.

## DEALER HISTORY — FINAL
- Dealer Portal normal order/estimate/delivery history displays latest 30 days only.
- Older records remain in TORVO database/audit and are hidden only from normal Dealer view.
- Dealer gets CONTACT WHATSAPP FOR ACCOUNT DETAILS, opening a prepared request to TORVO support. Automatic WhatsApp sent state is prohibited until provider integration is verified.

## DEALER FITMENT SUGGESTIONS / PRIVATE SUITABLE KNOWLEDGE — FINAL
- Dealer may suggest that a TORVO Spare Part fits another Machine/Model or respond to a TORVO fitment request.
- This feature earns ZERO TORVO Points. TORVO Points are only from eligible actual sales/final paid billing under the separate sales reward system.
- Owner/Admin review each suggestion as Correct/Verified, Partly Correct, Wrong/Rejected or Duplicate.
- Only eligible Verified/Partly Correct known-item fitment may be promoted to TORVO PRIVATE Suitable Master.
- Dealers must never see another Dealer's submissions or TORVO's private cross-compatibility intelligence.
- `v2-knowledge-rewards.sql` retains a legacy filename for compatibility but now implements Dealer Fitment Suggestions / Private Suitable Knowledge, not knowledge rewards.
- Migration removes obsolete knowledge-only point columns/ledger from earlier V2 drafts, without touching the separate sales `reward_ledger`.
- Fitment tables use RLS/direct-access restrictions; Dealer-facing reads/writes use scoped security-definer RPCs. Owner/Admin direct reads are policy-controlled.

## PURCHASE — FINAL DIRECTION
- Purchase module is stock/rate/source history, NOT supplier accounting/ledger.
- Basic supplier: Supplier/Party Name, Company, Invoice No, Invoice Date, items, quantity, purchase rate. Optional basic contact/city/GSTIN.
- Show invoice total only as reference/history. No supplier debit/credit/paid/balance ledger.
- Duplicate supplier+invoice protection.
- Item purchase entry should show prior date-wise purchase rates, supplier/party and invoice history in a popup/side panel.
- Purchase save adds stock through controlled inventory movement.
- Purchase edit/return must preserve audit and adjust stock safely; no silent overwrite.

## PURCHASE REQUIREMENTS — CURRENT
- Salesman, Accountant and Store Keeper may submit Purchase Requirements; Owner/Admin can review.
- Existing item request includes current item/required qty/reason and optional Dealer demand link.
- New item request supports Brand/Company, Machine Type, Model, Part Name, OEM, Category, demand/remarks/photo and optional Dealer link.
- Admin review supports Approve/Modify Qty/Hold/Reject/Purchasing foundation. Staff cannot directly add stock from a requirement.
- Schema/RPC/UI foundation exists. Purchase fulfilment/partial-purchase linkage remains pending.

## ITEM MASTER / MOVEMENT HISTORY — FINAL
- Clicking an item should open a complete movement center: identity, stock, reorder, purchased/sold, last purchase/sale rate and date-wise movement.
- Filters include date, purchase/sale/all, supplier, Dealer, brand, category, model, invoice and rate ranges. Print/PDF/Excel should respect active filters.
- Movement history derives from real records, not duplicated fake history.

## LOW STOCK — FINAL
- Low/out-of-stock view shows current qty/reorder level plus previous source, purchase rates and dates.
- Filter by brand/category/supplier and allow controlled reorder/purchase action.

## STOCK CONVERSION / REPACKING — FINAL
- TORVO may buy stock under another source/brand and convert/repack part to TORVO.
- Preserve original source, supplier, invoice, purchase rate, conversion qty/date/actor and target TORVO item.
- Conversion must atomically decrement source and increment target exactly once with audit and controlled reversal.

## REWARDS — FINAL DIRECTION
- TORVO Points are sales-only. Fitment/knowledge suggestions never earn points.
- Financial-year scheme defaults: Apr-Jun, Jul-Sep, Oct-Dec, Jan-Mar unless Owner changes rules.
- Wallet should support current/carry-forward/current-quarter/available/next reward progress.
- Redemption lifecycle must reserve points first, prevent double-use, and keep earned/redemption history separate.
- Do not claim automated third-party voucher issuance without a real provider/API or TORVO-controlled code.

## WHATSAPP
- Dealer registration OTP preference is WhatsApp OTP.
- Deal/order events should support SEND WHATSAPP and SEND WHATSAPP + SECURE LINK where relevant.
- Current Sales Order Dealer-OK action records `prepared_not_sent`, not a fake delivery state.
- Actual automatic sending requires approved provider/API and testing.
- TORVO support number currently 7027751533 and should be Admin-changeable.

## DELIVERY
- Delivery charges apply to Accessories and Machines.
- Spare Parts delivery free only when spare-parts purchase value is at least Rs 10,000.
- Stock deduction must happen exactly once at the final approved delivery/fulfilment operation after required payment state; never at Estimate creation merely because payment was noted.

## UI — NON-NEGOTIABLE
- Premium modern app-style TORVO UI is required across Home, Login, Admin, Salesman, Accountant, Store Keeper and Dealer screens.
- Mobile-first, responsive across mobile/tablet/laptop/desktop/large screens; no tiny/huge/overflow layouts.
- Strong filters/search are a priority, especially Spare Parts. Search supports item code/OEM/name/brand/category/model/type and controlled compatibility contexts.
- Popup-first for practical Add/Edit/Approve/Hold/Rate Change/Send Link actions.
- TORVO red accent with coherent premium palette; no fake figures/counts/badges.
- Buttons should be wired through UI -> business logic -> authorized backend/RPC -> database -> success/error state wherever the backend is available; avoid knowingly leaving core buttons as decorative placeholders.

## SECURITY / ROLES
OWNER full. ADMIN operational/admin. SALESMAN mapped Dealer/order/sales only. ACCOUNTANT internal estimate/payment/accounting work and authorized internal order modification. STORE KEEPER stock/pick/pack/dispatch without sensitive rates/profit. DEALER approved linked portal only. Compatibility/private Suitable Owner/Admin. Purchase Cost/Profit Owner-only unless explicitly changed.

## SALES TEAM — CURRENT IMPLEMENTATION
- Salesman area mappings, Dealer mappings and Monthly/Quarterly/FY targets have schema/RPC foundation.
- Owner/Admin Sales Team workspace supports area mapping, Dealer assignment/transfer and target setup.
- Salesman dashboard supports My Dealers, My Areas, target progress, assisted Dealer Order and Purchase Requirement entry.
- Server-side Salesman Dealer scoping is required; UI filtering is never the security boundary.
- Runtime staging compilation/data tests are still pending.

## SQL INSTALL / RELEASE GATE
- `supabase/V2_INSTALL_ORDER.md` is the authoritative dependency order.
- Current order includes `v2-sales-revision-rpcs.sql` after sales-team/assisted dependencies and before Purchase Requirements.
- GitHub/Vite success cannot validate PostgreSQL. All applicable migrations/RPCs must be executed against a separate Supabase staging project.
- Mandatory staging test includes role isolation, exact revision Dealer OK, stale OK rejection, Estimate lock, payment idempotency, once-only stock deduction, catalog master safety, Salesman scoping, Fitment privacy/no-points and secret checks.
- Never point live domain at V2 or merge/replace V27/main until staging gate passes and Owner explicitly approves.

## CURRENT BUILD STATUS — 12-09-2026
Project remains in the 20-40% Dealer + Sales milestone. Do not call 40% complete until this milestone is materially implemented and runtime-verified.

ACTUAL SOURCE-CODE IMPLEMENTED in `torvo-v2-build` includes:
- Premium V2 app shell and role/module structure.
- Dealer secure rate lookup and Purchase Order submission repository/backend foundation.
- Dealer Portal quantity-based applicable rate/amount, cart total, Purchase Order submission and latest 30-day Sales Order/Estimate history.
- Controlled Sales Order revision RPC, exact latest Dealer OK RPC and hardened Estimate boundary.
- SalesWorkspace Modify Order, Send for Dealer OK and Create Estimate controls wired to repository calls.
- Dealer Portal Review & Give Dealer OK modal showing revision/items/qty/rate/amount/total.
- Query/Quotation RPC execution revoked from active V2 API; historical data is not deleted.
- Sales Team mapping/target and Salesman-assisted-order foundation.
- Purchase Requirement schema/RPC/UI foundation.
- Dealer Fitment Suggestions/private Suitable Knowledge no-points migration + Dealer/Admin UI foundation.
- Premium catalog/master/dealer/inventory/dispatch/report foundations from earlier V2 work.

NOT YET CLAIMED VERIFIED:
- Supabase staging execution/compile of the migration chain and runtime RPC tests.
- Full WhatsApp OTP/provider/secure-link integration.
- Single-active Dealer session + inactivity PIN/OTP policy runtime flow.
- Dealer self-modification allowance/request-more-changes/add-on order lifecycle.
- Purchase fulfilment linkage, Purchase Return/edit atomicity, complete Item Movement Center, Low Stock source drilldown and Stock Conversion/Repacking UI/RPC.
- Final end-to-end payment -> dispatch/delivery -> exactly-once stock deduction staging proof.
- Full GST Admin switch/approval UI and remaining advanced modules.

## IMPORTANT NEXT WORK
1. Continue source-level dependency/security review for the current sales/payment/delivery chain, then execute the full applicable SQL order in Supabase staging as soon as a staging database connection/action is available.
2. Implement Dealer self-modification allowance + Request Modification + linked Add More Items/Next Order without changing finalized history.
3. Implement Purchase Requirement fulfilment/partial-purchase linkage.
4. Build Purchase save/edit/return atomic RPCs and purchase-rate-history UI.
5. Build Item Master complete movement center + Low Stock source/rate drilldown.
6. Build atomic Stock Conversion/Repacking RPC + premium UI.
7. Complete sales-only reward reservation/redemption/next-bill adjustment lifecycle.
8. Complete staged Dealer onboarding WhatsApp OTP/call verification/secure details link.
9. Complete Admin GST switch/approval queue and remaining role dashboards/workspaces.
10. Run responsive/UI polish and actual preview verification after each meaningful batch.

## RECOVERY INSTRUCTION FOR A NEW CHAT
Read this file first, then inspect the latest `torvo-v2-build` branch before changing anything. Treat FINAL/CURRENT AUTHORITATIVE sections above as authoritative over older code/comments/chat assumptions. Continue actual implementation in meaningful batches, fresh-fetching SHAs before writes. Never touch V27/main without explicit final permission.
