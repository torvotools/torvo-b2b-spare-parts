-- TORVO V2 RETIRE LEGACY DEALER RPCS
-- Final device-bound dealer services replace these authenticated browser-callable signatures.
do $$declare r record;begin for r in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname=any(array['dealer_item_rate','submit_purchase_order','dealer_revise_sales_order','dealer_request_sales_order_change','dealer_confirm_sales_order','dealer_create_add_on_order']) loop execute format('revoke execute on function %s from public, anon, authenticated',r.sig);end loop;end$$;
-- Device-bound replacements remain granted by their own final migrations.
