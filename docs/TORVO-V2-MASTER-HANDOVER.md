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
- Dealer may directly modify an eligible pre-Estimate Purchase Order only within the server-controlled modification allowance (default foundation: 2). Each accepted revision is audited and repriced server-side.
- When direct modification allowance is exhausted, Dealer can submit a Modification Request for TORVO review. Admin approval may grant an additional controlled chance; approval never silently edits rates/items.
- Estimate creation requires exact latest Dealer OK and is blocked if an Estimate already exists. Creating Estimate locks direct Sales Order revision.
- ADD MORE ITEMS is a request/approval flow, not an edit to the original document. After TORVO approval, Dealer selects products/qty and creates a separate linked Additional Purchase Order. The original Sales Order/Estimate remains immutable.
- Approved Add More Items can convert only once. Dealer ownership, approval status and current Dealer Rate Group/quantity pricing are validated server-side; duplicate conversion is blocked.
- Dealer Portal mounts the approved Additional Purchase Order panel and premium item-selection/rate-preview modal. Admin SalesWorkspace shows whether an approved Add More Items request is waiting for Dealer action or has produced its linked Additional Sales Order.
- SalesWorkspace has active Modify Order, Send for Dealer OK, Create Estimate and Dealer Change Request review controls wired to repository/RPC calls.
- Salesman-assisted order foundation exists and is server-scoped to mapped Dealers/areas. Runtime staging verification remains mandatory.

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

## PURCHASE — CURRENT AUTHORITATIVE FLOW
- Purchase is stock/rate/source history, NOT supplier accounting/ledger.
- Owner/Admin Purchase Entry records Supplier, Invoice No/Date, items, qty and Purchase Rate. Supplier + normalized Invoice No is duplicate-protected.
- Purchase Entry is the single authoritative supplier stock-receipt path. Saving an invoice increases inventory and writes inventory movement in the same controlled backend transaction.
- Legacy Inventory/Reorder direct stock receipt is retired. Reorder is planning only, preventing duplicate stock receipt.
- Purchase is immutable. Correction uses audited reversal with mandatory reason and is blocked if current stock cannot safely absorb the reversal.
- Owner can inspect actual invoice-wise Purchase Rate History. Purchase cost/rate history is not exposed to Salesman/Store Keeper/Dealer.
- Purchase Entry UI is premium/responsive for mobile and desktop. Runtime staging verification remains mandatory.

## PURCHASE REQUIREMENTS — CURRENT IMPLEMENTATION
- Salesman, Accountant and Store Keeper may submit Purchase Requirements; Owner/Admin review them.
- Existing Item request supports item/qty/reason and optional Dealer demand link.
- New Item request supports Brand/Company, Machine Type, Model, Part Name, OEM, Category, demand/remarks and optional Dealer link.
- Owner/Admin can Approve/Hold/Reject/Send to Purchasing.
- New Item requirement must be securely linked to exactly one active Item Master record before Purchase fulfilment. Linking is audited, creates no stock and refuses silent reassignment.
- Owner/Admin can link a real non-reversed Purchase containing the exact requirement item. Partial fulfilment is supported; full approved quantity completes the requirement.
- Backend blocks over-linking beyond Purchase quantity or remaining approved requirement. A Purchase already reversed cannot fulfil a requirement.
- Fulfilment-link reversal is audited and changes requirement tracking only; it never reverses Purchase stock or creates another inventory movement.
- Staff cannot directly add stock from a Purchase Requirement.

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
- GitHub/Vite success cannot validate PostgreSQL. All applicable migrations/RPCs must be executed against a separate Supabase staging project.
- Mandatory staging tests include role isolation; Dealer direct modification limits; change-request approval; approved Add More Items one-time linked-order conversion; original-document immutability; current server pricing; exact revision Dealer OK; stale OK rejection; Estimate lock; payment idempotency; once-only stock deduction; Purchase Entry/reversal; Purchase Requirement Item Master linkage/partial fulfilment; catalog master safety; Salesman scoping; Fitment privacy/no-points; and secret checks.
- Never point live domain at V2 or merge/replace V27/main until staging gate passes and Owner explicitly approves.

## CURRENT BUILD STATUS — 12-09-2026
Project remains in the 20-40% Dealer + Sales milestone. Do not call 40% complete until this milestone is materially implemented and runtime-verified.

ACTUAL SOURCE-CODE IMPLEMENTED in `torvo-v2-build` includes:
- Premium V2 app shell and role/module structure.
- Dealer secure rate lookup and Purchase Order submission repository/backend foundation.
- Dealer Portal quantity-based applicable rate/amount, cart total, Purchase Order submission and latest 30-day Sales Order/Estimate history.
- Controlled Sales Order revision RPC, Dealer direct self-modification allowance, Modification Request/Admin review, exact latest Dealer OK RPC and hardened Estimate boundary.
- Approved Add More Items -> separate linked Additional Purchase Order backend/repository/UI foundation with one-time conversion, Dealer ownership checks and server-side current pricing.
- Dealer Portal mounted Additional Purchase Order approval panel, premium searchable item/qty/rate-preview modal, retry/loading states and stale-rate-response protection.
- Admin SalesWorkspace shows approved Add More Items waiting/converted state and linked Additional Sales Order status.
- SalesWorkspace Modify Order, Send for Dealer OK and Create Estimate controls wired to repository calls.
- Dealer Portal Review & Give Dealer OK modal showing revision/items/qty/rate/amount/total.
- Query/Quotation RPC execution revoked from active V2 API; historical data is not deleted.
- Sales Team mapping/target and Salesman-assisted-order foundation.
- Purchase Entry secure supplier-invoice stock receipt, duplicate protection, audited reversal, Owner-only invoice-rate history and responsive UI.
- Inventory/Reorder duplicate stock receipt path retired; reorder remains planning only.
- Purchase Requirement secure Item Master linkage plus real Purchase partial/full fulfilment and audited fulfilment-link reversal.
- Dealer Fitment Suggestions/private Suitable Knowledge no-points migration + Dealer/Admin UI foundation.
- Premium catalog/master/dealer/inventory/dispatch/report foundations from earlier V2 work.

NOT YET CLAIMED VERIFIED:
- Supabase staging execution/compile of the migration chain and runtime RPC tests.
- Actual Vite/Netlify build/deploy of the latest commit; GitHub currently has no CI status check proving the build.
- Full WhatsApp OTP/provider/secure-link integration.
- Single-active Dealer session + inactivity PIN/OTP policy runtime flow.
- Complete Item Movement Center, Low Stock source/rate drilldown and Stock Conversion/Repacking UI/RPC.
- Final end-to-end payment -> dispatch/delivery -> exactly-once stock deduction staging proof.
- Full GST Admin switch/approval UI and remaining advanced modules.

## IMPORTANT NEXT WORK
1. Execute/verify the applicable SQL migration order against Supabase staging when a staging database action/connection is available.
2. Obtain a real Vite/Netlify build result for the latest V2 branch and repair compile/runtime UI errors found.
3. Build Item Master complete movement center + Low Stock source/rate drilldown.
4. Build atomic Stock Conversion/Repacking RPC + premium UI.
5. Complete sales-only reward reservation/redemption/next-bill adjustment lifecycle.
6. Complete staged Dealer onboarding WhatsApp OTP/call verification/secure details link.
7. Complete Admin GST switch/approval queue and remaining role dashboards/workspaces.
8. Run responsive/UI polish and actual preview verification after each meaningful batch.

## RECOVERY INSTRUCTION FOR A NEW CHAT
Read this file first, then inspect the latest `torvo-v2-build` branch before changing anything. Treat FINAL/CURRENT AUTHORITATIVE sections above as authoritative over older code/comments/chat assumptions. Continue actual implementation in meaningful batches, fresh-fetching SHAs before writes. Never touch V27/main without explicit final permission.
