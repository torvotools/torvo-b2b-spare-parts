-- TORVO V2 ADMIN-MANAGED EXPERIENCE
-- Change daily website/app/marketing configuration without a code deployment.
create table if not exists admin_managed_settings(
 setting_key text primary key,
 setting_group text not null check(setting_group in('website','social','app','marketing','feature')),
 setting_value jsonb not null default '{}'::jsonb,
 public_read boolean not null default false,
 active boolean not null default true,
 updated_by uuid references app_users(id),
 updated_at timestamptz not null default now()
);
alter table admin_managed_settings enable row level security;revoke all on admin_managed_settings from anon,authenticated;
insert into admin_managed_settings(setting_key,setting_group,setting_value,public_read) values
('website_content','website','{"announcement":"","home_notice":"","support_label":"CUSTOMER CARE"}'::jsonb,true),
('social_links','social','{"facebook":"","instagram":"","youtube":""}'::jsonb,true),
('whatsapp_channels','website','{"customer_number":"7027751533","customer_active":true,"business_number":"7027751533","business_active":true}'::jsonb,true),
('app_experience','app','{"maintenance":false,"maintenance_message":"","update_notice":true}'::jsonb,false),
('marketing_defaults','marketing','{"festival_messages":true,"product_launch_messages":true}'::jsonb,false),
('product_promotions','marketing','{"website_enabled":true,"dealer_app_enabled":true,"headline":"FEATURED PRODUCTS","items":[]}'::jsonb,true),
('popular_products','marketing','{"website_enabled":true,"dealer_app_enabled":true,"auto_from_sales":true,"manual_items":[],"max_items":12}'::jsonb,true),
('app_download_links','app','{"android_url":"","ios_url":"","android_enabled":false,"ios_enabled":false}'::jsonb,true),
('feature_switches','feature','{"dealer_registration":true,"customer_profile":true,"notifications":true,"product_promotions":true,"popular_products":true}'::jsonb,false)
on conflict(setting_key) do nothing;
create or replace function admin_managed_settings_snapshot() returns setof admin_managed_settings language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;return query select * from admin_managed_settings order by setting_group,setting_key;end$$;
create or replace function admin_save_managed_setting(p_key text,p_value jsonb,p_active boolean default true,p_reason text default null) returns boolean language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;oldv jsonb;cn text;bn text;begin select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;if nullif(btrim(coalesce(p_reason,'')),'') is null then raise exception 'CHANGE REASON REQUIRED';end if;select setting_value into oldv from admin_managed_settings where setting_key=p_key for update;if not found then raise exception 'UNKNOWN MANAGED SETTING';end if;if p_key='whatsapp_channels' then cn:=regexp_replace(coalesce(p_value->>'customer_number',''),'\D','','g');bn:=regexp_replace(coalesce(p_value->>'business_number',''),'\D','','g');if length(cn) not in(10,12) or length(bn) not in(10,12) then raise exception 'VALID WHATSAPP NUMBERS REQUIRED';end if;end if;update admin_managed_settings set setting_value=coalesce(p_value,'{}'::jsonb),active=coalesce(p_active,true),updated_by=u.id,updated_at=now() where setting_key=p_key;insert into audit_log(actor_id,action,entity_type,entity_id,details)values(u.id,'ADMIN_MANAGED_SETTING_UPDATED','SETTING',p_key,jsonb_build_object('old',oldv,'new',p_value,'reason',upper(btrim(p_reason))));return true;end$$;
create or replace function public_managed_settings() returns table(setting_key text,setting_value jsonb) language sql security definer set search_path=public as $$select s.setting_key,s.setting_value from admin_managed_settings s where s.public_read=true and s.active=true order by s.setting_key$$;
revoke all on function admin_managed_settings_snapshot(),admin_save_managed_setting(text,jsonb,boolean,text) from public,anon;grant execute on function admin_managed_settings_snapshot(),admin_save_managed_setting(text,jsonb,boolean,text) to authenticated;revoke all on function public_managed_settings() from public;grant execute on function public_managed_settings() to anon,authenticated;
