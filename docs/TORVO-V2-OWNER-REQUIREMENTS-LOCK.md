# TORVO V2 OWNER REQUIREMENTS LOCK

Purpose: permanent no-omission checklist for TORVO V2 development. This supplements `TORVO-V2-MASTER-HANDOVER.md`; it does not replace it. If implementation and this checklist differ, stop and reconcile against the latest explicit Owner-approved requirement before release.

## DEVELOPMENT ORDER
- Finish functional logic/backend/database/security and end-to-end flows before cosmetic-only polishing.
- Continue only on `torvo-v2-build`; never change V27/main without explicit Owner release permission.
- Website, App and Desktop share one authoritative Supabase backend and central business logic. Content/data changes should propagate from backend; native code changes require a versioned signed release.

## FORM / DROPDOWN-FIRST RULE
- Use dropdowns/selectors to the fullest practical extent across Website, App, Desktop and Admin forms whenever the value comes from a known master, fixed option set or linked business list.
- Prefer searchable dropdowns for long lists and linked/dependent dropdowns where relationships exist, especially STATE -> DISTRICT -> CITY, BRAND -> MACHINE/TYPE/MODEL, CATEGORY, PRODUCT TYPE, RATE A/B/C, STATUS, ROLE, BUSINESS TYPE, DEALER, SUPPLIER, SCHEME and report/filter selections.
- Reuse authoritative master data instead of allowing free-text duplicates. A selection should save the stable underlying ID/value while displaying the approved business label.
- Dependent dropdowns must reset invalid child selections when the parent changes and must not permit a stale child value from another parent.
- Keep free-text inputs only where genuinely open/custom data is required, such as Customer/Contact name, mobile, detailed address, description/notes and Item/OEM number where no authoritative master selection exists.
- Dropdown-first design must reduce spelling mistakes, duplicate master values and inconsistent reporting; it must not weaken server-side validation or role/security rules.

## PUBLIC CUSTOMER WEBSITE
- Public discovery for MACHINE -> SPARE PART -> ACCESSORY, product photo/detail, requirement capture, nearby Dealer referral, Dealer public profile, map/directions, call/WhatsApp, Dealer registration and support.
- The general Customer website/homepage must not expose a generic APP DOWNLOAD / INSTALL CTA. TORVO Business App install/download belongs inside Dealer registration/onboarding or other authorized business-access surfaces only, because the App is for Dealer, Salesman and authorized Store/Business staff rather than ordinary Customers.
- No public TORVO selling price, Dealer A/B/C rate, purchase cost, public TORVO checkout/payment/COD/refund flow.
- Customer selects product first; product identity must follow the referral.
- Capture minimum useful Customer data: name, mobile/WhatsApp, PIN/location, product/requirement, timestamp, selected/contacted Dealer where available.
- Marketing consent is separate, auditable and revocable; never infer marketing consent from a referral.
- Lead source attribution supports WEBSITE/FACEBOOK/INSTAGRAM/YOUTUBE/WHATSAPP/EMAIL/OTHER without storing raw referrer URLs.
- Nearby Dealer result must be real: APPROVED/ACTIVE, opted into referrals, verified location/service capability. Never fabricate distance, availability, authorization or Dealer results.
- If no suitable Dealer exists: CONTACT TORVO / SEND REQUIREMENT.
- Customer app/login direction retained only where separately Owner-approved; it must not create a public generic Business App download CTA or bypass business-role authorization.

## SEARCH / PUBLIC UI LOCK
- Mobile-first premium RED/BLACK/WHITE/GREY TORVO identity.
- Remove visible `ALL` option on mobile and desktop.
- CAMERA before MIC; MIC last. As-you-type suggestions below search without bordered dropdown; MACHINES/SPARE PARTS/ACCESSORIES groups and model/item variants such as ARMATURE 801 variants.
- Search bar light/clean, no unnecessary vertical dividers; readable typed text and compact spacing.
- Delivery strip: `10000+ SPARE PARTS FREE DELIVERY`, one line where layout permits; this is TORVO-to-Dealer B2B policy, not public retail delivery.
- Action-specific button names; never use OK on every button.
- English business-facing UI text UPPERCASE except case-sensitive identity/protocol values.
- Product card/detail must not leak private rate/cost/compatibility.
- Required public headings/content and TORVO premium placement remain Admin-manageable; useful brand logos, photos, videos, featured/best products and suitable/compatible messaging remain supported.

## DEALER ONBOARDING / ACCESS
- Website registration -> TORVO verification -> approval -> App access.
- Website `REGISTER AS DEALER` opens the Dealer registration/onboarding surface; the TORVO Business App install/download control is placed inside that business-only flow, not in the general Customer homepage.
- A directly installed TORVO Business App must offer `REGISTER AS DEALER` from the first Dealer login screen so a new Dealer can complete the same authoritative registration flow.
- App install/download controls must expose only a verified install prompt or verified Android/iPhone release/store link. Never invent APK/AAB/IPA/Play Store/App Store targets.
- Registration shared Call + WhatsApp number concept: India +91, 10-digit mobile, WhatsApp indication/helper; same active number unless Owner later changes the rule.
- Dealer private login is App-only, not public Website.
- Dealer login uses 10-digit registered mobile. First login/defined security verification uses WhatsApp OTP, then secure 4-digit PIN; forgot PIN and suspicious/new device require verification.
- One Dealer account/device security means one active mobile device per Dealer account; a newly verified device revokes the old active device. Blocked/inactive access denial, rate limiting and secure PIN hashing are server-authoritative.
- Inactive Dealer warning after prolonged no-billing period remains; suspension/reactivation is Admin-controlled, not blind deletion.

## DEALER PRICING / B2B ORDER LOGIC
- Dealer rates are exactly RATE A / RATE B / RATE C. Admin can change a Dealer's assigned rate category.
- Dealer sees only the rate assigned to that Dealer; rate and quantity-tier calculations are server-authoritative.
- Purchase cost/history/profit is confidential and Owner-only as approved; no public leakage.
- PO -> SALES ORDER -> controlled revision -> exact latest DEALER OK -> ESTIMATE -> payment/fulfilment -> DELIVERY.
- A new TORVO revision invalidates old Dealer OK. Estimate locks the approved revision.
- ADD MORE ITEMS after approval creates a separate linked Additional PO; never mutate the original approved order/Estimate.
- Duplicate item lines and client-trusted financial manipulation must be blocked.

## DELIVERY / TRACKING
- Machines and Accessories: delivery charge applies.
- Spare Parts: free TORVO-to-Dealer delivery only when Spare Parts subtotal >= Rs 10,000.
- Pending/Delivered history, dispatch tracking code and delivery confirmation/history are required; successful delivery status/message must be recorded.

## PRODUCT / MASTER / COMPATIBILITY
- Sell/manage MACHINES, SPARE PARTS and ACCESSORIES.
- Masters include Brand, Machine Type, Work/Machine Name, Category and required linked masters.
- Prevent duplicates, business text uppercase, safe linked-use edit/delete controls; destructive master deletion requires protected confirmation/business rule (historical Owner code 1122 where applicable).
- Product master supports RATE A/B/C, quantity tiers and Owner-only purchase cost history with multiple references.
- Compatibility mapping: Spare Part -> Brand + Machine/Model + photos. Private by default; only explicitly approved projection may be public.
- Opportunity/Missing Range records no-match searches/requests for sourcing and TORVO range development.
- Product PDF/export must exclude private fields.

## DEALER NETWORK / CUSTOMER REFERRAL
- Dealer master: address, PIN, State/District/City, verified service/location data and customer-facing capabilities.
- Dealer public profile may show approved shop/contact/address/map/directions/sales/service data.
- `AUTHORIZED SERVICE CENTER` wording only after verified authorization.
- Referral analytics tracks product/area and Dealer interactions without requiring Dealer's private final retail sale price.
- Dealer change/reassignment must be auditable where applicable.

## STAFF / ROLE SECURITY
- OWNER: full control.
- ADMIN: authorized operational/admin controls; Owner-only confidential data remains restricted.
- ACCOUNTANT: secure Desktop accounting/payment and authorized flows.
- SALESMAN: mapped Dealer/area/order/sales workflows only.
- STORE KEEPER: stock/pick/pack/dispatch only; no unauthorized financials.
- DEALER: approved linked App only.
- Staff login uses Admin-issued staff identity/one-time credential flow where specified; do not force Dealer mobile-login semantics onto staff.
- Salesman attendance: server-bound identity, one check-in per date, checkout only after check-in, self history plus Owner/Admin reports.
- Role/device authorization must be enforced server-side, not merely hidden in UI.

## PURCHASE / INVENTORY
- Purchase Entry is the single supplier stock-receipt path.
- Supplier + invoice duplicate protection; stock increases exactly once; inventory movement is recorded.
- Correction uses audited reversal; Purchase Requirement must not duplicate stock receipt.
- Purchase Requirements support staff submission, Admin review, Item Master linking, partial/full fulfilment, Dealer allocation tracking and audited reversal.
- Stock, low/reorder alerts and inventory reports required.

## SCHEMES / REWARDS / REFERRAL / TARGETS
- Quarterly Dealer schemes with slabs/gifts.
- Points/rewards including approved bonus/points-on-points logic.
- DealerTargetRewards and Admin Scheme Management remain complete and server-authoritative.
- Billing/order linkage must not double count.
- Claim approval/cancel/reversal and annual expiry/reset rules required.
- Never revive superseded/old billing or fitment points incorrectly.
- Referral program, Salesman verification/statement and Target/Progress reporting remain required.

## REPORTS / NOTIFICATIONS
- One REPORTS CENTER covering Sales, Order vs Estimate, Pending/Unfulfilled, Profit/Income (authorized roles), Expenses, Stock/Inventory, Low/Reorder, Dealer performance, Scheme/Target progress, Delivery/Tracking and other approved operational reports.
- Excel/PDF exports where approved, without leaking restricted fields.
- Notification center includes new orders, pending estimates, Dealer enquiries, Customer/spare-part requests, chat/unread, low stock, delivery exceptions, blocked/inactive and system issues.

## COMMUNICATION / CUSTOMER CARE
- WhatsApp API is primary automated communication channel when real provider/API credentials and testing exist.
- TORVO Customer Care/Support number currently `7027751533`, Admin-changeable.
- Public business/requirement email may be shown where approved; private Admin/security email must never leak publicly.
- Dual/role-appropriate WhatsApp communication must remain supported across public, Dealer/Staff App and privileged surfaces as approved.
- Social lead routing uses official APIs/permissions only; no private-social scraping.
- Admin-managed communication/content/settings writes require Owner/Admin authorization, reason and audit.

## ADMIN-MANAGED SETTINGS
- Admin can manage approved website content/notices, social links, WhatsApp/support details, app notices, maintenance/update messaging, marketing defaults, safe feature switches, promotions/popular products and verified Android/iPhone release links.
- Security/authorization/database integrity/package identity/signing/executable business logic must never become arbitrary no-code Admin-editable settings.

## APP / RELEASE / UPDATE
- Package identity: `com.torvotools.app`.
- TORVO Business App is for Dealer, Salesman and authorized Store/Business staff. General Customer pages must not advertise its install/download control.
- Admin/Owner APP RELEASE/DOWNLOAD area must show real version/build/date/commit/status and verified downloadable artifacts/links only.
- Android: debug APK is test-only; production requires private signing, signed AAB/APK, real-device testing and Play Store path.
- iOS: Apple signing + TestFlight/App Store path; do not pretend an Android APK is an iPhone package.
- Backend/content changes can appear without reinstall; installed native code cannot silently replace itself. Native changes require signed versioned release/update.
- Never show fake APK/AAB/IPA/store links or claim published/live without evidence.

## BACKUP / DISASTER RECOVERY
- Backup is a core Owner/Admin function, but request != successful backup.
- Verified backup requires trusted worker completion + integrity verification.
- Portable backup encrypted; secrets/passwords/service-role credentials excluded.
- Restore Point includes DB backup + Git branch/commit + schema version + checksum + manifest.
- Restore must be tested in staging.

## RELEASE / STAGING
- `supabase/V2_INSTALL_ORDER.md` is authoritative; never run migrations alphabetically.
- Apply and test full migration chain in dedicated V2 staging before production.
- Stop at first SQL/runtime/security error and fix it; never label GitHub SQL as runtime-tested merely because source exists.
- Runtime-test public referral/locator, consent, role routing, Dealer device security, B2B order/estimate, inventory, rewards, reports, notifications, backup/restore and app packaging.
- Exact GitHub release SHA and deployed SHA must match before live release.
- Domain switch only after staging, backup/restore readiness, exact preview and Owner acceptance. Preserve old site as backup/reference until safe transition.

## CLEANUP / NEVER CHANGE SILENTLY
- Superseded direct-public-checkout/pricing foundation must not return to production.
- Do dependency-aware cleanup only; preserve required migration/audit/recovery history.
- Never fabricate rates, stock, Dealer availability, distance, maps, service authorization, WhatsApp sent state, backup success or production status.
- Never weaken server-authoritative pricing, role/device security, Customer privacy, consent, private compatibility or Owner-only confidential controls for UI convenience.

## NO-OMISSION RELEASE RULE
Before TORVO V2 is called complete, every section above and every active item in `TORVO-V2-MASTER-HANDOVER.md` must be mapped to implementation + verifier/test evidence. Any missing item remains OPEN; it must not be silently treated as complete.
