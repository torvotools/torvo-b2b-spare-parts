# TORVO V2 — SUPABASE STAGING INSTALL ORDER

Authoritative dependency order. Never install migrations alphabetically and never call GitHub source runtime-verified until staging passes.

## LOCKED BUSINESS ARCHITECTURE
- PUBLIC CUSTOMER HAS NO TORVO RETAIL PRICE, CHECKOUT, COD, PAYMENT OR PUBLIC RETURN FLOW.
- CUSTOMER DISCOVERS PRODUCTS -> PRICE-FREE ENQUIRY -> APPROVED DEALER; CUSTOMER AND DEALER FINALIZE RETAIL RATE/PAYMENT/DELIVERY.
- CONFIRMED CUSTOMER PRODUCT REQUIREMENTS AND NO-MATCH SEARCH REQUESTS ARE CAPTURED AS PRIVATE TORVO DEMAND/OPPORTUNITY DATA; RAW TYPING ALONE MUST NOT CREATE A CONFIRMED LEAD.
- CUSTOMER CONTACT DATA IS NEVER BROADCAST PUBLICLY; DEALER CONTACT UNLOCK/ROUTING MUST FOLLOW CONTROLLED LEAD CONSENT/RULES.
- DEALER PROCUREMENT REMAINS PRIVATE B2B WITH A/B/C RATE GROUPS.
- WEBSITE, ONE APP AND SECURE DESKTOP USE ONE AUTHORITATIVE BACKEND.
- NEW DEALER APPLICATION -> ACCOUNTANT VERIFICATION / CORRECTION -> SUBMIT TO ADMIN -> OWNER/ADMIN FINAL APPROVAL. ACCOUNTANT NEVER FINAL-ACTIVATES A DEALER.
- ONE DEALER ACCOUNT MAY HAVE ONLY ONE ACTIVE APP DEVICE SESSION AT A TIME.
- SALESMAN / STORE KEEPER / ACCOUNTANT NORMAL LOGIN = ADMIN USERNAME + ONE-TIME PASSWORD; NO EMPLOYEE MOBILE REQUIRED.
- SALESMAN / STORE KEEPER PASSWORD IS CONSUMED ON FIRST LOGIN; APPROVED APP SESSION CONTINUES UNTIL LOGOUT/REVOKE. NEXT LOGIN NEEDS A NEW ADMIN PASSWORD.
- ACCOUNTANT IS DESKTOP-ONLY AND NEEDS A NEW ADMIN-ISSUED ONE-TIME PASSWORD FOR EACH NEW LOGIN SESSION.
- NEW STAFF DEVICE REQUIRES OWNER/ADMIN APPROVAL; REPLACEMENT DEVICE REVOKES PREVIOUS DEVICE.
- MASTER SALESMAN IS EXPLICIT SERVER-SIDE GRANT; NORMAL SALESMAN IS MAPPED-ONLY.

## SAFETY
- Dedicated V2 staging first; stop on first SQL error.
- No service-role keys, provider secrets, plaintext passwords, PINs, OTP secrets or private tokens in GitHub/browser code.
- `SUPABASE_SERVICE_ROLE_KEY` exists only as a Supabase Edge Function secret/environment variable.
- Server derives authenticated role/user/dealer identity; never trust browser-supplied role/dealer identity.

## INSTALL SEQUENCE
1. CORE: `v2-schema.sql` -> `v2-core-dealer-identity.sql`, then role/profile/base RLS/security dependencies. The canonical `app_users.dealer_id` link MUST exist here before any Dealer final-approval RPC; mobile is never an authorization key. Later `v2-dealer-pin-auth.sql` keeps its `ADD COLUMN IF NOT EXISTS` only for idempotent upgrade compatibility.
2. CATALOG: catalog/item/master/rate/search foundations + dependent RPCs.
3. SALES: sales/order foundations -> `v2-sales-order-integrity.sql` -> `v2-additional-purchase-order.sql`.
4. PURCHASE + INVENTORY: inventory + canonical movement and final Purchase integrity migrations.
5. PURCHASE REQUIREMENTS: base -> RPC -> item link -> fulfilment -> receipt integrity -> `v2-accountant-stock-requirement-view.sql`.
6. PAYMENT / DELIVERY: payment/dispatch foundations -> `v2-delivery-stock-integrity.sql`.
7. RETURNS BASE after Delivery + received Purchase integrity.
8. CENTRAL MAKER-CHECKER and final approval boundaries.
9. FINANCIAL REPORTING: inventory movement, low-stock/reorder and Purchase Cost History/reporting read layers first; after delivered Sales, Purchase Cost History and Sales Return foundations exist, install `v2-expense-profit-integrity.sql`. Business expenses remain private, reversals are audited, and the profit summary is OWNER-only. Profit must use authoritative delivered Sales, completed Sales Returns and historical Purchase cost; missing historical cost must be reported rather than invented.
10. Private Suitable/fitment and Dealer/role privacy foundations, including `v2-knowledge-rewards.sql` base.
11. CUSTOMER/DEALER NETWORK BASE and public referral/repair/registration/service-area/support foundations. Install `v2-customer-dealer-referral-network.sql` exactly once here. After it install `v2-customer-marketing-consent-segmentation.sql`; marketing profile data is voluntary, consent-audited and private. After both customer contact + marketing-consent foundations exist, install `v2-customer-product-demand-leads.sql` to capture confirmed product requirements and missing-range demand without exposing Customer contact publicly. The public CustomerApp runtime-contract migration is installed later in CENTRAL ADMIN CONTROL after its managed-experience dependency exists. After `v2-public-dealer-registration.sql`, install `v2-accountant-dealer-verification.sql`, then after `v2-business-rpcs.sql` install `v2-dealer-final-approval-accountant-gate.sql`. The Step 1 canonical Dealer identity foundation is a mandatory prerequisite for this final approval gate.
12. REFERRAL TO B2B BASE DEPENDENCIES.
13. FIELD/STORE: salesman field network -> dealer-salesman mapping -> `v2-master-salesman-access.sql` -> `v2-salesman-attendance.sql` -> `v2-salesman-referral-otp-statement.sql` -> store keeper boundary. The Salesman referral OTP/statement migration is installed only after both the Step 11 customer/dealer referral network and the dealer-salesman mapping exist. OTP delivery remains a trusted WhatsApp worker/provider responsibility; plaintext OTP is never stored or returned to the client.
14. CENTRAL ADMIN CONTROL -> `v2-accountant-workspace-buttons.sql` after `app_users` -> `v2-admin-managed-experience.sql` -> `v2-customer-public-runtime-contract.sql`. The final public runtime contract is installed here so CustomerApp locator/referral/settings RPC names match the client only after both customer/dealer network and Admin-managed experience dependencies exist. Daily website/app/social/marketing/feature configuration must be changed through Owner/Admin backend controls instead of source edits wherever the setting is operational content/configuration rather than executable code or a security rule.
15. PRODUCT DIGITAL CONTENT and public showcase -> `v2-product-promotion-popularity.sql` -> `v2-product-promotions.sql` -> `v2-product-promotion-analytics.sql`. Promotions may target WEBSITE, DEALER APP or BOTH; Popular Items are ranked by Admin feature/rank then available popularity signals. Inactive products are excluded. Promotion analytics records privacy-safe idempotent VIEW -> CLICK -> ENQUIRY -> DEALER_ORDER funnel events; Owner/Admin analytics reads only aggregated counts.
16. PRODUCT/DRAFT MEDIA after app_users.
17. AUTH: `v2-staff-whatsapp-auth.sql` -> `v2-admin-issued-staff-access.sql` -> `v2-dealer-pin-auth.sql` -> `v2-auth-worker-runtime-grants.sql` -> `v2-business-login-routing.sql`.
18. FINAL DEALER DEVICE BOUNDARIES after auth assertion exists: first install `v2-dealer-inactivity-control.sql` after the Dealer active-session/auth foundation exists, then `v2-dealer-catalog-search.sql` -> `v2-dealer-machine-spares.sql` -> `v2-dealer-missing-part-request.sql` -> `v2-referral-to-b2b-order-conversion.sql` -> `v2-dealer-knowledge-device-bound.sql` -> `v2-dealer-order-device-bound.sql` -> `v2-dealer-procurement-device-bound.sql` -> `v2-dealer-workspace-device-bound.sql` -> `v2-dealer-final-actions-device-bound.sql` -> `v2-customer-repair-device-bound.sql` -> `v2-customer-demand-dealer-routing.sql` -> `v2-customer-demand-lead-lifecycle.sql` -> `v2-customer-demand-found-lifecycle.sql`. Dealer inactivity control uses authoritative delivered business activity, warns after three consecutive inactive months, and leaves suspension/reactivation strictly Owner/Admin-controlled; it never auto-deletes or auto-suspends a Dealer. Customer demand routing is installed here because Dealer inbox/accept/decline requires `dealer_assert_my_device_session`; lifecycle then gives Owner/Admin a private lead center, audited close, truthful AVAILABLE result and audited conversion/closure. The Customer demand foundation from Step 11 is also a prerequisite. Dealer sees requirement details first and customer contact unlocks only after that assigned Dealer explicitly accepts the lead. The customer/dealer referral network base from Step 11 and customer public runtime contract from Step 14 are prerequisites here and MUST NOT be re-run. Repair inbox/read/update becomes device-bound here and legacy no-device repair signatures are dropped.
19. DEALER TARGET REWARDS: `v2-dealer-target-rewards.sql` -> `v2-dealer-target-reward-settlement.sql` after approved Dealer/app_users/audit and delivered Sales Order foundations. Target slabs are Owner/Admin-controlled; annual scheme year is APRIL-MARCH; only authoritative DELIVERED sales value qualifies; each achieved slab settles once through a unique settlement record; claim cancellation reverses a debit once; points are never earned from fitment suggestions or arbitrary per-invoice billing.
20. DEPLOY AUTH EDGE FUNCTIONS only after DB auth boundary: `_shared/torvo-auth.ts`, `dealer-pin-login`, `dealer-session-valid`, `dealer-session-revoke`, `staff-one-time-login`.
21. SECURE DESKTOP verification against Accountant desktop/device boundary.
22. BACKUP control -> channels -> worker contract.
23. APP RELEASE CENTER: `v2-app-release-center.sql`; release metadata writes remain CI/trusted-worker only and Owner/Admin can read verified release status.
24. APP NOTIFICATIONS: `v2-role-push-notifications.sql` after `app_users`; Owner/Admin may publish role-targeted messages to DEALER, SALESMAN, STORE KEEPER or ACCOUNTANT. After Step 18 Customer lead routing/lifecycle and this notification foundation both exist, install `v2-customer-lead-notifications.sql`; it targets only the specifically assigned approved Dealer app user and never copies Customer name/mobile/WhatsApp into notification data.
25. DEMO RESET after backup/audit dependencies; Dashboard/admin/business/reporting and later modules after prerequisites.

## ADMIN-MANAGED CONFIGURATION GATE
- OWNER/ADMIN may change supported public website text/notices, official social links, app notices, marketing defaults, PRODUCT PROMOTIONS, POPULAR/FEATURED ITEMS, APP DOWNLOAD LINKS and safe feature switches from backend-driven controls without a source-code deployment.
- EVERY admin configuration write requires a reason and audit log.
- PUBLIC receives only settings explicitly marked `public_read`; private app/marketing/feature controls are never exposed by the public RPC.
- SECURITY, AUTHORIZATION, DATABASE INTEGRITY, PACKAGE IDENTITY, SIGNING AND EXECUTABLE PROGRAM LOGIC ARE NOT editable as arbitrary Admin JSON/code. Those remain protected release/code changes.
- SOCIAL LINKS are data/configuration: once official URLs are entered in Admin, public website/app readers use backend values without recoding.
- PRODUCT ADS may target WEBSITE, DEALER APP or BOTH and must have active/time boundaries. INACTIVE PRODUCTS MUST NEVER BE PROMOTED.
- POPULAR ITEMS support Admin FEATURED override plus automatic popularity signals; the public surface never exposes Dealer A/B/C rates.

## CUSTOMER DEMAND / OPPORTUNITY GATE
- A CONFIRMED `REQUEST THIS ITEM` action may create a demand lead; ordinary partial search typing must not be treated as a confirmed Customer requirement.
- FOUND PRODUCT and MISSING PRODUCT requirements are both retained so TORVO can measure demand and source missing range.
- CUSTOMER NAME/MOBILE/WHATSAPP remain private tables/RPC output; public callers receive only the created demand identifier/status.
- OWNER/ADMIN may read the private demand inbox and aggregated demand summary for sourcing/range decisions.
- OWNER/ADMIN private CUSTOMER LEADS CENTER may combine requirement, customer contact and assigned Dealer status; this privileged read is never granted to public/Dealer roles.
- CLOSING a requirement closes its still-open Dealer lead assignments and writes an audit entry with the supplied reason.
- OWNER/ADMIN may mark an active requirement AVAILABLE only with truthful found information; an optional found Dealer must be APPROVED. The Customer result RPC requires matching demand ID + mobile proof and exposes the found contact note only while status is AVAILABLE.
- CONVERSION requires AVAILABLE status, records `converted_at`, closes remaining open Dealer assignments and writes an audit entry before the requirement becomes CLOSED.
- DEALER notification/routing is controlled: Owner/Admin may assign only an active requirement to an APPROVED Dealer. Dealer inbox is device-bound and contains requirement/area data but no customer contact. Only the assigned Dealer that explicitly ACCEPTS the lead may receive the necessary Customer name/mobile/WhatsApp. Declined/unassigned Dealers never receive contact.
- CUSTOMER LEAD ALERTS target only the assigned active approved Dealer app user. Alert body contains requirement and area/PIN only; Customer name/mobile/WhatsApp remain private until accepted through the device-bound lead RPC.
- LOCAL / EXTENDED routing labels do not themselves prove distance. 0-25 KM / 25-50 KM claims require truthful coordinates, geocoding or service-area evidence; never infer kilometres from a PIN string alone.

## MANDATORY DEALER DEVICE GATE
- Dealer item-rate resolution and Purchase Order submission require current device proof server-side; browser cannot select another Dealer/rate group.
- Private Dealer workspace catalog reads require current device proof; revoked old mobile must not keep browsing the private ordering workspace.
- Purchase Order quantities are integer 1..9999 and duplicate catalog item lines fail.
- Machine-spare, fitment, referral, missing-part, repair inbox/update and protected order actions require current device proof.
- Sales Order confirmation, revision, modification request, approved Add More Items read/create, Additional Purchase Order request and 30-day order history require current device proof.
- Customer demand lead inbox/accept/decline requires current Dealer device proof; contact unlock is permitted only after an assigned lead is accepted.
- Dealer business UI must call the dedicated device-proof services; direct legacy repository RPC shortcuts are release blockers.
- Build/App/Android verification must fail if legacy no-device machine-spare, rate, Purchase Order or repair client calls return.
- Legacy no-device signatures must be absent after final migrations.
- Revoked old mobile must fail every protected Dealer mutation/read even while its Supabase Auth token has not yet expired.

## MANDATORY STAFF ACCESS GATE
- `SM@01`-style username is Admin-managed and independent of employee mobile number.
- Only one current unused one-time password; issuing another revokes previous.
- SALESMAN/STORE KEEPER = approved `mobile_app`; ACCOUNTANT = approved `desktop`.
- Logout/revocation means next login needs a fresh Admin-issued password.
- MASTER SALESMAN grant/revoke is Owner/Admin controlled and audited server-side.
- SALESMAN attendance uses authenticated server identity; a salesman can check in once per date, check out only after check-in, and read only self attendance through RPCs.
- ACCOUNTANT SIDEBAR WORKSPACES ARE OWNER/ADMIN-MANAGED; ACCOUNTANT CAN READ ENABLED WORKSPACES BUT CANNOT CREATE, REORDER, ENABLE OR DISABLE THEM.

## APP NOTIFICATION GATE
- OWNER/ADMIN chooses one or more target roles; the server resolves recipients from active users.
- Every published message remains in the recipient's backend inbox even if native push delivery is temporarily unavailable.
- Native Android/iOS push uses registered app-device tokens and a trusted server/worker provider integration; provider credentials are server-only.
- UPDATE, ACCOUNT/ACCESS, BUSINESS and GENERAL messages may carry a safe action key/value for app routing; notification content must never change authorization rules.
- CUSTOMER LEAD notifications are direct-recipient alerts, not role-wide broadcasts; the assigned Dealer receives requirement/area only and must use the secure lead acceptance flow to unlock Customer contact.

## RETIRED / DO NOT ENABLE
- `v2-public-retail-pricing-foundation.sql`
- `v2-public-checkout-payment-modes.sql`

## MANDATORY GENERAL STAGING GATE
- Role authorization/privacy for OWNER, ADMIN, SALESMAN, ACCOUNTANT, STORE KEEPER, DEALER and PUBLIC CUSTOMER.
- Public cannot read Dealer Rate A/B/C, private fitment, purchase cost or privileged Customer data.
- Public catalog has no TORVO selling price/checkout/payment.
- Dealer PIN is hashed and one active Dealer device rule is server-enforced.
- ONE APP routes by authoritative authenticated role.
- Purchase/payment/Delivery/Return integrity and maker-checker remain final authority.
- Expense/Profit integrity must pass before release: direct financial tables stay private; expense recording/reversal is role-controlled and audited; profit is OWNER-only, delivered-Sales based, Return-aware, historical-cost based, and reports missing cost instead of fabricating it.

## APP RELEASE GATE
- Owner/Admin APP RELEASE tab reads release metadata through `admin_app_release_center()` only.
- Browser cannot write release metadata or mark an artifact verified.
- APK/AAB/iOS download is shown only when status is VERIFIED/PUBLISHED and a trusted artifact URL exists.
- DATA/CONTENT changes flow from the central backend without native reinstall; PROGRAM/CODE changes require a new verified native release.
- INSTALLED APP checks verified production update metadata on startup, foreground/resume and periodically; package identity remains `com.torvotools.app`.

## ANDROID / LIVE RELEASE GATE
- Exact release SHA Build Check and FINAL READINESS contract must pass.
- Android artifact must install/open on a real Android device before production-ready claim.
- Debug APK is TEST ONLY; public release requires private signing and signed AAB/APK.
- External provider credentials and custom domain/DNS remain deployment gates.

## RELEASE EVIDENCE
Retain migration branch/commit, role/security results, exact web build/deploy SHA, Android artifact and real-device test evidence. No final-live claim without it.