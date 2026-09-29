-- TORVO V2 salesman-assisted workflows. Staging/runtime verification required before production.
-- Every assisted action is attributable to the logged-in salesman and dealer consent is recorded separately.

alter table sales_documents add column if not exists order_source text not null default 'dealer_self' check(order_source in ('dealer_self','salesman_assisted','admin_assisted'));
alter table sales_documents add column if not exists assisted_by uuid references app_users(id) on delete restrict;
alter table sales_documents add column if not exists dealer_consent_method text check(dealer_consent_method in ('whatsapp_confirmation','phone','written_slip','in_person','dealer_self'));
alter table sales_documents add column if not exists dealer_consent_note text;
create index if not exists idx_sales_documents_source on sales_documents(order_source,created_at desc);
create index if not exists idx_sales_documents_assisted_by on sales_documents(assisted_by,created_at desc) where assisted_by is not null;

create table if not exists salesman_assisted_registrations (
  id uuid primary key default gen_random_uuid(),
  dealer_id uuid not null unique references dealers(id) on delete restrict,
  salesman_id uuid not null references app_users(id) on delete restrict,
  whatsapp_number text not null,
  otp_verified boolean not null default false,
  otp_verified_at timestamptz,
  submitted_at timestamptz not null default now(),
  admin_status text not null default 'pending' check(admin_status in ('pending','approved','hold','rejected')),
  reviewed_by uuid references app_users(id) on delete restrict,
  reviewed_at timestamptz,
  review_note text,
  check((otp_verified=false and otp_verified_at is null) or (otp_verified=true and otp_verified_at is not null))
);
create index if not exists idx_salesman_assisted_reg_salesman on salesman_assisted_registrations(salesman_id,submitted_at desc);

-- Do not store OTP plaintext here. The approved WhatsApp OTP service will verify a challenge and only then mark consent.
create table if not exists dealer_consent_events (
  id uuid primary key default gen_random_uuid(),
  dealer_id uuid references dealers(id) on delete restrict,
  salesman_id uuid references app_users(id) on delete restrict,
  entity_type text not null check(entity_type in ('dealer_registration','purchase_order')),
  entity_id uuid not null,
  method text not null check(method in ('whatsapp_otp','whatsapp_confirmation','phone','written_slip','in_person')),
  verified boolean not null default false,
  verification_reference text,
  created_at timestamptz not null default now(),
  verified_at timestamptz
);
create index if not exists idx_dealer_consent_entity on dealer_consent_events(entity_type,entity_id,created_at desc);

-- Server-side helper: salesman can only act for a currently mapped dealer.
create or replace function salesman_can_access_dealer(p_salesman uuid,p_dealer uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1 from salesman_dealer_mappings m
    where m.salesman_id=p_salesman and m.dealer_id=p_dealer and m.active=true
  );
$$;
revoke all on function salesman_can_access_dealer(uuid,uuid) from public,anon;
grant execute on function salesman_can_access_dealer(uuid,uuid) to authenticated;


-- Canonical operational Salesman runtime. Normal Salesman is mapped-only.
alter table dealer_consent_events enable row level security;
revoke all on dealer_consent_events from anon,authenticated;

create or replace function my_salesman_dealers()
returns table(dealer_id uuid,shop_name text,mobile text,city text,rate_group text,status text)
language plpgsql stable security definer set search_path=public as $$declare u app_users%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 return query select d.id,d.shop_name,d.mobile,d.city,d.rate_group,d.status from dealers d join salesman_dealer_mappings m on m.dealer_id=d.id where m.salesman_id=u.id and m.active=true and d.status='approved' order by d.shop_name;
end$$;
revoke all on function my_salesman_dealers() from public,anon;grant execute on function my_salesman_dealers() to authenticated;

create or replace function my_salesman_areas()
returns table(state text,district text,city text)
language plpgsql stable security definer set search_path=public as $$declare u app_users%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 return query select a.state,a.district,a.city from salesman_area_mappings a where a.salesman_id=u.id and a.active=true order by a.state,a.district,a.city;
end$$;
revoke all on function my_salesman_areas() from public,anon;grant execute on function my_salesman_areas() to authenticated;

create or replace function salesman_submit_dealer_order(p_dealer uuid,p_lines jsonb,p_consent_method text,p_consent_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$declare u app_users%rowtype;d dealers%rowtype;ln jsonb;v_doc uuid;v_item uuid;v_qty numeric;v_rate numeric;v_sub numeric:=0;v_method text;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;if u.id is null or u.role<>'salesman' then raise exception 'SALESMAN ACCESS REQUIRED';end if;
 select * into d from dealers where id=p_dealer and status='approved';if d.id is null then raise exception 'APPROVED DEALER REQUIRED';end if;
 if not exists(select 1 from salesman_dealer_mappings m where m.salesman_id=u.id and m.dealer_id=d.id and m.active=true) then raise exception 'DEALER NOT MAPPED TO SALESMAN';end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'ORDER LINES REQUIRED';end if;
 v_method:=lower(btrim(coalesce(p_consent_method,'')));if v_method not in('whatsapp_confirmation','phone','written_slip','in_person') then raise exception 'VALID DEALER CONSENT METHOD REQUIRED';end if;
 insert into sales_documents(dealer_id,doc_type,status,subtotal,final_payable,created_by,order_source,assisted_by,dealer_consent_method,dealer_consent_note) values(d.id,'sales_order','submitted',0,0,u.id,'salesman_assisted',u.id,v_method,nullif(btrim(p_consent_note),'')) returning id into v_doc;
 for ln in select * from jsonb_array_elements(p_lines) loop
  v_item:=(ln->>'item_id')::uuid;v_qty:=(ln->>'qty')::numeric;
  if v_qty<=0 or v_qty<>trunc(v_qty) or v_qty>9999 then raise exception 'QUANTITY MUST BE INTEGER 1..9999';end if;
  if exists(select 1 from sales_document_lines where document_id=v_doc and item_id=v_item) then raise exception 'DUPLICATE ITEM';end if;
  if not exists(select 1 from catalog_items where id=v_item and active=true) then raise exception 'ACTIVE ITEM REQUIRED';end if;
  select ir.selling_rate into v_rate from item_rates ir where ir.item_id=v_item and ir.rate_group=d.rate_group and ir.min_qty<=v_qty order by ir.min_qty desc limit 1;
  if v_rate is null then raise exception 'DEALER RATE NOT CONFIGURED';end if;
  insert into sales_document_lines(document_id,item_id,qty,rate,amount) values(v_doc,v_item,v_qty,v_rate,v_qty*v_rate);v_sub:=v_sub+(v_qty*v_rate);
 end loop;
 update sales_documents set subtotal=v_sub,final_payable=v_sub where id=v_doc;
 insert into dealer_consent_events(dealer_id,salesman_id,entity_type,entity_id,method,verified,verification_reference,verified_at) values(d.id,u.id,'purchase_order',v_doc,v_method,true,nullif(btrim(p_consent_note),''),now());
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'SALESMAN_ASSISTED_ORDER_SUBMITTED','sales_document',v_doc::text,jsonb_build_object('dealer_id',d.id,'consent_method',v_method,'line_count',jsonb_array_length(p_lines)));
 return v_doc;
end$$;
revoke all on function salesman_submit_dealer_order(uuid,jsonb,text,text) from public,anon;grant execute on function salesman_submit_dealer_order(uuid,jsonb,text,text) to authenticated;
