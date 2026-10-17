-- TORVO V2: additive STAGING forward patch for managed hero settings.
-- Apply only after v2-admin-managed-experience.sql has installed the table.
-- Existing uploaded URLs, actions, and unrelated website content are preserved.
update public.admin_managed_settings
set setting_value = setting_value || jsonb_build_object(
    'company_logo_url', coalesce(setting_value->'company_logo_url', '""'::jsonb),
    'hero_image_desktop_url', coalesce(setting_value->'hero_image_desktop_url', '""'::jsonb),
    'hero_image_mobile_url', coalesce(setting_value->'hero_image_mobile_url', '""'::jsonb),
    'hero_image_dealer_url', coalesce(setting_value->'hero_image_dealer_url', '""'::jsonb),
    'hero_image_salesman_url', coalesce(setting_value->'hero_image_salesman_url', '""'::jsonb),
    'hero_image_store_url', coalesce(setting_value->'hero_image_store_url', '""'::jsonb),
    'hero_actions_desktop', coalesce(setting_value->'hero_actions_desktop', '[]'::jsonb),
    'hero_actions_mobile', coalesce(setting_value->'hero_actions_mobile', '[]'::jsonb),
    'hero_actions_dealer', coalesce(setting_value->'hero_actions_dealer', '[]'::jsonb),
    'hero_actions_salesman', coalesce(setting_value->'hero_actions_salesman', '[]'::jsonb),
    'hero_actions_store', coalesce(setting_value->'hero_actions_store', '[]'::jsonb)
)
where setting_key = 'website_content';

-- Read-only verification (expect 11 true keys).
select setting_key, setting_value ? 'company_logo_url' as has_company_logo_url,
       setting_value ? 'hero_image_desktop_url' as has_hero_image_desktop_url,
       setting_value ? 'hero_image_mobile_url' as has_hero_image_mobile_url,
       setting_value ? 'hero_image_dealer_url' as has_hero_image_dealer_url,
       setting_value ? 'hero_image_salesman_url' as has_hero_image_salesman_url,
       setting_value ? 'hero_image_store_url' as has_hero_image_store_url,
       setting_value ? 'hero_actions_desktop' as has_hero_actions_desktop,
       setting_value ? 'hero_actions_mobile' as has_hero_actions_mobile,
       setting_value ? 'hero_actions_dealer' as has_hero_actions_dealer,
       setting_value ? 'hero_actions_salesman' as has_hero_actions_salesman,
       setting_value ? 'hero_actions_store' as has_hero_actions_store
from public.admin_managed_settings where setting_key='website_content';
