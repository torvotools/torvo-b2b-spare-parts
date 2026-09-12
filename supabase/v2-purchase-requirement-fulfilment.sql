-- TORVO V2 purchase requirement fulfilment / partial-purchase linkage.
-- Requires v2-purchase-requirements.sql and purchase_headers/purchase_lines from the core purchase schema.
-- Staging review required before production.

alter table purchase_requirements add column if not exists purchased_qty numeric not null default 0;
alter table purchase_requirements drop constraint if exists purchase_requirements_purchased_qty_check;
alter table purchase_requirements add constraint purchase_requirements_purchased_qty_check check(purchased_qty>=0);

alter table purchase_requirement_links add column if not exists linked_qty numeric not null default 0;
alter table purchase_requirement_links add column if not exists item_id uuid references catalog_items(id);
alter table purchase_requirement_links add column if not exists note text;
alter table purchase_requirement_links add column if not exists reversed_at timestamptz;
alter table purchase_requirement_links add column if not exists reversed_by uuid references app_users(id);

create index if not exists idx_purchase_requirement_links_requirement on purchase_requirement_links(requirement_id,linked_at desc);
create index if not exists idx_purchase_requirement_links_purchase on purchase_requirement_links(purchase_id);

-- Owner/Admin-only fulfilment finder. Deliberately returns no Purchase Rate / line amount.
create or replace function get_requirement_purchase_candidates(p_requirement uuid,p_limit integer default 100)
returns table(purchase_id uuid,invoice_no text,invoice_date date,supplier_name text,purchased_item_qty numeric,allocated_item_qty numeric,available_item_qty numeric)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;r purchase_requirements%rowtype;link_item uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 select * into r from purchase_requirements where id=p_requirement;if not found then raise exception 'Requirement not found'; end if;
 if r.request_type='new_item' then select created_item_id into link_item from purchase_requirement_new_items where requirement_id=r.id;else link_item:=r.existing_item_id;end if;
 if link_item is null then raise exception 'Create/link the catalog item before fulfilment'; end if;
 return query with bought as(select h.id,h.invoice_no,h.invoice_date,h.created_at,h.supplier_id,sum(l.qty) qty from purchase_headers h join purchase_lines l on l.purchase_id=h.id and l.item_id=link_item where not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED') group by h.id),allocated as(select prl.purchase_id,coalesce(sum(prl.linked_qty),0) qty from purchase_requirement_links prl where prl.item_id=link_item and prl.reversed_at is null group by prl.purchase_id) select b.id,b.invoice_no,b.invoice_date,s.name,b.qty,coalesce(x.qty,0),greatest(b.qty-coalesce(x.qty,0),0) from bought b left join allocated x on x.purchase_id=b.id left join suppliers s on s.id=b.supplier_id where b.qty>coalesce(x.qty,0) order by b.invoice_date desc,b.created_at desc limit greatest(1,least(coalesce(p_limit,100),200));
end;$$;
revoke all on function get_requirement_purchase_candidates(uuid,integer) from public,anon;
grant execute on function get_requirement_purchase_candidates(uuid,integer) to authenticated;

create or replace function get_purchase_requirement_links(p_requirement uuid)
returns table(id uuid,purchase_id uuid,invoice_no text,invoice_date date,supplier_name text,linked_qty numeric,item_id uuid,note text,linked_at timestamptz,reversed_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if not exists(select 1 from purchase_requirements where purchase_requirements.id=p_requirement) then raise exception 'Requirement not found'; end if;
 return query select l.id,l.purchase_id,h.invoice_no,h.invoice_date,s.name,l.linked_qty,l.item_id,l.note,l.linked_at,l.reversed_at from purchase_requirement_links l join purchase_headers h on h.id=l.purchase_id left join suppliers s on s.id=h.supplier_id where l.requirement_id=p_requirement order by l.linked_at desc;
end;$$;
revoke all on function get_purchase_requirement_links(uuid) from public,anon;
grant execute on function get_purchase_requirement_links(uuid) to authenticated;

create or replace function link_purchase_to_requirement(p_requirement uuid,p_purchase uuid,p_qty numeric,p_note text default null) returns numeric
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r purchase_requirements%rowtype;approved numeric;already numeric;remaining numeric;link_item uuid;purchase_qty numeric;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if p_qty is null or p_qty<=0 then raise exception 'Valid linked quantity required'; end if;
 select * into r from purchase_requirements where id=p_requirement for update;
 if not found then raise exception 'Requirement not found'; end if;
 if r.status not in('approved','purchasing','partially_purchased') then raise exception 'Requirement is not open for purchase fulfilment'; end if;
 if r.request_type='new_item' then select created_item_id into link_item from purchase_requirement_new_items where requirement_id=r.id;if link_item is null then raise exception 'Create/link the catalog item before fulfilling a new-item requirement'; end if;else link_item:=r.existing_item_id;end if;
 if not exists(select 1 from purchase_headers where id=p_purchase) then raise exception 'Purchase not found'; end if;
 if exists(select 1 from audit_log where entity_type='purchase' and entity_id=p_purchase::text and action='PURCHASE_REVERSED') then raise exception 'Reversed Purchase cannot fulfil a requirement'; end if;
 select coalesce(sum(qty),0) into purchase_qty from purchase_lines where purchase_id=p_purchase and item_id=link_item;
 if purchase_qty<=0 then raise exception 'Selected purchase does not contain the requirement item'; end if;
 select coalesce(sum(linked_qty),0) into already from purchase_requirement_links where purchase_id=p_purchase and item_id=link_item and reversed_at is null;
 if already+p_qty>purchase_qty then raise exception 'Linked quantity exceeds purchased quantity for this item'; end if;
 approved:=coalesce(r.approved_qty,r.requested_qty);remaining:=greatest(approved-r.purchased_qty,0);
 if remaining<=0 then raise exception 'Requirement is already fully purchased'; end if;
 if p_qty>remaining then raise exception 'Linked quantity exceeds remaining approved requirement'; end if;
 if exists(select 1 from purchase_requirement_links where requirement_id=r.id and purchase_id=p_purchase and reversed_at is null) then raise exception 'This purchase is already linked to the requirement'; end if;
 insert into purchase_requirement_links(requirement_id,purchase_id,linked_by,linked_qty,item_id,note) values(r.id,p_purchase,a.id,p_qty,link_item,nullif(trim(p_note),''));
 update purchase_requirements set purchased_qty=purchased_qty+p_qty,status=case when purchased_qty+p_qty>=approved then 'completed' else 'partially_purchased' end where id=r.id;
 with demand as(select id,coalesce(requested_qty,0) requested_qty,fulfilled_qty,greatest(coalesce(requested_qty,0)-fulfilled_qty,0) need from purchase_requirement_dealers where requirement_id=r.id and greatest(coalesce(requested_qty,0)-fulfilled_qty,0)>0 order by id),alloc as(select id,need,greatest(least(need,p_qty-coalesce(sum(need) over(order by id rows between unbounded preceding and 1 preceding),0)),0) give from demand) update purchase_requirement_dealers d set fulfilled_qty=d.fulfilled_qty+a2.give,stock_arrival_recorded_at=case when a2.give>0 then now() else d.stock_arrival_recorded_at end from alloc a2 where d.id=a2.id and a2.give>0;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REQUIREMENT_PURCHASE_LINKED','purchase_requirement',r.id::text,jsonb_build_object('purchase_id',p_purchase,'item_id',link_item,'linked_qty',p_qty,'previous_purchased_qty',r.purchased_qty,'new_purchased_qty',r.purchased_qty+p_qty));return r.purchased_qty+p_qty;
end;$$;
revoke all on function link_purchase_to_requirement(uuid,uuid,numeric,text) from public,anon;grant execute on function link_purchase_to_requirement(uuid,uuid,numeric,text) to authenticated;

create or replace function reverse_purchase_requirement_link(p_link uuid,p_reason text) returns void
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;l purchase_requirement_links%rowtype;r purchase_requirements%rowtype;approved numeric;dealer_undo numeric;d record;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;if nullif(trim(p_reason),'') is null then raise exception 'Reversal reason required'; end if;
 select * into l from purchase_requirement_links where id=p_link for update;if not found then raise exception 'Link not found'; end if;if l.reversed_at is not null then raise exception 'Link already reversed'; end if;select * into r from purchase_requirements where id=l.requirement_id for update;approved:=coalesce(r.approved_qty,r.requested_qty);
 -- Roll back dealer fulfilment allocation before closing the link. This keeps Dealer demand totals consistent with requirement purchased_qty.
 dealer_undo:=l.linked_qty;
 for d in select id,fulfilled_qty from purchase_requirement_dealers where requirement_id=r.id and fulfilled_qty>0 order by stock_arrival_recorded_at desc nulls last,id desc for update loop exit when dealer_undo<=0;update purchase_requirement_dealers set fulfilled_qty=greatest(fulfilled_qty-least(fulfilled_qty,dealer_undo),0),stock_arrival_recorded_at=case when greatest(fulfilled_qty-least(fulfilled_qty,dealer_undo),0)=0 then null else stock_arrival_recorded_at end where id=d.id;dealer_undo:=greatest(dealer_undo-d.fulfilled_qty,0);end loop;
 update purchase_requirement_links set reversed_at=now(),reversed_by=a.id,note=concat_ws(' | ',note,'REVERSED: '||trim(p_reason)) where id=l.id;
 update purchase_requirements set purchased_qty=greatest(purchased_qty-l.linked_qty,0),status=case when greatest(purchased_qty-l.linked_qty,0)<=0 then 'purchasing' when greatest(purchased_qty-l.linked_qty,0)>=approved then 'completed' else 'partially_purchased' end where id=r.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REQUIREMENT_LINK_REVERSED','purchase_requirement',r.id::text,jsonb_build_object('link_id',l.id,'purchase_id',l.purchase_id,'qty',l.linked_qty,'reason',trim(p_reason)));
end;$$;
revoke all on function reverse_purchase_requirement_link(uuid,text) from public,anon;grant execute on function reverse_purchase_requirement_link(uuid,text) to authenticated;
