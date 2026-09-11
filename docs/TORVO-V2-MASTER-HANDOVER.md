# TORVO V2 MASTER HANDOVER

Last updated: 11-09-2026
Authoritative repository: torvotools/torvo-b2b-spare-parts
Development branch: torvo-v2-build

## NON-NEGOTIABLE SAFETY
- V27/main is old/live and must remain untouched while V2 is developed.
- Never merge/replace main without final verification and explicit owner permission.
- Remote torvo-v2-build is the code source of truth. Fetch current SHA before every write.
- No fake data, fake WhatsApp sent states, fake prices, fake availability, secrets or insecure shortcuts.
- SQL committed to GitHub is NOT considered Supabase-runtime verified until actually executed/tested in staging.

## FINAL BUSINESS DIRECTION
TORVO V2 is a B2B operational portal, not accounting software. Machine -> Spare Part -> Accessory. Registered/approved dealers only.

## DEALER SALES FLOW — FINAL
- Dealer selects products and must see the applicable dealer rate/amount before submitting.
- Dealer-facing document name: PURCHASE ORDER. TORVO internal name for the same business document: SALES ORDER.
- Remove Quotation from the main sales process. Old Query/Quotation code is superseded and must be refactored, not extended.
- Dealer initially gets approximately 2 direct modifications (default 2; configurable). Show remaining count.
- Every change creates revision/history: actor, date/time, before/after and reason.
- Dealer can modify only through Sales Order stage. After allowance is exhausted, dealer sends REQUEST MODIFICATION with reason; Admin can allow another chance.
- Admin/authorized Accountant internal modifications are not count-limited but must be audited. Material TORVO changes invalidate prior Dealer OK and require new OK.
- Dealer can ADD MORE ITEMS / NEXT ORDER as a linked add-on without corrupting prior/final records.
- Once Estimate exists, dealer cannot directly edit. Dealer may only request modification; TORVO controls reopening/change.
- Dealer-facing journey should remain Purchase Order -> Estimate Submitted -> Estimate Approved/OK -> Delivery/Dispatch.

## DEALER PAYMENT PRIVACY — FINAL
- Dealer Portal must show NO payment data: no pending/received/cash/UPI/bank/outstanding/accounting-entry number.
- Payment communication/transaction happens outside portal via WhatsApp/offline/accounting process.
- TORVO Owner/Admin/Accountant may internally note payment information.
- Outstanding/balance is TORVO-private. When it is entered into external accounting software, staff enters ACCOUNTING ENTRY NO and marks ACCOUNTING ENTERED / PAYMENT OK for portal workflow purposes.
- This does NOT mean dealer paid. It means the balance has been transferred/recorded in external accounting software.
- Active pending report then clears it, but history permanently retains balance, accounting entry number, date/time and actor.
- Payment entries may be modified by authorized staff with reason; old/new values must remain in payment revision/audit history.

## DEALER HISTORY — FINAL
- Dealer Portal normal order/estimate/delivery history displays only latest 30 days.
- Older records are not deleted from TORVO database/audit; only hidden from normal dealer view.
- Dealer gets CONTACT WHATSAPP FOR ACCOUNT DETAILS. It opens a prefilled request to TORVO support WhatsApp. TORVO supplies older detail manually.

## PURCHASE — FINAL DIRECTION
- Purchase module is stock/rate/source history, NOT supplier accounting/ledger.
- Basic supplier: Supplier/Party Name, Company, Invoice No, Invoice Date, items, quantity, purchase rate. Optional basic contact/city/GSTIN.
- Show invoice total only as reference/history. No supplier debit/credit/paid/balance ledger.
- Duplicate supplier+invoice protection.
- Item purchase entry should show prior date-wise purchase rates, supplier/party and invoice history in a popup/side panel.
- Purchase save adds stock through controlled inventory movement.
- Purchase edit/return must preserve audit and adjust stock safely; no silent overwrite.

## ITEM MASTER / MOVEMENT HISTORY — FINAL
- Clicking an item must open a complete movement center.
- Show item identity, current stock, reorder level, total purchased/sold, last purchase rate, last sale rate.
- Date-wise PURCHASE history: supplier, invoice, qty, rate.
- Date-wise SALES history: dealer/party, qty, sales rate, date/document.
- Filters: date range, purchase/sale/all movement, supplier, dealer, brand, category, model, invoice, purchase/sale rate ranges, low/out of stock.
- Print/PDF/Excel should respect active filters.
- Movement history should derive from real purchase/sales/inventory records, not duplicated fake history.

## LOW STOCK — FINAL
- Low/out-of-stock view must show current qty/reorder level plus where the item was previously sourced and at which purchase rates/dates.
- Filter low stock/out of stock by brand/category/supplier and allow controlled reorder/purchase action.

## STOCK CONVERSION / REPACKING — FINAL
- TORVO may purchase an item as another brand/source (example BDI) and repack/convert part of stock to TORVO for sale.
- Preserve original source trace: source item/brand, supplier, invoice, purchase rate, conversion qty/date/actor -> target TORVO item.
- Conversion must atomically decrement source stock and increment target stock exactly once with audit.
- Sale after conversion can be TORVO branded, while internal history can trace back to original purchase source.
- Controlled reversal/history; never silently edit stock.

## REWARDS — FINAL DIRECTION
- Financial-year scheme split into 4 quarterly periods unless owner changes rule: Apr-Jun, Jul-Sep, Oct-Dec, Jan-Mar.
- Points wallet: current/carry-forward/current-quarter/available/next reward progress.
- Reward catalogue/slabs configurable by Admin.
- Redemption choices: gift voucher/coupon OR use eligible points as next-bill adjustment.
- Redemption request reserves points first; no double-use. Coupon target SLA displayed 24-48 hours. Admin can enter/upload coupon details/code and issue it. Dealer can confirm received and used.
- Next-bill points are reserved then explicitly deducted on applicable Final Estimate: gross + charges - points adjustment = net payable. Cancel before use returns reservation.
- New earned points remain separate from old redeemed points.
- Do not claim automated Amazon/Flipkart issuance without real provider/API or TORVO-controlled codes.

## WHATSAPP
- Dealer registration OTP preference is WhatsApp OTP.
- Deal/order events should support SEND WHATSAPP and SEND WHATSAPP + SECURE LINK where relevant.
- Never record a fake sent state. Actual automatic sending requires approved provider/API and testing.
- TORVO support number currently 7027751533 and should be Admin-changeable.

## DELIVERY
- Delivery charges apply to Accessories and Machines.
- Spare Parts delivery free only when spare-parts purchase value is at least Rs 10,000.
- Stock deduction must happen exactly once at the final approved dispatch/delivery operation according to the finalized fulfilment RPC; never at Estimate creation merely because payment was noted.

## UI
- Premium modern app-style TORVO UI, mobile-first but responsive across mobile/tablet/laptop/desktop/large screens.
- Strong filters/search. Search supports item code/OEM/name/brand/category/model/type/compatibility.
- Popup-first for practical Add/Edit/Approve/Hold/Rate Change/Send Link actions.
- TORVO red accent; no fake figures.

## SECURITY / ROLES
OWNER full. ADMIN operational/admin. SALESMAN dealer/order/sales. ACCOUNTANT internal estimate/payment/accounting work and authorized internal order modification. STORE KEEPER stock/pick/pack/dispatch without sensitive rates/profit. DEALER approved portal only. Purchase Cost/Profit owner-only unless explicitly changed.

## CURRENT BUILD STATUS
Project milestone remains 20-40% Dealer + Sales System. Do not claim 40% complete until materially implemented and verified. Current V2 preview is Netlify branch preview. DealerVisual/AdminVisual/LoginVisual/DealerRegistration previews exist. DealerPortal has 30-day visible history and WhatsApp older-detail request, but secure dealer-rate Purchase Order submission is still pending. SalesWorkspace has begun replacement of old quotation semantics. Purchase/item-history/conversion schema groundwork exists but UI/RPC atomic operations remain pending.

## IMPORTANT PENDING NEXT WORK
1. Secure dealer-rate lookup and Purchase Order submission RPC; dealer sees correct applicable rate/amount before submit.
2. Sales Order revision/modification/Dealer OK RPCs and UI; Estimate boundary and add-on order.
3. TORVO private outstanding/accounting report UI + payment modify revision RPC.
4. Purchase save/edit/return RPCs with stock atomicity; purchase-rate history UI.
5. Item Master complete movement history + filters + print/PDF/Excel.
6. Low-stock source/rate drilldown.
7. Atomic Stock Conversion/Repacking RPC + UI.
8. Rewards reservation/redemption/next-bill adjustment lifecycle.
9. Staged dealer onboarding WhatsApp OTP/call verification/secure details link.
10. Execute and validate SQL in Supabase staging before production claims.

## RECOVERY INSTRUCTION FOR A NEW CHAT
Read this file first, then inspect the latest torvo-v2-build branch before changing anything. Treat FINAL sections above as authoritative over older code/comments/chat assumptions. Continue actual implementation in meaningful batches, fresh-fetching SHAs before writes. Never touch V27/main without explicit final permission.
