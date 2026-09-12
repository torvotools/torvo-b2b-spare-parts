-- TORVO V2 PRODUCT DIGITAL CONTENT
-- AI MAY DRAFT CONTENT, BUT ADMIN APPROVAL IS REQUIRED BEFORE PUBLIC USE.
alter table catalog_items add column if not exists short_description text;
alter table catalog_items add column if not exists detailed_description text;
alter table catalog_items add column if not exists feature_points jsonb not null default '[]'::jsonb;
alter table catalog_items add column if not exists content_status text not null default 'manual' check(content_status in('manual','ai_draft','approved'));
alter table catalog_items add column if not exists content_approved_by uuid references app_users(id);
alter table catalog_items add column if not exists content_approved_at timestamptz;

create table if not exists product_content_drafts(
 id uuid primary key default gen_random_uuid(),item_id uuid not null references catalog_items(id) on delete cascade,
 source_image_url text,provider text,model_reference text,
 suggested_name text,suggested_category text,short_description text,detailed_description text,
 feature_points jsonb not null default '[]'::jsonb,
 raw_response jsonb not null default '{}'::jsonb,status text not null default 'draft' check(status in('draft','approved','rejected')),
 created_by uuid references app_users(id),created_at timestamptz not null default now(),decided_by uuid references app_users(id),decided_at timestamptz
);create index if not exists idx_product_content_drafts_item on product_content_drafts(item_id,created_at desc);
alter table product_content_drafts enable row level security;revoke all on product_content_drafts from anon,authenticated;

create or replace function admin_approve_product_content(p_item_id uuid,p_short_description text,p_detailed_description text,p_feature_points jsonb default '[]'::jsonb)
returns boolean language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if not exists(select 1 from catalog_items where id=p_item_id) then raise exception 'PRODUCT NOT FOUND';end if;
 update catalog_items set short_description=nullif(btrim(p_short_description),''),detailed_description=nullif(btrim(p_detailed_description),''),feature_points=coalesce(p_feature_points,'[]'::jsonb),content_status='approved',content_approved_by=u.id,content_approved_at=now() where id=p_item_id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'PRODUCT_CONTENT_APPROVED','CATALOG_ITEM',p_item_id::text,jsonb_build_object('source','ADMIN_PANEL'));return true;end$$;
revoke all on function admin_approve_product_content(uuid,text,text,jsonb) from public;grant execute on function admin_approve_product_content(uuid,text,text,jsonb) to authenticated;

-- Provider-neutral queue: no AI secret/API key is stored in browser or database rows.
create or replace function admin_request_product_content_draft(p_item_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;v catalog_items%rowtype;d uuid;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;select * into v from catalog_items where id=p_item_id;if v.id is null then raise exception 'PRODUCT NOT FOUND';end if;if nullif(btrim(v.image_url),'') is null then raise exception 'PRODUCT IMAGE REQUIRED';end if;
 insert into product_content_drafts(item_id,source_image_url,status,created_by,raw_response) values(v.id,v.image_url,'draft',u.id,jsonb_build_object('queue_status','AWAITING_AI_PROVIDER')) returning id into d;return d;end$$;
revoke all on function admin_request_product_content_draft(uuid) from public;grant execute on function admin_request_product_content_draft(uuid) to authenticated;
