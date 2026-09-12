-- TORVO V2 CENTRAL ADMIN CONTROL
-- DAILY BUSINESS CONFIGURATION IS MANAGED FROM ADMIN PANEL AND READ FROM ONE BACKEND.
create table if not exists business_public_settings(
 id boolean primary key default true check(id=true),
 support_mobile text not null default '7027751533',
 whatsapp_mobile text not null default '7027751533',
 referral_enabled boolean not null default true,
 repair_service_enabled boolean not null default true,
 customer_catalog_enabled boolean not null default true,
 updated_by uuid references app_users(id),updated_at timestamptz not null default now()
);insert into business_public_settings(id) values(true) on conflict(id) do nothing;
alter table business_public_settings enable row level security;revoke all on business_public_settings from anon,authenticated;

create or replace function admin_control_snapshot() returns jsonb language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v jsonb;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 select jsonb_build_object('delivery',to_jsonb(d),'public',to_jsonb(p),'portal',to_jsonb(pc),'tax',to_jsonb(t)) into v from delivery_settings d cross join business_public_settings p cross join portal_content_settings pc cross join tax_settings t where d.id=true and p.id=true and pc.id=true and t.id=true;return v;end$$;
revoke all on function admin_control_snapshot() from public,anon;grant execute on function admin_control_snapshot() to authenticated;

create or replace function admin_update_business_controls(p_support_mobile text,p_whatsapp_mobile text,p_referral_enabled boolean,p_repair_service_enabled boolean,p_customer_catalog_enabled boolean,p_spare_free_delivery_enabled boolean,p_spare_free_delivery_threshold numeric,p_reason text)
returns boolean language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;old_d delivery_settings%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;if regexp_replace(coalesce(p_support_mobile,''),'\D','','g')!~'^[0-9]{10}$' or regexp_replace(coalesce(p_whatsapp_mobile,''),'\D','','g')!~'^[0-9]{10}$' then raise exception 'VALID 10 DIGIT SUPPORT / WHATSAPP MOBILE REQUIRED';end if;if coalesce(p_spare_free_delivery_threshold,-1)<0 then raise exception 'VALID DELIVERY THRESHOLD REQUIRED';end if;if nullif(btrim(p_reason),'') is null then raise exception 'CHANGE REASON REQUIRED';end if;
 select * into old_d from delivery_settings where id=true for update;
 update business_public_settings set support_mobile=regexp_replace(p_support_mobile,'\D','','g'),whatsapp_mobile=regexp_replace(p_whatsapp_mobile,'\D','','g'),referral_enabled=p_referral_enabled,repair_service_enabled=p_repair_service_enabled,customer_catalog_enabled=p_customer_catalog_enabled,updated_by=u.id,updated_at=now() where id=true;
 if old_d.spare_free_delivery_enabled is distinct from p_spare_free_delivery_enabled or old_d.spare_free_delivery_threshold is distinct from p_spare_free_delivery_threshold then insert into delivery_setting_history(old_enabled,old_threshold,new_enabled,new_threshold,reason,changed_by) values(old_d.spare_free_delivery_enabled,old_d.spare_free_delivery_threshold,p_spare_free_delivery_enabled,p_spare_free_delivery_threshold,upper(btrim(p_reason)),u.id);end if;
 update delivery_settings set spare_free_delivery_enabled=p_spare_free_delivery_enabled,spare_free_delivery_threshold=p_spare_free_delivery_threshold,updated_by=u.id,updated_at=now() where id=true;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'BUSINESS_CONTROLS_UPDATED','SYSTEM','CENTRAL',jsonb_build_object('reason',upper(btrim(p_reason))));return true;end$$;
revoke all on function admin_update_business_controls(text,text,boolean,boolean,boolean,boolean,numeric,text) from public;grant execute on function admin_update_business_controls(text,text,boolean,boolean,boolean,boolean,numeric,text) to authenticated;

create or replace function public_business_settings() returns table(support_mobile text,whatsapp_mobile text,referral_enabled boolean,repair_service_enabled boolean,customer_catalog_enabled boolean) language sql security definer set search_path=public as $$select support_mobile,whatsapp_mobile,referral_enabled,repair_service_enabled,customer_catalog_enabled from business_public_settings where id=true$$;revoke all on function public_business_settings() from public;grant execute on function public_business_settings() to anon,authenticated;
