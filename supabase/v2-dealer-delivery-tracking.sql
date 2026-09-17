-- TORVO V2 DEALER DELIVERY TRACKING
-- Dealer-safe, device-bound delivery status. Financial/payment/internal stock fields are intentionally excluded.

drop function if exists get_dealer_delivery_tracking(text,text);

create or replace function get_dealer_delivery_tracking(p_device_id text,p_session_token text)
returns table(
  estimate_id uuid,
  sales_order_id uuid,
  delivery_status text,
  tracking_code text,
  delivered_at timestamptz,
  updated_at timestamptz
) language plpgsql security definer set search_path=public as $$
declare did uuid;
begin
  did:=dealer_assert_my_device_session(p_device_id,p_session_token);
  return query
  select
    d.estimate_id,
    coalesce(e.parent_id,e.root_order_id) as sales_order_id,
    d.status::text as delivery_status,
    d.tracking_code::text,
    d.delivered_at,
    coalesce(d.delivered_at,e.created_at) as updated_at
  from dispatches d
  join sales_documents e on e.id=d.estimate_id and e.doc_type='estimate'
  where e.dealer_id=did
  order by coalesce(d.delivered_at,e.created_at) desc;
end$$;

revoke all on function get_dealer_delivery_tracking(text,text) from public,anon;
grant execute on function get_dealer_delivery_tracking(text,text) to authenticated;
