# TORVO V2 — Approved Hero photo-layer implementation specification (draft)

Reference: owner-supplied approved Hero PNG, 1536 × 864 pixels, received 15 October 2026. This is a single flattened raster, NOT a layered template. Preserve the original headline, CTA, three category labels/buttons, marble/wood background, lighting, card outlines, red hexagon frame and all spacing.

## Approximate photo-only areas (REFERENCE PIXELS; NOT final masks)

| Slot key | Approximate image-content bounds (x1,y1,x2,y2) | Mask geometry |
| --- | --- | --- |
| machinery | (105, 374, 311, 507) | clipped to slanted rounded card, exclude red category button |
| spare_part | (331, 374, 552, 507) | clipped to slanted rounded card, exclude red category button |
| accessori | (555, 374, 789, 507) | clipped to slanted rounded card, exclude red category button |
| feature | (790, 182, 1458, 677) | custom clipped hexagon interior, preserve metallic frame |

All bounds are **approximate visual measurements** of the 1536 × 864 approved image, not confirmed pixel-accurate geometry. They must be refined against the source image at full resolution. The right hexagon is not a rectangle; a rectangular overlay would hide the original red/metal frame.

## Non-negotiable gates

1. Source is flattened: first produce a clean plate where the old product photos are removed from the four interiors **without changing any other pixel**. A simple overlay on the old flattened image is not an acceptable finished implementation.
2. Separate the clean background plate, photo masks and any foreground trim. Preserve the owner's original image as a rollback reference.
3. Reconcile upload sizes with actual masks and rendering; existing 320 × 240 / 720 × 600 constraints are **provisional** and not derived from these areas. Do not claim they are final.
4. Render slot photos with object-fit: contain or cover according to the verified mask, no stretching, maintain mobile/desktop behavior and fallback to the existing approved artwork until the replacement assets are fully ready.
5. Validate Admin save/load and public render end-to-end in staging. Obtain visual approval before switching public Hero. No production database or main branch changes.

Current code reads website_content.hero_slot_images but does not display them in the approved flattened Hero. This document does not enable any overlay or alter the live Hero.
