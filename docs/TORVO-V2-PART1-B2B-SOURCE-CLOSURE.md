# TORVO V2 — PART 1 DEALER B2B SOURCE CLOSURE

Status: SOURCE-SIDE COMPLETE
Branch: `torvo-v2-build`
Scope: Dealer B2B order / estimate / additional PO / payment / fulfilment / delivery lifecycle.

## CLOSED SOURCE FLOW

`PURCHASE ORDER -> SALES ORDER -> CONTROLLED REVISION -> EXACT LATEST DEALER OK -> ESTIMATE -> PAYMENT / FULFILMENT -> LINKED ADDITIONAL PURCHASE ORDER WHEN REQUIRED -> PICK / PACK -> READY FOR DISPATCH -> TRACKING CODE -> DELIVERED`

## SOURCE INVARIANTS

1. Dealer commercial actions use approved-device/session-bound services and server RPCs.
2. Dealer rates remain server-calculated; public/customer pricing is not part of this flow.
3. A TORVO revision invalidates the previous Dealer confirmation; the latest revision requires exact Dealer OK.
4. Once an Estimate exists, the original Sales Order / Estimate is not mutated for extra items.
5. Extra items use only a separate linked Additional Purchase Order. The legacy generic `ADD MORE ITEMS` modification path is blocked in both visible Dealer UI and compatibility service bridge.
6. Additional PO eligibility requires a valid Estimate linkage to the original Sales Order and supports authoritative/current linkage plus valid historical linkage fields.
7. Payment and fulfilment are separate states. Dealer UI never exposes Owner-only purchase cost, profit, internal stock accounting or staff accounting data.
8. Received payment is bounded by Estimate payable; displayed balance is derived safely from payable minus received.
9. Tracking / dispatch code is exposed only at READY FOR DISPATCH or DELIVERED.
10. Delivered timestamp is exposed only for DELIVERED state.
11. Delivery history deduplicates by Estimate and follows the canonical fulfilment lifecycle.
12. Dealer private workspace re-verifies the approved device/session on app resume/focus and private order/payment/delivery events.
13. Cross-device changes refresh while the Dealer App is active through lifecycle events plus visible polling.
14. Original Sales Order / Estimate remains unchanged when a linked Additional PO is created.
15. Main/V27 is not part of this development closure and must remain untouched.

## MAIN SOURCE SURFACES

- `src/v2/components/DealerPortal.jsx`
- `src/v2/components/DealerPortalMounted.jsx`
- `src/v2/components/DealerAdditionalPOWorkspace.jsx`
- `src/v2/components/DealerDirectAdditionalPOModal.jsx`
- `src/v2/components/DealerApprovedAddOnOrders.jsx`
- `src/v2/components/DealerPaymentFulfilment.jsx`
- `src/v2/components/DealerDeliveryTracking.jsx`
- `src/v2/services/dealerB2BFlow.js`
- `src/v2/services/dealerOrders.js`
- `src/v2/services/dealerLegacyBridge.js`
- `supabase/v2-dealer-order-device-bound.sql`
- `supabase/v2-dealer-payment-fulfilment.sql`
- `supabase/v2-dealer-delivery-tracking.sql`
- `supabase/v2-delivery-stock-integrity.sql`
- `supabase/V2_INSTALL_ORDER.md`

## NOT CLAIMED BY THIS CLOSURE

This is a source-code closure, not a production/runtime certification. The following remain release work and belong to final integration/QA:

- compile/apply the authoritative migration chain in the identified Supabase staging project;
- run real Dealer/Staff end-to-end transactions against staging;
- verify payment, stock deduction, dispatch and delivery exactly once under concurrency/retry;
- verify WhatsApp/provider/session runtime behaviour;
- responsive/native-device QA;
- verify exact GitHub build SHA against the staging/production deploy SHA.

These runtime items must be completed before TORVO V2 is called production-ready.

## NEXT DEVELOPMENT BLOCK

Proceed to Part 2: PUBLIC WEBSITE + CUSTOMER -> NEARBY DEALER -> REQUIREMENT / REFERRAL, following `docs/TORVO-V2-MASTER-HANDOVER.md` and the Owner requirement lock. No public TORVO retail checkout or public Dealer A/B/C rates.
