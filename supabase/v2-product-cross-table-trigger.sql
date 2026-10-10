-- TORVO V2: cross-table product-code safety. STAGING FIRST. Owner approval for production.
-- Install AFTER v2-product-draft-atomic-conversion.sql (current version).
-- Guard catalog inserts and code edits against active drafts. Conversion marks its own
-- draft converted within the SAME transaction before inserting; rollback restores it.
create or replace function public.torvo_catalog_draft_code_guard()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_code text;
begin
 v_code:=public.torvo_normalize_business_text(new.item_code);
 if v_code='' then raise exception 'ITEM CODE REQUIRED';end if;
 perform pg_advisory_xact_lock(hashtextextended('TORVO_PRODUCT_DRAFT_CODE:'||v_code,0));
 if exists(
  select 1 from public.product_draft_library d
  where d.status='draft' and public.torvo_normalize_business_text(d.item_code)=v_code
 ) then raise exception 'ALREADY EXISTS: ITEM CODE IN PRODUCT DRAFT LIBRARY. CONVERT THE EXISTING DRAFT INSTEAD';end if;
 return new;
end$$;
drop trigger if exists trg_torvo_catalog_draft_code_guard on public.catalog_items;
create trigger trg_torvo_catalog_draft_code_guard
before insert or update of item_code on public.catalog_items
for each row execute function public.torvo_catalog_draft_code_guard();
revoke all on function public.torvo_catalog_draft_code_guard() from public,anon,authenticated;
