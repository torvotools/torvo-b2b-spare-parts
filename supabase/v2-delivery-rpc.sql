-- TORVO V2 atomic delivery operation.
-- Stock is deducted only when an authorized authenticated employee performs DELIVERY
-- after a valid payment, and it is deducted exactly once.
create or replace function deliver_estimate(p_estimate uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user uuid := auth.uid();
  v_actor app_users%rowtype;
  v_estimate sales_documents%rowtype;
  v_dispatch dispatches%rowtype;
  v_line record;
begin
  if v_auth_user is null then
    raise exception 'Authentication required';
  end if;

  select * into v_actor
  from app_users
  where auth_user_id = v_auth_user and active = true;

  if not found then
    raise exception 'Active application user not found';
  end if;

  if v_actor.role not in ('owner','admin','store_keeper') then
    raise exception 'Not authorized to deliver orders';
  end if;

  select * into v_estimate
  from sales_documents
  where id = p_estimate
  for update;

  if not found then
    raise exception 'Estimate not found';
  end if;

  if v_estimate.doc_type <> 'estimate' then
    raise exception 'Delivery requires an estimate document';
  end if;

  select * into v_dispatch
  from dispatches
  where estimate_id = p_estimate
  for update;

  if not found then
    raise exception 'Dispatch record not found';
  end if;

  -- Idempotency guard. A delivered estimate can never deduct stock twice.
  if v_dispatch.stock_deducted_at is not null or v_dispatch.status = 'delivered' then
    raise exception 'Delivery already completed for this estimate';
  end if;

  if v_dispatch.status <> 'ready_for_dispatch' then
    raise exception 'Order must be ready for dispatch before delivery';
  end if;

  if not exists (
    select 1
    from payments
    where estimate_id = p_estimate
      and status in ('received','cash')
      and amount >= v_estimate.final_payable
  ) then
    raise exception 'Full payment must be received before delivery';
  end if;

  if not exists (select 1 from sales_document_lines where document_id = p_estimate) then
    raise exception 'Estimate has no items';
  end if;

  -- Lock every required inventory row before checking/deducting any quantity.
  for v_line in
    select l.item_id, sum(l.qty) as qty
    from sales_document_lines l
    where l.document_id = p_estimate
    group by l.item_id
    order by l.item_id
  loop
    perform 1 from inventory where item_id = v_line.item_id for update;
    if not found then
      raise exception 'Inventory row missing for item %', v_line.item_id;
    end if;

    if (select current_qty from inventory where item_id = v_line.item_id) < v_line.qty then
      raise exception 'Insufficient stock for item %', v_line.item_id;
    end if;
  end loop;

  for v_line in
    select l.item_id, sum(l.qty) as qty
    from sales_document_lines l
    where l.document_id = p_estimate
    group by l.item_id
    order by l.item_id
  loop
    update inventory
      set current_qty = current_qty - v_line.qty,
          updated_at = now()
      where item_id = v_line.item_id;

    insert into inventory_movements(
      item_id, qty_change, reason, reference_type, reference_id, created_by
    ) values (
      v_line.item_id, -v_line.qty, 'Delivery', 'estimate', p_estimate, v_actor.id
    );
  end loop;

  update dispatches
    set status = 'delivered',
        delivered_at = now(),
        stock_deducted_at = now(),
        updated_by = v_actor.id
    where id = v_dispatch.id;

  insert into audit_log(actor_id, action, entity_type, entity_id, details)
  values (
    v_actor.id,
    'DELIVER_AND_DEDUCT_STOCK',
    'estimate',
    p_estimate::text,
    jsonb_build_object(
      'dispatch_id', v_dispatch.id,
      'payment_verified', true,
      'stock_deducted_once', true
    )
  );
end;
$$;

revoke all on function deliver_estimate(uuid) from public;
revoke all on function deliver_estimate(uuid) from anon;
grant execute on function deliver_estimate(uuid) to authenticated;
