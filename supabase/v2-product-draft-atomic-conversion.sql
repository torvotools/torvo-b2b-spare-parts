-- TORVO V2: atomic draft -> catalog conversion. STAGING FIRST; production requires Owner approval.
-- Single PostgreSQL transaction: any error rolls back catalog, inventory, draft status and audit.
create or replace function public.admin_convert_product_draft(
 p_draft_id uuid,p_item_type text,p_item_code text,p_name text,
 p_oem_code text default null,p_brand text default null,p_category text default null,
 p_model text default null,p_image_url text default null,p_gst_mode text default null,
 p_active boolean default true
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_draft product_draft_library%rowtype;v_item uuid;v_code text;
begin
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true;
 if v_user.id is null or v_user.role not in ('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if p_draft_id is null then raise exception 'DRAFT ID REQUIRED';end if;
 v_code:=torvo_normalize_business_text(p_item_code);
 if v_code is null or v_code='' then raise exception 'ITEM CODE REQUIRED';end if;
 -- Match existing draft-save advisory key for serializing same-code draft creation.
 perform pg_advisory_xact_lock(hashtextextended('TORVO_PRODUCT_DRAFT_CODE:'||upper(btrim(p_item_code)),0));
 select * into v_draft from product_draft_library where id=p_draft_id and status='draft' for update;
 if not found then raise exception 'DRAFT NOT FOUND OR ALREADY CONVERTED';end if;
 if nullif(torvo_normalize_business_text(v_draft.item_code),'') is null then raise exception 'DRAFT ITEM CODE REQUIRED: SAVE CODE TO DRAFT BEFORE CONVERSION';end if;
 if torvo_normalize_business_text(v_draft.item_code)<>v_code then
  raise exception 'DRAFT CODE CHANGED: UPDATE DRAFT FIRST';end if;
 if exists(select 1 from product_draft_library where status='draft' and id<>p_draft_id and torvo_normalize_business_text(item_code)=v_code) then
  raise exception 'ALREADY EXISTS: ITEM CODE IN ANOTHER DRAFT';end if;
 -- Release this draft code before inserting the catalog row; the entire RPC rolls back on any failure.
 update product_draft_library set status='converted',converted_at=now(),updated_by=v_user.id,updated_at=now() where id=p_draft_id and status='draft';
 if not found then raise exception 'DRAFT CONVERSION FAILED';end if;
 v_item:=public.upsert_catalog_item(null,p_item_type,p_item_code,p_name,p_oem_code,p_brand,p_category,p_model,p_image_url,p_gst_mode,p_active);
 update product_draft_library set status='converted',converted_item_id=v_item,converted_at=now(),updated_by=v_user.id,updated_at=now()
 where id=p_draft_id and status='draft';
 if not found then raise exception 'DRAFT CONVERSION FAILED';end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(v_user.id,'PRODUCT_DRAFT_CONVERTED','CATALOG_ITEM',v_item::text,jsonb_build_object('draft_id',p_draft_id,'atomic',true));
 return v_item;
end$$;
revoke all on function public.admin_convert_product_draft(uuid,text,text,text,text,text,text,text,text,text,boolean) from public,anon;
grant execute on function public.admin_convert_product_draft(uuid,text,text,text,text,text,text,text,text,text,boolean) to authenticated;
