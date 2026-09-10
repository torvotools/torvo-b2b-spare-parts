-- Atomic delivery operation. Stock is deducted only after a received/cash payment and only once.
create or replace function deliver_estimate(p_estimate uuid,p_actor uuid)
returns void language plpgsql security definer set search_path=public as $$
declare d dispatches%rowtype; ln record;
begin
 select * into d from dispatches where estimate_id=p_estimate for update;
 if not found then raise exception 'Dispatch record not found'; end if;
 if d.stock_deducted_at is not null then raise exception 'Stock already deducted for this estimate'; end if;
 if not exists(select 1 from payments where estimate_id=p_estimate and status in('received','cash')) then
   raise exception 'Payment must be received before delivery';
 end if;
 for ln in select item_id,qty from sales_document_lines where document_id=p_estimate loop
   update inventory set current_qty=current_qty-ln.qty,updated_at=now()
    where item_id=ln.item_id and current_qty>=ln.qty;
   if not found then raise exception 'Insufficient stock for item %',ln.item_id; end if;
   insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by)
    values(ln.item_id,-ln.qty,'Delivery','estimate',p_estimate,p_actor);
 end loop;
 update dispatches set status='delivered',delivered_at=now(),stock_deducted_at=now(),updated_by=p_actor where id=d.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(p_actor,'DELIVER_AND_DEDUCT_STOCK','estimate',p_estimate::text,jsonb_build_object('dispatch_id',d.id));
end;$$;
revoke all on function deliver_estimate(uuid,uuid) from public;
