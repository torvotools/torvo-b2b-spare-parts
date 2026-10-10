# TORVO V2 — AI-ASSISTED AND MANUAL PRODUCT ENTRY CONTRACT

Owner-approved requirement, 10 October 2026. This is part of the ONE TORVO V2 codebase and authoritative backend. It is not a separate app, database, or product catalog.

## Two permanent entry modes
1. **MANUAL ADD:** Keep the existing full Product Master form and Product Draft Library usable without any AI service, extra cost, or dependency.
2. **ADD WITH AI:** User uploads a real product photo. Vision identifies likely item type and prepares **suggestions only**. If photo is unclear, show an optional text box: "WHAT IS THIS ITEM?" / product hint. User can enter e.g. "ARMATURE FOR 801 ANGLE GRINDER", then regenerate suggestions. Show editable preview of name, category, description, keywords, brand/model only where evidence exists. Require explicit admin review and approval before converting a draft into a catalog item.

## Safety and quality invariants
- Preserve original product image. Enhancement must be optional and reversible, with original/enhanced preview and user selection; never alter shape, proportions, identifying markings, or technical features.
- No hallucinated OEM code, fitment, dimensions, technical specification, GST, stock, purchase cost, dealer rate, selling price, or manufacturer authorization. Unknown fields stay blank and are labeled NEEDS VERIFICATION.
- AI suggestions are **untrusted**. Never write them directly into live catalog without owner/admin authorization, existing server-side validation, duplicate checks, and product master save confirmation.
- API credentials must remain server-side; require authenticated role and tenant checks, strict image MIME/size validation, rate limits, audit trail, and explicit cost controls. Never send dealer prices, financials, or private customer information to a vision provider.
- An unavailable or failing AI service must gracefully return to manual entry without blocking product creation. No mock/generated output may be presented as a real AI result.
- Reuse existing product draft storage and conversion flow; avoid duplicate catalog items and a parallel data source.
- UI must work on desktop and mobile and use the canonical TORVO V2 design foundation.

## Delivery stages
- Stage 1: Visible manual/AI entry choice and photo + optional hint capture. The AI choice must be clearly marked SETUP PENDING until an authenticated backend AI service actually works.
- Stage 2: Secure server-side vision provider adapter, verified upload pipeline, suggestion schema, cost limits, and audit logging.
- Stage 3: Editable preview, regenerate with hint, optional non-destructive photo enhancement, owner/admin approval and conversion with integration tests.
- Stage 4: Real staging runtime and device acceptance. Do not mark the feature complete on static UI/CI alone.

No provider has been selected, no vision API has been connected, and no live AI analysis or photo enhancement has been verified as of this contract.

## Owner-approved duplicate prevention (10 October 2026)
- Check the authoritative Product Master **and** unconverted Product Draft Library before both MANUAL ADD and ADD WITH AI create or convert a product.
- Exact normalized TORVO item code must be unique, enforced by the backend/database (not only browser state). Verified OEM code plus brand/model/type can flag potential duplicates; OEM code alone is not necessarily unique across all products.
- Similar product name, category, brand, model and future image similarity produce **POSSIBLE DUPLICATE** suggestions with existing item code, name and photo. Image similarity is not proof of identity; do not block different-looking-equivalent or visually similar but incompatible spare parts without review.
- Display **ALREADY EXISTS** for verified exact matches and provide OPEN EXISTING ITEM. For possible matches, let authorized staff review the existing item and explicitly resolve whether it is distinct. Never silently merge, overwrite, or create a second record.
- Repeat duplicate check atomically on server at final save to prevent concurrent submissions/races. Include draft conversion and retry/idempotency cases. Do not claim AI photo matching is active until the real provider and staging tests pass.
