-- TORVO V2 DEALER DELIVERY TRACKING
-- Dealer-safe, device-bound delivery status. Financial/payment/internal stock fields are intentionally excluded.
-- Requires canonical dispatch/payment delivery foundations and dealer_assert_my_device_session.

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
    e.id as estimate_id,
    coalesce(e.parent_id,e.root_order_id) as sales_order_id,
    case
      when d.status='dispatched' then 'ready_for_dispatch'
      else d.status::text
    end as delivery_status,
    case when d.status in('ready_for_dispatch','dispatched','delivered') then nullif(upper(trim(d.tracking_code::text)),'') else null end as tracking_code,
    case when d.status='delivered' then d.delivered_at else null end as delivered_at,
    coalesce(d.delivered_at,d.updated_at,e.created_at) as updated_at
  from sales_documents e
  join lateral(
    select x.status,x.tracking_code,x.delivered_at,x.updated_at,x.id
    from dispatches x
    where x.estimate_id=e.id
      and x.status in('pick_list','picked','packed','ready_for_dispatch','dispatched','delivered')
    order by
      case x.status when 'delivered' then 6 when 'dispatched' then 5 when 'ready_for_dispatch' then 4 when 'packed' then 3 when 'picked' then 2 when 'pick_list' then 1 else 0 end desc,
      coalesce(x.delivered_at,x.updated_at) desc nulls last,
      x.id desc
    limit 1
  ) d on true
  where e.dealer_id=did and e.doc_type='estimate'
    and e.created_at>=now()-interval '90 days'
  order by coalesce(d.delivered_at,d.updated_at,e.created_at) desc,e.id desc;
end$$;

revoke all on function get_dealer_delivery_tracking(text,text) from public,anon;
grant execute on function get_dealer_delivery_tracking(text,text) to authenticated;
