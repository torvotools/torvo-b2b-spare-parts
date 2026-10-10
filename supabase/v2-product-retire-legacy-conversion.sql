-- TORVO V2 — retire the non-atomic legacy product draft conversion endpoint.
-- Install AFTER v2-product-draft-atomic-conversion.sql.
-- The old endpoint can mark any draft converted against an unrelated existing catalog item;
-- the replacement admin_convert_product_draft performs the full operation atomically.
-- Keep function definition for historical dependency compatibility, but deny API roles.
revoke all on function public.admin_mark_product_draft_converted(uuid, uuid)
  from public, anon, authenticated;
