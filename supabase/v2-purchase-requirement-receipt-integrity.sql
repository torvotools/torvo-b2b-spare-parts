-- TORVO V2 PURCHASE REQUIREMENT RECEIPT INTEGRITY
-- Requires v2-purchase-entry-integrity.sql and v2-purchase-requirement-fulfilment.sql.
-- A Purchase Requirement may be fulfilled only from supplier stock actually received through Purchase Entry.
-- Linking/allocating requirement demand NEVER changes inventory.
-- STAGING RUNTIME VERIFICATION REQUIRED BEFORE PRODUCTION.

-- Prevent concurrent active links for the same requirement/purchase pair while preserving audited reversed history.
create unique index if not exists uq_purchase_requirement_active_purchase_link
on public.purchase_requirement_links(requirement_id,purchase_id)
where reversed_at is null;

create or replace function public.get_requirement_purchase_candidates(p_requirement uuid,p_limit integer default 100)
returns table(purchase_id uuid,invoice_no text,invoice_date date,supplier_name text,purchased_item_qty numeric,allocated_item_qty numeric,available_item_qty numeric)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r purchase_requirements%rowtype;link_item uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;
 select * into r from purchase_requirements where id=p_requirement;if not found then raise exception 'Requirement not found';end if;
 if r.request_type='new_item' then select created_item_id into link_item from purchase_requirement_new_items where requirement_id=r.id;else link_item:=r.existing_item_id;end if;
 if link_item is null then raise exception 'Create/link the catalog item before fulfilment';end if;
 return query
 with bought as(
   select h.id,h.invoice_no,h.invoice_date,h.created_at,h.supplier_id,sum(l.qty) qty
   from purchase_headers h
   join purchase_stock_receipts psr on psr.purchase_id=h.id and psr.reversed_at is null
   join purchase_lines l on l.purchase_id=h.id and l.item_id=link_item
   group by h.id
 ),allocated as(
   select prl.purchase_id,coalesce(sum(prl.linked_qty),0) qty
   from purchase_requirement_links prl
   where prl.item_id=link_item and prl.reversed_at is null
   group by prl.purchase_id
 )
 select b.id,b.invoice_no,b.invoice_date,case when a.role='owner' then s.supplier_name else null end,
        b.qty,coalesce(x.qty,0),greatest(b.qty-coalesce(x.qty,0),0)
 from bought b left join allocated x on x.purchase_id=b.id left join suppliers s on s.id=b.supplier_id
 where b.qty>coalesce(x.qty,0)
 order by b.invoice_date desc,b.created_at desc
 limit greatest(1,least(coalesce(p_limit,100),200));
end;$$;
revoke all on function public.get_requirement_purchase_candidates(uuid,integer) from public,anon;
grant execute on function public.get_requirement_purchase_candidates(uuid,integer) to authenticated;

create or replace function public.link_purchase_to_requirement(p_requirement uuid,p_purchase uuid,p_qty numeric,p_note text default null) returns numeric
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r purchase_requirements%rowtype;approved numeric;already numeric;remaining numeric;link_item uuid;purchase_qty numeric;new_link uuid;alloc_left numeric;d record;give_qty numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;
 if p_qty is null or p_qty<=0 then raise exception 'Valid linked quantity required';end if;
 select * into r from purchase_requirements where id=p_requirement for update;
 if not found then raise exception 'Requirement not found';end if;
 if r.status not in('approved','purchasing','partially_purchased') then raise exception 'Requirement is not open for purchase fulfilment';end if;
 if r.request_type='new_item' then
   select created_item_id into link_item from purchase_requirement_new_items where requirement_id=r.id;
   if link_item is null then raise exception 'Create/link the catalog item before fulfilling a new-item requirement';end if;
 else link_item:=r.existing_item_id;end if;
 perform 1 from purchase_headers where id=p_purchase for update;if not found then raise exception 'Purchase not found';end if;
 -- Critical guard: a saved Purchase Entry is not fulfilment until its stock receipt completed and remains unreversed.
 perform 1 from purchase_stock_receipts where purchase_id=p_purchase and reversed_at is null for update;
 if not found then raise exception 'Purchase stock has not been received or was reversed';end if;
 select coalesce(sum(qty),0) into purchase_qty from purchase_lines where purchase_id=p_purchase and item_id=link_item;
 if purchase_qty<=0 then raise exception 'Selected Purchase does not contain the requirement item';end if;
 select coalesce(sum(linked_qty),0) into already from purchase_requirement_links where purchase_id=p_purchase and item_id=link_item and reversed_at is null;
 if already+p_qty>purchase_qty then raise exception 'Linked quantity exceeds received Purchase quantity for this item';end if;
 approved:=coalesce(r.approved_qty,r.requested_qty);remaining:=greatest(approved-r.purchased_qty,0);
 if remaining<=0 then raise exception 'Requirement is already fully purchased';end if;
 if p_qty>remaining then raise exception 'Linked quantity exceeds remaining approved requirement';end if;
 if exists(select 1 from purchase_requirement_links where requirement_id=r.id and purchase_id=p_purchase and reversed_at is null) then raise exception 'This Purchase is already linked to the requirement';end if;
 insert into purchase_requirement_links(requirement_id,purchase_id,linked_by,linked_qty,item_id,note)
 values(r.id,p_purchase,a.id,p_qty,link_item,nullif(trim(p_note),'')) returning id into new_link;
 update purchase_requirements set purchased_qty=purchased_qty+p_qty,status=case when purchased_qty+p_qty>=approved then 'completed' else 'partially_purchased' end where id=r.id;
 alloc_left:=p_qty;
 for d in select id,greatest(coalesce(requested_qty,0)-fulfilled_qty,0) need from purchase_requirement_dealers where requirement_id=r.id and greatest(coalesce(requested_qty,0)-fulfilled_qty,0)>0 order by id for update loop
   exit when alloc_left<=0;give_qty:=least(d.need,alloc_left);
   if give_qty>0 then
     update purchase_requirement_dealers set fulfilled_qty=fulfilled_qty+give_qty,stock_arrival_recorded_at=now() where id=d.id;
     insert into purchase_requirement_link_dealer_allocations(link_id,requirement_dealer_id,allocated_qty) values(new_link,d.id,give_qty);
     alloc_left:=alloc_left-give_qty;
   end if;
 end loop;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'PURCHASE_REQUIREMENT_PURCHASE_LINKED','purchase_requirement',r.id::text,jsonb_build_object('link_id',new_link,'purchase_id',p_purchase,'item_id',link_item,'linked_qty',p_qty,'dealer_allocated_qty',p_qty-alloc_left,'previous_purchased_qty',r.purchased_qty,'new_purchased_qty',r.purchased_qty+p_qty,'purchase_stock_received',true));
 return r.purchased_qty+p_qty;
end;$$;
revoke all on function public.link_purchase_to_requirement(uuid,uuid,numeric,text) from public,anon;
grant execute on function public.link_purchase_to_requirement(uuid,uuid,numeric,text) to authenticated;

-- Do not permit Purchase stock reversal while active requirement allocations still depend on that receipt.
create or replace function public.reverse_purchase_entry(p_purchase uuid,p_reason text) returns void
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;h purchase_headers%rowtype;r purchase_stock_receipts%rowtype;l record;current_stock numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Reversal reason required';end if;
 select * into h from purchase_headers where id=p_purchase for update;if not found then raise exception 'Purchase not found';end if;
 select * into r from purchase_stock_receipts where purchase_id=p_purchase for update;
 if not found then raise exception 'Purchase stock was never received';end if;
 if r.reversed_at is not null then raise exception 'Purchase already reversed';end if;
 if exists(select 1 from purchase_requirement_links where purchase_id=p_purchase and reversed_at is null) then
   raise exception 'Reverse active Purchase Requirement links before reversing Purchase stock';
 end if;
 for l in select item_id,sum(qty) qty from purchase_lines where purchase_id=p_purchase group by item_id order by item_id loop
   select current_qty into current_stock from inventory where item_id=l.item_id for update;
   if not found or current_stock<l.qty then raise exception 'Cannot reverse: current stock is lower than received Purchase quantity';end if;
 end loop;
 for l in select item_id,sum(qty) qty from purchase_lines where purchase_id=p_purchase group by item_id order by item_id loop
   update inventory set current_qty=current_qty-l.qty,updated_at=now() where item_id=l.item_id;
   insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by)
   values(l.item_id,-l.qty,'PURCHASE REVERSAL: '||upper(trim(p_reason)),'purchase_reversal',p_purchase,a.id);
 end loop;
 update purchase_stock_receipts set reversed_at=now(),reversed_by=a.id,reversal_reason=upper(trim(p_reason)) where purchase_id=p_purchase;
 insert into audit_log(actor_id,action,entity_type,entity_id,details)
 values(a.id,'PURCHASE_REVERSED','purchase',p_purchase::text,jsonb_build_object('reason',upper(trim(p_reason)),'invoice_no',h.invoice_no,'stock_reversed_once',true,'active_requirement_links',false));
end;$$;
revoke all on function public.reverse_purchase_entry(uuid,text) from public,anon;
grant execute on function public.reverse_purchase_entry(uuid,text) to authenticated;
