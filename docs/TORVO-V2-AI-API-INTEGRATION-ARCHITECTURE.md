# TORVO V2 — AI & API INTEGRATION ARCHITECTURE

Status: APPROVED DIRECTION / IMPLEMENTATION CONTRACT
Business logic remains Owner-defined and locked. Integrations extend TORVO; they do not silently rewrite TORVO rules.

## Core rule
TORVO's authoritative backend/database remains the system of record. External AI, accounting, WhatsApp, mail, GST, payment, logistics, maps and monitoring providers are adapters behind TORVO services. No browser/mobile client receives provider secrets.

## Integration gateway
Every external call must pass through a server-side TORVO integration gateway with:
- provider adapter and version
- idempotency key for write operations
- request purpose and actor
- timeout and bounded retry
- status: PENDING / PROCESSING / SUCCESS / RETRY / FAILED / NEEDS_REVIEW
- provider reference
- safe error/audit record
- timestamps
- Owner/Admin operational visibility
Provider outage must not corrupt the TORVO transaction.

## Canonical integration registry and queue
Future providers must plug into a provider-neutral server-side registry rather than page-specific code. The canonical integration layer should model:
- capability key (ACCOUNTING / WHATSAPP / EMAIL / AI_VISION / GST / LOGISTICS / PAYMENT / MAPS / MONITORING)
- provider + adapter version + enabled environment
- secret reference only, never secret value in browser/database-readable public configuration
- health/last-success/last-failure state
- outbound sync/event queue with idempotency key, canonical entity ID, retry count and next retry time
- dead-letter / NEEDS_REVIEW state after bounded retries
- inbound webhook event ID/signature verification/replay protection before any TORVO mutation
- provider-to-canonical ID mapping so switching ERP/mail/logistics providers does not rewrite TORVO business IDs
- Owner/Admin diagnostics with redacted payload/error details

Provider activation remains configuration-driven and must not create a second source of truth. TORVO commits its canonical business state according to TORVO rules; external sync success/failure is tracked separately unless a specific legally required external submission is explicitly defined as a workflow gate.

## Public integration abuse boundary
Anonymous/public write capabilities (Dealer registration, Customer requirement/referral/repair/support/complaint, marketing preference and promotion telemetry) must be treated as internet-facing abuse surfaces even when the database RPC validates fields. Production routing should prefer a trusted TORVO gateway/Edge boundary that adds per-IP/session/identity rate limits, bounded request size, replay/idempotency protection where appropriate, bot/challenge protection for suspicious traffic, and privacy-safe abuse telemetry before invoking canonical database RPCs. Browser-only throttling is not a security control.

Do not revoke a currently required public RPC merely to satisfy this rule; migrate callers to the protected gateway with compatibility evidence, then narrow direct grants only after zero-caller/runtime proof.

## AI Product Assistant
Product entry flow:
PHOTO(S) -> AI ANALYSIS -> STRUCTURED DRAFT -> CONFIDENCE -> QUESTIONS/REVIEW -> HUMAN CONFIRM -> PRODUCT SAVE.

AI may suggest:
- Machine / Spare Part / Accessory classification
- visible brand, model, item/part markings
- product/category/name/description/features
- visible physical characteristics
- probable machine/model compatibility
- missing information/questions

Safety/data-integrity rule:
AI compatibility, brand/model identity, technical specification and other uncertain facts are suggestions. Low-confidence or ambiguous fields must be marked NEEDS REVIEW and ask Owner/Admin. Compatibility becomes authoritative only after authorized human confirmation. Preserve original image, AI draft, confidence/provenance and confirmation audit.

## Accounting adapter
Provider-neutral accounting boundary for approved TORVO events such as party/contact, sales/purchase documents, payment, credit/debit/return and reconciliation. TORVO business document lifecycle remains canonical. Provider selection/paid activation requires Owner approval.

## WhatsApp Business adapter
Approved transactional messaging: OTP/auth where applicable, order/estimate workflow notifications, payment acknowledgement, dispatch/tracking, delivery, dealer/customer requirement follow-up. Marketing requires genuine opt-in and approved templates/policy. No unofficial personal-WhatsApp automation.

## Email
Existing TORVO server-side mail integration remains canonical for approved mail flows. Secrets stay server-side.

## GST / e-Invoice / e-Way Bill
Dedicated compliance adapter; do not hard-wire accounting UI to one provider. Legal/tax submission requires validated canonical TORVO document data and explicit workflow controls.

## Logistics
Provider-neutral shipment/AWB/label/tracking adapter. Tracking events map back to canonical TORVO dispatch/delivery records.

## Payments
Payment-link/gateway/bank-reconciliation adapters may support the approved private B2B payment flow. This does not create public checkout/COD/public payment logic.

## Maps / address
Address verification/geocoding/directions support only. Do not infer or publish fake distance, availability, stock or ranking.

## Monitoring
Central health, latency, failed-call and retry visibility. Integration failure must be visible to authorized staff without exposing secrets or private payloads.

## UX contract
AI/API features use the same TORVO design system. Show clear states: ANALYZING, DRAFT, NEEDS REVIEW, CONFIRMED, SYNCING, SYNCED, RETRY, FAILED. Never present an AI guess as verified fact. Product photos remain visually primary.

## Change control
UI/integration plumbing may proceed without changing locked business logic. New provider purchase, production credentials, irreversible production/domain change, or a new business policy requires Owner approval.
