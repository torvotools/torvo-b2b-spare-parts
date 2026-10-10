-- TORVO V2 / STAGING ONLY / READ-ONLY PRODUCT CONVERSION CONTRACT AUDIT
-- Safe to run repeatedly. Does not create users, products, drafts or transactions.
-- This audit proves installed structural guards, NOT authenticated Owner E2E conversion.
do $audit$
declare
 v_catalog_trigger boolean;
 v_draft_trigger boolean;
 v_conversion text;
 v_legacy_anon boolean;
 v_legacy_auth boolean;
 v_conversion_auth boolean;
 v_conversion_anon boolean;
 v_conflicts bigint;
begin
 select exists(select 1 from pg_trigger where tgrelid='public.catalog_items'::regclass
  and tgname='trg_torvo_catalog_draft_code_guard' and tgenabled='O' and not tgisinternal)
 into v_catalog_trigger;
 select exists(select 1 from pg_trigger where tgrelid='public.product_draft_library'::regclass
  and tgname='trg_torvo_draft_catalog_code_guard' and tgenabled='O' and not tgisinternal)
 into v_draft_trigger;
 if not v_catalog_trigger then raise exception 'CATALOG DRAFT CODE GUARD NOT ENABLED'; end if;
 if not v_draft_trigger then raise exception 'DRAFT CATALOG CODE GUARD NOT ENABLED'; end if;
 select pg_get_functiondef('public.admin_convert_product_draft(uuid,text,text,text,text,text,text,text,text,text,boolean)'::regprocedure)
 into v_conversion;
 if position('status = ''converted''' in v_conversion)=0 and position('status=''converted''' in v_conversion)=0 then
  raise exception 'ATOMIC CONVERSION FINAL LINKAGE FIX MISSING';
 end if;
 if position('converted_item_id is null' in lower(v_conversion))=0 then
  raise exception 'ATOMIC CONVERSION FINAL LINKAGE GUARD MISSING';
 end if;
 select has_function_privilege('anon','public.admin_convert_product_draft(uuid,text,text,text,text,text,text,text,text,text,boolean)','EXECUTE')
 into v_conversion_anon;
 select has_function_privilege('authenticated','public.admin_convert_product_draft(uuid,text,text,text,text,text,text,text,text,text,text,boolean)','EXECUTE')
 into v_conversion_auth;
 if v_conversion_anon or not v_conversion_auth then raise exception 'ATOMIC CONVERSION EXECUTE GRANTS INVALID';end if;
 if to_regprocedure('public.admin_mark_product_draft_converted(uuid,uuid)') is not null then
  select has_function_privilege('anon','public.admin_mark_product_draft_converted(uuid,uuid)','EXECUTE'),
         has_function_privilege('authenticated','public.admin_mark_product_draft_converted(uuid,uuid)','EXECUTE')
   into v_legacy_anon,v_legacy_auth;
  if v_legacy_anon or v_legacy_auth then raise exception 'UNSAFE LEGACY CONVERSION RPC STILL ACCESSIBLE';end if;
 end if;
 select count(*) into v_conflicts
 from public.catalog_items c join public.product_draft_library d
 on public.torvo_normalize_business_text(c.item_code)=public.torvo_normalize_business_text(d.item_code)
 where d.status='draft' and nullif(public.torvo_normalize_business_text(c.item_code),'') is not null;
 if v_conflicts<>0 then raise exception 'ACTIVE DRAFT / CATALOG ITEM CODE COLLISION: %',v_conflicts;end if;
 raise notice 'PASS: product draft/catalog guards, atomic linkage, RPC grants and existing-code collision audit. Owner E2E still required.';
end
$audit$;
