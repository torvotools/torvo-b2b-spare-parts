-- Canonical TORVO staff action that exposes the latest quotation revision to the Dealer for acknowledgement.
create or replace function public.send_sales_order_for_dealer_ok(p_sales_order uuid,p_note text default null)
returns integer language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;d sales_documents%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','salesman') then raise exception 'Not authorized';end if;
 select * into d from sales_documents where id=p_sales_order and doc_type='sales_order' for update;
 if not found then raise exception 'Quotation not found';end if;
 if d.estimate_created_at is not null or d.locked_at is not null then raise exception 'Estimate-locked quotation cannot be sent';end if;
 if not exists(select 1 from sales_document_lines where document_id=d.id) then raise exception 'Quotation has no items';end if;
 update sales_documents set status='awaiting_dealer_ok' where id=d.id;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'SENT_FOR_DEALER_OK','sales_order',d.id::text,jsonb_build_object('revision_no',d.revision_no,'note',nullif(trim(p_note),'')));
 return d.revision_no;
end;$$;
revoke all on function public.send_sales_order_for_dealer_ok(uuid,text) from public,anon;
grant execute on function public.send_sales_order_for_dealer_ok(uuid,text) to authenticated;
