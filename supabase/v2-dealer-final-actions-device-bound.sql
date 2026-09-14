-- TORVO V2 FINAL DEALER ACTION DEVICE BOUNDARY
-- Install after v2-sales-revision-rpcs.sql and v2-dealer-order-device-bound.sql.

create or replace function dealer_revise_sales_order_device(p_sales_order uuid,p_lines jsonb,p_reason text,p_device_id text,p_session_token text)
returns integer language plpgsql security definer set search_path=public as $$declare did uuid;begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);perform 1 from sales_documents where id=p_sales_order and dealer_id=did and doc_type='sales_order';if not found then raise exception 'SALES ORDER NOT AVAILABLE';end if;return dealer_revise_sales_order(p_sales_order,p_lines,p_reason);end$$;

create or replace function dealer_request_sales_order_change_device(p_sales_order uuid,p_type text,p_reason text,p_device_id text,p_session_token text)
returns uuid language plpgsql security definer set search_path=public as $$declare did uuid;begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);perform 1 from sales_documents where id=p_sales_order and dealer_id=did and doc_type='sales_order';if not found then raise exception 'SALES ORDER NOT AVAILABLE';end if;return dealer_request_sales_order_change(p_sales_order,p_type,p_reason);end$$;

create or replace function dealer_approved_add_on_requests(p_device_id text,p_session_token text)
returns table(id uuid,sales_order_id uuid,reason text,admin_note text,reviewed_at timestamptz,created_at timestamptz) language plpgsql security definer set search_path=public as $$declare did uuid;begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);return query select r.id,r.sales_order_id,r.reason,r.admin_note,r.reviewed_at,r.created_at from sales_order_change_requests r where r.dealer_id=did and r.request_type='add_more_items' and r.status='approved' and r.linked_add_on_order_id is null order by r.created_at desc;end$$;

create or replace function dealer_create_add_on_order_device(p_request uuid,p_lines jsonb,p_device_id text,p_session_token text)
returns uuid language plpgsql security definer set search_path=public as $$declare did uuid;begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);perform 1 from sales_order_change_requests where id=p_request and dealer_id=did and request_type='add_more_items' and status='approved' and linked_add_on_order_id is null;if not found then raise exception 'APPROVED ADD MORE ITEMS REQUEST REQUIRED';end if;return dealer_create_add_on_order(p_request,p_lines);end$$;

revoke all on function dealer_revise_sales_order_device(uuid,jsonb,text,text,text),dealer_request_sales_order_change_device(uuid,text,text,text,text),dealer_approved_add_on_requests(text,text),dealer_create_add_on_order_device(uuid,jsonb,text,text) from public,anon;
grant execute on function dealer_revise_sales_order_device(uuid,jsonb,text,text,text),dealer_request_sales_order_change_device(uuid,text,text,text,text),dealer_approved_add_on_requests(text,text),dealer_create_add_on_order_device(uuid,jsonb,text,text) to authenticated;
