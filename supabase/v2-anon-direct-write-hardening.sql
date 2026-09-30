-- TORVO V2 ANON DIRECT-WRITE LEAST PRIVILEGE
-- Public writes use intentionally exposed SECURITY DEFINER RPCs. Base business tables are never direct anonymous mutation surfaces.
revoke insert, update, delete, truncate on table
 app_settings, app_users, audit_log, catalog_items, catalog_master_values,
 dealer_request_history, dealers, item_rates, machine_spare_mapping, messages,
 non_available_requests, notifications, stock_reorder_requests
from anon;
