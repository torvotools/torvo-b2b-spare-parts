-- TORVO V2 secure Purchase Entry foundation.
-- Purchase is operational stock/rate/source history, not supplier accounting.
-- Requires core schema purchase_headers, purchase_lines, inventory, inventory_movements and app_users.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

create unique index if not exists uq_purchase_supplier_invoice
on purchase_headers(supplier_id,upper(trim(invoice_no))) where nullif(trim(invoice_no),'') is not null;

create or replace function create_purchase_entry(p_supplier uuid,p_invoice_no text,p_invoice_date date,p_lines jsonb,p_note text default null) returns uuid
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;h uuid;x jsonb;iid uuid;q numeric;rate numeric;total numeric:=0;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if p_supplier is null or not exists(select 1 from suppliers where id=p_supplier and active=true) then raise exception 'Active supplier required'; end if;
 if nullif(trim(p_invoice_no),'') is null then raise exception 'Invoice number required'; end if;
 if p_invoice_date is null then raise exception 'Invoice date required'; end if;
 if p_invoice_date>current_date then raise exception 'Future invoice date is not allowed'; end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'At least one purchase item required'; end if;
 if exists(select 1 from purchase_headers where supplier_id=p_supplier and upper(trim(invoice_no))=upper(trim(p_invoice_no))) then raise exception 'Duplicate supplier invoice'; end if;
 insert into purchase_headers(supplier_id,invoice_no,invoice_date,total_amount,created_by) values(p_supplier,upper(trim(p_invoice_no)),p_invoice_date,0,a.id) returning id into h;
 for x in select * from jsonb_array_elements(p_lines) loop
   begin iid:=(x->>'item_id')::uuid;q:=(x->>'qty')::numeric;rate:=(x->>'purchase_rate')::numeric; exception when others then raise exception 'Invalid purchase line'; end;
   if iid is null or q is null or q<=0 or rate is null or rate<0 then raise exception 'Invalid purchase line'; end if;
   if not exists(select 1 from catalog_items where id=iid and active=true) then raise exception 'Invalid/inactive catalog item'; end if;
   insert into purchase_lines(purchase_id,item_id,qty,purchase_rate,line_amount) values(h,iid,q,rate,q*rate);
   total:=total+(q*rate);
   insert into inventory(item_id,qty,updated_at) values(iid,q,now()) on conflict(item_id) do update set qty=inventory.qty+excluded.qty,updated_at=now();
   insert into inventory_movements(item_id,movement_type,qty,reference_type,reference_id,note,created_by) values(iid,'purchase',q,'purchase',h,concat('PURCHASE ',upper(trim(p_invoice_no))),a.id);
 end loop;
 update purchase_headers set total_amount=total where id=h;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_CREATED','purchase',h::text,jsonb_build_object('supplier_id',p_supplier,'invoice_no',upper(trim(p_invoice_no)),'invoice_date',p_invoice_date,'total_amount',total,'note',nullif(trim(p_note),'')));
 return h;
exception when unique_violation then raise exception 'Duplicate supplier invoice';end;$$;
revoke all on function create_purchase_entry(uuid,text,date,jsonb,text) from public,anon;grant execute on function create_purchase_entry(uuid,text,date,jsonb,text) to authenticated;

create or replace function reverse_purchase_entry(p_purchase uuid,p_reason text) returns void
language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;h purchase_headers%rowtype;l record;current_qty numeric;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Reversal reason required'; end if;
 select * into h from purchase_headers where id=p_purchase for update;if not found then raise exception 'Purchase not found'; end if;
 if exists(select 1 from audit_log where entity_type='purchase' and entity_id=p_purchase::text and action='PURCHASE_REVERSED') then raise exception 'Purchase already reversed'; end if;
 for l in select item_id,sum(qty) qty from purchase_lines where purchase_id=p_purchase group by item_id loop select qty into current_qty from inventory where item_id=l.item_id for update;if coalesce(current_qty,0)<l.qty then raise exception 'Cannot reverse: current stock is lower than this Purchase quantity'; end if;end loop;
 for l in select item_id,sum(qty) qty from purchase_lines where purchase_id=p_purchase group by item_id loop update inventory set qty=qty-l.qty,updated_at=now() where item_id=l.item_id;insert into inventory_movements(item_id,movement_type,qty,reference_type,reference_id,note,created_by) values(l.item_id,'purchase_reversal',-l.qty,'purchase',p_purchase,'PURCHASE REVERSAL: '||trim(p_reason),a.id);end loop;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PURCHASE_REVERSED','purchase',p_purchase::text,jsonb_build_object('reason',trim(p_reason),'invoice_no',h.invoice_no));
end;$$;
revoke all on function reverse_purchase_entry(uuid,text) from public,anon;grant execute on function reverse_purchase_entry(uuid,text) to authenticated;

-- Owner-only actual invoice-rate history. This reads immutable Purchase lines and never exposes purchase rates to Dealer/Store/Salesman.
create or replace function get_item_purchase_rate_history(p_item uuid,p_limit integer default 20) returns table(purchase_id uuid,invoice_no text,invoice_date date,supplier_name text,qty numeric,purchase_rate numeric,line_amount numeric,created_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner authorization required'; end if;
 if p_item is null then raise exception 'Item required'; end if;
 return query select h.id,h.invoice_no,h.invoice_date,s.name,l.qty,l.purchase_rate,l.line_amount,h.created_at from purchase_lines l join purchase_headers h on h.id=l.purchase_id left join suppliers s on s.id=h.supplier_id where l.item_id=p_item and not exists(select 1 from audit_log al where al.entity_type='purchase' and al.entity_id=h.id::text and al.action='PURCHASE_REVERSED') order by h.invoice_date desc,h.created_at desc limit greatest(1,least(coalesce(p_limit,20),100));
end;$$;
revoke all on function get_item_purchase_rate_history(uuid,integer) from public,anon;grant execute on function get_item_purchase_rate_history(uuid,integer) to authenticated;
