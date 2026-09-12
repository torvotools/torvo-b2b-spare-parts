-- TORVO V2 RETURN APPROVAL CHECKER FIX
-- Install after v2-return-approval-gate.sql.
-- Problem fixed: an authorized ACCOUNTANT checker could pass the approval gate but fail
-- when the old gate called OWNER/ADMIN-only public completion RPCs under checker identity.
-- This patch keeps public direct completion rules unchanged and applies approved returns
-- inside one locked SECURITY DEFINER approval transaction after full revalidation.

create or replace function public.decide_return_approval(p_approval uuid,p_decision text,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 a app_users%rowtype;r approval_requests%rowtype;perm approval_permissions%rowtype;allowed boolean:=false;
 result_id uuid;t text;s uuid;l jsonb;rs text;k text;x jsonb;i uuid;q numeric;original_qty numeric;returned_qty numeric;stock numeric;old transaction_returns%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found then raise exception 'Not authorized';end if;
 select * into r from approval_requests where id=p_approval for update;
 if not found or r.module<>'reversal' or r.entity_type not in('sales_return','purchase_return') then raise exception 'Return approval not found';end if;
 if r.status<>'pending_approval' then raise exception 'Approval request already decided';end if;
 if lower(trim(p_decision)) not in('approved','rejected') then raise exception 'Decision must be APPROVED or REJECTED';end if;
 if a.role='owner' then allowed:=true;
 elsif a.role in('admin','accountant') then select * into perm from approval_permissions where user_id=a.id;allowed:=found and perm.can_approve_transactions;end if;
 if not allowed then raise exception 'Approval permission required';end if;
 if r.maker_id=a.id and a.role<>'owner' and not coalesce(perm.can_approve_own_entry,false) then raise exception 'Self approval is not permitted';end if;
 if lower(trim(p_decision))='rejected' then
  update approval_requests set status='rejected',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now() where id=r.id;
  insert into approval_history(approval_id,action,actor_id,note) values(r.id,'rejected',a.id,nullif(upper(trim(coalesce(p_note,''))),''));
  insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'RETURN_APPROVAL_REJECTED','approval_request',r.id::text,jsonb_build_object('entity_type',r.entity_type));
  return null;
 end if;
 t:=r.payload_snapshot->>'return_type';s:=(r.payload_snapshot->>'source_id')::uuid;l:=r.payload_snapshot->'lines';rs:=r.payload_snapshot->>'reason';k:=r.payload_snapshot->>'request_key';
 if t<>r.entity_type or s::text<>r.entity_id then raise exception 'Approval snapshot mismatch';end if;
 if nullif(trim(rs),'') is null or nullif(trim(k),'') is null or jsonb_typeof(l)<>'array' or jsonb_array_length(l)=0 then raise exception 'Invalid approval snapshot';end if;
 if exists(select 1 from(select e->>'item_id' i,count(*) c from jsonb_array_elements(l)e group by e->>'item_id')z where i is null or c>1) then raise exception 'Duplicate/missing return item';end if;
 select * into old from transaction_returns where request_key=trim(k);
 if found then
  if old.return_type=t and old.source_id=s and old.status='completed' then result_id:=old.id;else raise exception 'Return request key already used';end if;
 else
  if t='sales_return' then
   if not exists(select 1 from delivery_stock_finalizations where estimate_id=s) then raise exception 'Actual delivered Estimate required';end if;
  else
   if not exists(select 1 from purchase_stock_receipts where purchase_id=s and reversed_at is null) then raise exception 'Received unreversed Purchase required';end if;
   if exists(select 1 from purchase_requirement_links where purchase_id=s and reversed_at is null) then raise exception 'Reverse active Purchase Requirement links before Purchase Return';end if;
  end if;
  insert into transaction_returns(return_type,source_id,status,reason,request_key,created_by,completed_by,completed_at,details)
  values(t,s,'completed',upper(trim(rs)),trim(k),r.maker_id,a.id,now(),jsonb_build_object('approval_id',r.id,'approved_by',a.id)) returning id into result_id;
  for x in select * from jsonb_array_elements(l) loop
   begin i:=(x->>'item_id')::uuid;q:=(x->>'qty')::numeric;exception when others then raise exception 'Invalid return line';end;
   if q<=0 then raise exception 'Return quantity must be positive';end if;
   if t='sales_return' then
    select coalesce(sum(qty),0) into original_qty from sales_document_lines where document_id=s and item_id=i;
    select coalesce(sum(rl.qty),0) into returned_qty from transaction_return_lines rl join transaction_returns rr on rr.id=rl.return_id where rr.return_type=t and rr.source_id=s and rr.status='completed' and rr.id<>result_id and rl.item_id=i;
    if returned_qty+q>original_qty then raise exception 'Sales return quantity exceeds delivered quantity';end if;
    insert into transaction_return_lines(return_id,item_id,qty) values(result_id,i,q);
    insert into inventory(item_id,current_qty,updated_at) values(i,q,now()) on conflict(item_id) do update set current_qty=inventory.current_qty+excluded.current_qty,updated_at=now();
    insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by) values(i,q,'SALES RETURN','sales_return',result_id,a.id);
   else
    select coalesce(sum(qty),0) into original_qty from purchase_lines where purchase_id=s and item_id=i;
    select coalesce(sum(rl.qty),0) into returned_qty from transaction_return_lines rl join transaction_returns rr on rr.id=rl.return_id where rr.return_type=t and rr.source_id=s and rr.status='completed' and rr.id<>result_id and rl.item_id=i;
    select current_qty into stock from inventory where item_id=i for update;
    if returned_qty+q>original_qty then raise exception 'Purchase return quantity exceeds received quantity';end if;
    if stock is null or stock<q then raise exception 'Insufficient current stock for Purchase Return';end if;
    insert into transaction_return_lines(return_id,item_id,qty) values(result_id,i,q);
    update inventory set current_qty=current_qty-q,updated_at=now() where item_id=i;
    insert into inventory_movements(item_id,qty_change,reason,reference_type,reference_id,created_by) values(i,-q,'PURCHASE RETURN','purchase_return',result_id,a.id);
   end if;
  end loop;
 end if;
 update approval_requests set status='approved',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now(),payload_snapshot=payload_snapshot||jsonb_build_object('return_id',result_id,'effect_applied_at',now()) where id=r.id;
 insert into approval_history(approval_id,action,actor_id,note,details) values(r.id,'approved',a.id,nullif(upper(trim(coalesce(p_note,''))),''),jsonb_build_object('return_id',result_id));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'RETURN_APPROVAL_APPLIED','approval_request',r.id::text,jsonb_build_object('return_id',result_id,'return_type',t,'source_id',s));
 return result_id;
end;$$;
revoke all on function public.decide_return_approval(uuid,text,text) from public,anon;
grant execute on function public.decide_return_approval(uuid,text,text) to authenticated;
