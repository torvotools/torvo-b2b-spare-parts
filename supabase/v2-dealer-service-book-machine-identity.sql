-- TORVO V2 SERVICE BOOK MACHINE IDENTITY
-- Optional canonical catalog reference. Manual / outside machines remain valid text snapshots.
alter table dealer_service_jobs add column if not exists machine_catalog_item_id uuid references catalog_items(id) on delete set null;
create index if not exists idx_dealer_service_jobs_machine_catalog on dealer_service_jobs(dealer_id,machine_catalog_item_id) where machine_catalog_item_id is not null;

drop function if exists dealer_service_job_create(text,text,text,text,text,text,text,text,text,text,text,text,text);
create or replace function dealer_service_job_create(p_device_id text,p_session_token text,p_customer_name text,p_mobile text,p_whatsapp text,p_address text,p_machine_photo_url text,p_machine_catalog_item_id uuid,p_machine_brand text,p_machine_type text,p_machine_model text,p_serial_no text,p_complaint_code text,p_complaint_note text)
returns uuid language plpgsql security definer set search_path=public as $$declare did uuid;jid uuid;photo_path text;cm record;begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);photo_path:=trim(coalesce(p_machine_photo_url,''));
 if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'CUSTOMER NAME REQUIRED';end if;
 if nullif(trim(coalesce(p_mobile,'')),'') is not null and regexp_replace(p_mobile,'[^0-9]','','g') !~ '^(91)?[0-9]{10}$' then raise exception 'INVALID CUSTOMER MOBILE';end if;
 if nullif(trim(coalesce(p_whatsapp,'')),'') is not null and regexp_replace(p_whatsapp,'[^0-9]','','g') !~ '^(91)?[0-9]{10}$' then raise exception 'INVALID CUSTOMER WHATSAPP';end if;
 if length(photo_path)<4 then raise exception 'ORIGINAL MACHINE PHOTO REQUIRED';end if;
 if photo_path not like did::text||'/incoming/%' or photo_path like '%..%' then raise exception 'INVALID SERVICE BOOK MEDIA PATH';end if;
 if p_machine_catalog_item_id is not null then
  select id,item_type,brand,category,model,name into cm from catalog_items where id=p_machine_catalog_item_id and active=true;
  if not found or cm.item_type<>'machine' then raise exception 'CATALOG MACHINE UNAVAILABLE';end if;
  p_machine_brand:=coalesce(nullif(trim(cm.brand),''),p_machine_brand);p_machine_type:=coalesce(nullif(trim(cm.category),''),p_machine_type);p_machine_model:=coalesce(nullif(trim(cm.model),''),nullif(trim(cm.name),''),p_machine_model);
 end if;
 if length(trim(coalesce(p_machine_brand,'')))<1 then raise exception 'MACHINE BRAND REQUIRED';end if;if length(trim(coalesce(p_complaint_code,'')))<2 then raise exception 'COMPLAINT REQUIRED';end if;
 insert into dealer_service_jobs(dealer_id,customer_name,mobile,whatsapp,address,machine_photo_url,machine_catalog_item_id,machine_brand,machine_type,machine_model,serial_no,complaint_code,complaint_note)
 values(did,left(trim(p_customer_name),120),nullif(left(trim(coalesce(p_mobile,'')),20),''),nullif(left(trim(coalesce(p_whatsapp,'')),20),''),nullif(left(trim(coalesce(p_address,'')),300),''),left(photo_path,1000),p_machine_catalog_item_id,left(trim(p_machine_brand),100),nullif(left(trim(coalesce(p_machine_type,'')),100),''),nullif(left(trim(coalesce(p_machine_model,'')),120),''),nullif(left(trim(coalesce(p_serial_no,'')),120),''),left(upper(trim(p_complaint_code)),100),nullif(left(trim(coalesce(p_complaint_note,'')),1000),''))
 returning id into jid;return jid;end$$;
revoke all on function dealer_service_job_create(text,text,text,text,text,text,text,uuid,text,text,text,text,text,text) from public,anon;
grant execute on function dealer_service_job_create(text,text,text,text,text,text,text,uuid,text,text,text,text,text,text) to authenticated;

drop function if exists dealer_service_jobs_read(text,text,text,integer);
create or replace function dealer_service_jobs_read(p_device_id text,p_session_token text,p_status text default null,p_limit integer default 100)
returns table(id uuid,token_no bigint,customer_name text,mobile text,whatsapp text,address text,machine_photo_url text,machine_catalog_item_id uuid,machine_brand text,machine_type text,machine_model text,serial_no text,complaint_code text,complaint_note text,status text,repair_charge numeric,machine_in_at timestamptz,ready_at timestamptz,delivered_at timestamptz)
language plpgsql security definer set search_path=public as $$declare did uuid;s text:=lower(trim(coalesce(p_status,'')));lim integer:=least(greatest(coalesce(p_limit,100),1),300);begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;did:=dealer_assert_my_device_session(p_device_id,p_session_token);if s<>'' and s not in('in_shop','repairing','ready','delivered','cancelled')then raise exception 'INVALID SERVICE STATUS';end if;
 return query select j.id,j.token_no,j.customer_name,j.mobile,j.whatsapp,j.address,j.machine_photo_url,j.machine_catalog_item_id,j.machine_brand,j.machine_type,j.machine_model,j.serial_no,j.complaint_code,j.complaint_note,j.status,j.repair_charge,j.machine_in_at,j.ready_at,j.delivered_at from dealer_service_jobs j where j.dealer_id=did and(s='' or j.status=s)order by j.machine_in_at desc limit lim;end$$;
revoke all on function dealer_service_jobs_read(text,text,text,integer) from public,anon;grant execute on function dealer_service_jobs_read(text,text,text,integer) to authenticated;

drop function if exists dealer_service_jobs_search(text,text,text,integer);
create or replace function dealer_service_jobs_search(p_device_id text,p_session_token text,p_query text,p_limit integer default 100)
returns table(id uuid,token_no bigint,customer_name text,mobile text,whatsapp text,address text,machine_photo_url text,machine_catalog_item_id uuid,machine_brand text,machine_type text,machine_model text,serial_no text,complaint_code text,complaint_note text,status text,repair_charge numeric,machine_in_at timestamptz,ready_at timestamptz,delivered_at timestamptz)
language plpgsql security definer set search_path=public as $$declare did uuid;q text:=trim(coalesce(p_query,''));lim integer:=least(greatest(coalesce(p_limit,100),1),300);begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;did:=dealer_assert_my_device_session(p_device_id,p_session_token);if length(q)<1 then raise exception 'SEARCH QUERY REQUIRED';end if;
 return query select j.id,j.token_no,j.customer_name,j.mobile,j.whatsapp,j.address,j.machine_photo_url,j.machine_catalog_item_id,j.machine_brand,j.machine_type,j.machine_model,j.serial_no,j.complaint_code,j.complaint_note,j.status,j.repair_charge,j.machine_in_at,j.ready_at,j.delivered_at from dealer_service_jobs j where j.dealer_id=did and(j.token_no::text=q or j.customer_name ilike '%'||q||'%' or coalesce(j.mobile,'') ilike '%'||q||'%' or coalesce(j.whatsapp,'') ilike '%'||q||'%' or j.machine_brand ilike '%'||q||'%' or coalesce(j.machine_type,'') ilike '%'||q||'%' or coalesce(j.machine_model,'') ilike '%'||q||'%' or coalesce(j.serial_no,'') ilike '%'||q||'%')order by j.machine_in_at desc limit lim;end$$;
revoke all on function dealer_service_jobs_search(text,text,text,integer) from public,anon;grant execute on function dealer_service_jobs_search(text,text,text,integer) to authenticated;
