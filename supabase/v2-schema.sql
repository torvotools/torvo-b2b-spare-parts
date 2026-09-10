-- TORVO V2 core schema. Run on the production Supabase project only after final review.
create extension if not exists pgcrypto;

create table if not exists app_users (
 id uuid primary key default gen_random_uuid(), auth_user_id uuid unique, full_name text not null,
 mobile text unique, role text not null check(role in ('owner','admin','salesman','accountant','store_keeper','dealer')),
 active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists dealers (
 id uuid primary key default gen_random_uuid(), dealer_code text unique, shop_name text not null, contact_person text not null,
 mobile text not null, whatsapp text, email text, address text, pin_code text, state text, district text, city text,
 visiting_card_url text, rate_group text check(rate_group in ('A','B','C')), status text not null default 'pending'
 check(status in ('pending','approved','hold','rejected','inactive','suspended')), approved_by uuid references app_users(id),
 approved_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists catalog_items (
 id uuid primary key default gen_random_uuid(), item_type text not null check(item_type in ('machine','spare_part','accessory')),
 item_code text unique not null, name text not null, brand text, category text, model text, image_url text,
 gst_mode text check(gst_mode in ('included','extra')), active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists item_rates (
 id uuid primary key default gen_random_uuid(), item_id uuid not null references catalog_items(id) on delete restrict,
 rate_group text not null check(rate_group in ('A','B','C')), min_qty numeric not null default 1, selling_rate numeric not null check(selling_rate>=0),
 unique(item_id,rate_group,min_qty)
);
create table if not exists machine_spare_mapping (
 id uuid primary key default gen_random_uuid(), machine_id uuid not null references catalog_items(id) on delete restrict,
 spare_part_id uuid not null references catalog_items(id) on delete restrict, required_qty numeric not null default 1,
 fitment_type text not null default 'compatible' check(fitment_type in ('oem','compatible','alternative')),
 dealer_visible boolean not null default false, public_visible boolean not null default false, notes text,
 unique(machine_id,spare_part_id,fitment_type)
);
create table if not exists inventory (
 item_id uuid primary key references catalog_items(id) on delete restrict, current_qty numeric not null default 0,
 reorder_level numeric not null default 0, updated_at timestamptz not null default now()
);
create table if not exists sales_documents (
 id uuid primary key default gen_random_uuid(), dealer_id uuid not null references dealers(id) on delete restrict,
 doc_type text not null check(doc_type in ('query','quotation','sales_order','estimate')),
 status text not null default 'draft', parent_id uuid references sales_documents(id), subtotal numeric not null default 0,
 freight numeric not null default 0, other_charges numeric not null default 0, final_payable numeric not null default 0,
 created_by uuid references app_users(id), created_at timestamptz not null default now()
);
create table if not exists sales_document_lines (
 id uuid primary key default gen_random_uuid(), document_id uuid not null references sales_documents(id) on delete cascade,
 item_id uuid not null references catalog_items(id) on delete restrict, qty numeric not null check(qty>0), rate numeric, amount numeric
);
create table if not exists payments (
 id uuid primary key default gen_random_uuid(), estimate_id uuid not null references sales_documents(id) on delete restrict,
 status text not null check(status in ('cash','pending','received')), amount numeric not null default 0,
 received_at timestamptz, recorded_by uuid references app_users(id), created_at timestamptz not null default now()
);
create table if not exists dispatches (
 id uuid primary key default gen_random_uuid(), estimate_id uuid not null unique references sales_documents(id) on delete restrict,
 status text not null default 'pick_list' check(status in ('pick_list','picked','packed','ready_for_dispatch','delivered')),
 tracking_code text, delivered_at timestamptz, stock_deducted_at timestamptz, updated_by uuid references app_users(id)
);
create table if not exists inventory_movements (
 id uuid primary key default gen_random_uuid(), item_id uuid not null references catalog_items(id), qty_change numeric not null,
 reason text not null, reference_type text, reference_id uuid, created_by uuid references app_users(id), created_at timestamptz not null default now()
);
create table if not exists audit_log (
 id bigint generated always as identity primary key, actor_id uuid references app_users(id), action text not null,
 entity_type text not null, entity_id text, details jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

-- Critical invariant: application delivery service must perform payment check + inventory decrement +
-- stock_deducted_at update in one DB transaction/RPC. A non-null stock_deducted_at makes delivery idempotent.
