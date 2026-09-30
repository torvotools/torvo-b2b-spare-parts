-- TORVO V2 FINAL DEALER WORKSPACE READ BOUNDARY
-- Dealer catalog used by the private ordering workspace must fail immediately for a revoked old mobile.
create or replace function dealer_workspace_catalog(p_device_id text,p_session_token text)
returns table(id uuid,item_type text,item_code text,oem_code text,name text,brand text,category text,model text,image_url text,active boolean)
language plpgsql security definer set search_path=public as $$declare did uuid;begin
did:=dealer_assert_my_device_session(p_device_id,p_session_token);
return query select c.id,c.item_type,c.item_code,c.oem_code,c.name,c.brand,c.category,c.model,c.image_url,c.active from catalog_items c where c.active=true and c.item_type in('machine','spare_part','accessory') order by c.item_type,c.name;
end$$;
revoke all on function dealer_workspace_catalog(text,text) from public,anon;
grant execute on function dealer_workspace_catalog(text,text) to authenticated;

-- History is also device-bound here so the dealer portal never needs direct sales_documents access.
drop function if exists dealer_workspace_order_history(text,text);
create or replace function dealer_workspace_order_history(p_device_id text,p_session_token text)
returns table(document_id uuid,document_type text,document_status text,revision_no integer,subtotal numeric,freight numeric,other_charges numeric,final_payable numeric,created_at timestamptz,parent_id uuid,root_order_id uuid,linked_sales_order_id uuid)
language plpgsql security definer set search_path=public as $declare did uuid;begin
did:=dealer_assert_my_device_session(p_device_id,p_session_token);
return query select d.id,d.doc_type,d.status,d.revision_no,d.subtotal,d.freight,d.other_charges,d.final_payable,d.created_at,d.parent_id,d.root_order_id,case when d.doc_type='estimate' then coalesce(d.parent_id,d.root_order_id) else d.id end from sales_documents d where d.dealer_id=did and d.doc_type in('sales_order','estimate') and d.created_at>=now()-interval '30 days' order by d.created_at desc;
end$;
revoke all on function dealer_workspace_order_history(text,text) from public,anon;
grant execute on function dealer_workspace_order_history(text,text) to authenticated;
