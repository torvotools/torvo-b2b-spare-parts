-- TORVO V2: guard draft direct writes against existing catalog item codes.
-- STAGING FIRST. Install AFTER v2-product-cross-table-trigger.sql.
-- The existing catalog trigger and this draft trigger share an advisory transaction key.
-- Atomic conversion changes draft status before catalog insert in the same transaction.
create or replace function public.torvo_draft_catalog_code_guard()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_code text;
begin
 if new.status <> 'draft' then return new; end if;
 v_code := public.torvo_normalize_business_text(new.item_code);
 if v_code = '' then return new; end if; -- Photo/name-only drafts may be incomplete.
 perform pg_advisory_xact_lock(hashtextextended('TORVO_PRODUCT_DRAFT_CODE:'||v_code,0));
 if exists (select 1 from public.catalog_items c
            where public.torvo_normalize_business_text(c.item_code)=v_code) then
  raise exception 'ALREADY EXISTS: ITEM CODE IN PRODUCT MASTER';
 end if;
 return new;
end$$;
drop trigger if exists trg_torvo_draft_catalog_code_guard on public.product_draft_library;
create trigger trg_torvo_draft_catalog_code_guard
before insert or update of item_code,status on public.product_draft_library
for each row execute function public.torvo_draft_catalog_code_guard();
revoke all on function public.torvo_draft_catalog_code_guard() from public,anon,authenticated;
