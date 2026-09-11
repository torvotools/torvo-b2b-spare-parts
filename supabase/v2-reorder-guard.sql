-- TORVO V2 duplicate active reorder protection.
-- Run after v2-extended-schema.sql and v2-operations-rpcs.sql.
-- Existing duplicate active rows must be reviewed before creating the unique index.

do $$
begin
 if exists(
  select 1 from stock_reorder_requests
  where status in('submitted','ordered')
  group by item_id having count(*)>1
 ) then
  raise exception 'Duplicate active reorder requests exist. Resolve them before applying v2-reorder-guard.sql';
 end if;
end$$;

create unique index if not exists ux_stock_reorder_one_active_per_item
 on stock_reorder_requests(item_id)
 where status in('submitted','ordered');

create or replace function submit_reorder(p_item uuid,p_required_qty numeric) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v uuid;existing uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','store_keeper') then raise exception 'Not authorized';end if;
 if p_required_qty is null or p_required_qty<=0 or not exists(select 1 from catalog_items where id=p_item) then raise exception 'Invalid reorder request';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_item::text,0));
 select id into existing from stock_reorder_requests where item_id=p_item and status in('submitted','ordered') order by created_at desc limit 1;
 if existing is not null then raise exception 'An active reorder request already exists for this item';end if;
 insert into stock_reorder_requests(item_id,required_qty,submitted_by) values(p_item,p_required_qty,a.id) returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REORDER_SUBMITTED','stock_reorder',v::text,jsonb_build_object('item_id',p_item,'required_qty',p_required_qty));
 return v;
end;$$;
revoke all on function submit_reorder(uuid,numeric) from public,anon;grant execute on function submit_reorder(uuid,numeric) to authenticated;
