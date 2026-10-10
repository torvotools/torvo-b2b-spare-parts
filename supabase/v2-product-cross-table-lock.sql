-- TORVO V2 / STAGING FIRST / CROSS-TABLE ITEM CODE SERIALIZATION
-- Keep existing upsert_catalog_item role, inventory, audit and validation rules intact.
-- Both draft and catalog writes must lock the SAME normalized item-code namespace.
-- Do not apply to production without Owner approval.
do $migration$
declare v_oid oid;v_definition text;v_old text;v_new text;
begin
 select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname='upsert_catalog_item'
 and pg_get_function_identity_arguments(p.oid) like 'p_item uuid, p_type text, p_code text%';
 if v_oid is null then raise exception 'EXPECTED CATALOG SAVE FUNCTION NOT FOUND';end if;
 v_definition:=pg_get_functiondef(v_oid);
 v_old:='if exists(select 1 from catalog_items x where torvo_normalize_business_text(x.item_code)=v_code and (p_item is null or x.id<>p_item)) then';
 v_new:='perform pg_advisory_xact_lock(hashtextextended(''TORVO_PRODUCT_DRAFT_CODE:''||v_code,0));'
 ||'if exists(select 1 from product_draft_library d where d.status=''draft'' and torvo_normalize_business_text(d.item_code)=v_code) then '
 ||'raise exception ''ALREADY EXISTS: ITEM CODE IN PRODUCT DRAFT LIBRARY'';end if;'
 ||v_old;
 if position(v_old in v_definition)=0 then
  raise exception 'CATALOG SAVE FUNCTION HAS CHANGED: REVIEW REQUIRED, NO MIGRATION APPLIED';
 end if;
 if position('TORVO_PRODUCT_DRAFT_CODE:' in v_definition)>0 then
  raise exception 'CATALOG SAVE FUNCTION ALREADY HAS CROSS-TABLE LOCK: REVIEW REQUIRED';
 end if;
 execute replace(v_definition,v_old,v_new);
end
$migration$;
