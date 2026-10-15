# TORVO V2 — latest owner-selected hero reference (15 October 2026)

Owner explicitly said: "Jo abhi aapane last photo bheji thi vah best hai" (the last photo sent is best).

## New visual direction
Use the **most recently generated TORVO promotional image** in this conversation as the visual reference, not the earlier showroom/card layout. The new reference features a left white marble content area with TORVO branding, black/red headline, two CTAs, and a right dark marble/showroom area with **three smaller red-bordered hexagons** (MACHINERY, SPARE PART, ACCESSORI) plus **one large red-bordered spare-part hexagon**. There is a dark feature strip along the bottom. This supersedes earlier *visual-only* hero decisions where they conflict.

## Important distinctions
- Approval is for the *appearance* of the last shared picture. It is **not** approval to publish or change production.
- The image is a flattened generated preview, **not** editable source artwork. Four independently managed photo regions still need a verified clean plate, border overlays and correctly measured hexagonal clipping masks.
- Generated product imagery and branding may not be authentic. Before public launch, replace product photographs with owner-supplied originals and confirm logo/copy; do not present AI-generated photos as genuine.
- Existing prototype masks in `src/v2/components/ApprovedHeroPhotoLayerDraft.jsx` refer to the **previous** 1536x864 hero and must NOT be mounted over this new design.
- Preserve all existing TORVO V2 business/auth/role rules and production safety constraints. No production edits without explicit approval.
- Next: save approved artwork as a project asset with verified rights/source, measure the new four hexagons, build a separate versioned hero implementation, wire four admin uploads, test mobile/desktop, then request owner sign-off before deployment.
