-- TORVO V2 DEALER PAYMENT + FULFILMENT VISIBILITY
-- Dealer-safe read model: exposes only the dealer's estimate total, received total and public fulfilment stage.
-- No purchase cost, inventory quantity, staff identity or internal accounting fields are exposed.

drop function if exists get_dealer_payment_fulfilment(text,text);

create or replace function get_dealer_payment_fulfilment(p_device_id text,p_session_token text)
returns table(
  estimate_id uuid,
  sales_order_id uuid,
  final_payable numeric,
  received_amount numeric,
  balance_amount numeric,
  payment_status text,
  fulfilment_status text,
  tracking_code text,
  delivered_at timestamptz,
  estimate_created_at timestamptz
) language plpgsql security definer set search_path=public as $$
declare did uuid;
begin
  did:=dealer_assert_my_device_session(p_device_id,p_session_token);
  return query
  select
    e.id,
    coalesce(e.parent_id,e.root_order_id),
    greatest(coalesce(e.final_payable,0),0),
    least(greatest(coalesce(e.final_payable,0),0),greatest(coalesce(p.received,0),0)),
    greatest(coalesce(e.final_payable,0)-greatest(coalesce(p.received,0),0),0),
    case
      when coalesce(e.final_payable,0)<=0 then 'NOT_DUE'
      when coalesce(p.received,0)<=0 then 'PAYMENT_PENDING'
      when coalesce(p.received,0)<coalesce(e.final_payable,0) then 'PART_PAID'
      else 'PAID'
    end,
    case
      when d.status='delivered' then 'DELIVERED'
      when d.status in('ready_for_dispatch','dispatched') then 'READY_FOR_DISPATCH'
      when d.status='packed' then 'PACKED'
      when d.status='picked' then 'PICKED'
      when d.status='pick_list' then 'PICK_LIST'
      else 'ESTIMATE_CREATED'
    end,
    case when d.status in('ready_for_dispatch','dispatched','delivered') then nullif(upper(trim(d.tracking_code::text)),'') else null end,
    case when d.status='delivered' then d.delivered_at else null end,
    e.created_at
  from sales_documents e
  left join lateral(
    select coalesce(sum(x.amount),0) received
    from payments x
    where x.estimate_id=e.id and x.status in('received','cash')
  ) p on true
  left join lateral(
    select x.status,x.tracking_code,x.delivered_at,x.updated_at
    from dispatches x
    where x.estimate_id=e.id
    order by
      case x.status when 'delivered' then 6 when 'dispatched' then 5 when 'ready_for_dispatch' then 4 when 'packed' then 3 when 'picked' then 2 when 'pick_list' then 1 else 0 end desc,
      coalesce(x.delivered_at,x.updated_at) desc nulls last,
      x.id desc
    limit 1
  ) d on true
  where e.dealer_id=did and e.doc_type='estimate'
    and e.created_at>=now()-interval '90 days'
  order by e.created_at desc,e.id desc;
end$$;

revoke all on function get_dealer_payment_fulfilment(text,text) from public,anon;
grant execute on function get_dealer_payment_fulfilment(text,text) to authenticated;
