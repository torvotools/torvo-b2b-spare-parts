-- TORVO V2 — critical direct table mutation hardening
-- Browser roles may read only through existing RLS policies and must mutate
-- authoritative financial/stock/order state through approved RPC boundaries.
-- SECURITY DEFINER RPCs owned by the database owner are not broken by these revokes.

revoke insert, update, delete, truncate on table public.payments from anon, authenticated;
revoke insert, update, delete, truncate on table public.dispatches from anon, authenticated;
revoke insert, update, delete, truncate on table public.inventory from anon, authenticated;
revoke insert, update, delete, truncate on table public.inventory_movements from anon, authenticated;
revoke insert, update, delete, truncate on table public.sales_documents from anon, authenticated;
revoke insert, update, delete, truncate on table public.sales_document_lines from anon, authenticated;
revoke insert, update, delete, truncate on table public.purchase_headers from anon, authenticated;
revoke insert, update, delete, truncate on table public.purchase_lines from anon, authenticated;

-- Already RPC-only tables are repeated intentionally so a clean install and an
-- upgraded staging database converge on the same deny-direct-write posture.
revoke insert, update, delete, truncate on table public.purchase_stock_receipts from anon, authenticated;
revoke insert, update, delete, truncate on table public.transaction_returns from anon, authenticated;
revoke insert, update, delete, truncate on table public.transaction_return_lines from anon, authenticated;
revoke insert, update, delete, truncate on table public.delivery_stock_finalizations from anon, authenticated;
revoke insert, update, delete, truncate on table public.estimate_delivery_details from anon, authenticated;
revoke insert, update, delete, truncate on table public.delivery_settings from anon, authenticated;
revoke insert, update, delete, truncate on table public.delivery_setting_history from anon, authenticated;
