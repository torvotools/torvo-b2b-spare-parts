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
    coalesce(e.final_payable,0),
    least(coalesce(e.final_payable,0),coalesce(p.received,0)),
    greatest(coalesce(e.final_payable,0)-coalesce(p.received,0),0),
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
    nullif(upper(trim(d.tracking_code::text)),''),
    d.delivered_at,
    e.created_at
  from sales_documents e
  left join lateral(
    select coalesce(sum(x.amount),0) received
    from payments x
    where x.estimate_id=e.id and x.status in('received','cash')
  ) p on true
  left join dispatches d on d.estimate_id=e.id
  where e.dealer_id=did and e.doc_type='estimate'
    and e.created_at>=now()-interval '90 days'
  order by e.created_at desc,e.id desc;
end$$;

revoke all on function get_dealer_payment_fulfilment(text,text) from public,anon;
grant execute on function get_dealer_payment_fulfilment(text,text) to authenticated;
