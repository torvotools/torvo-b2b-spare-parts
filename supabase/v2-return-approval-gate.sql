-- TORVO V2 RETURN MAKER-CHECKER GATE
-- Install after v2-maker-checker-approval.sql and v2-sales-purchase-returns.sql.
-- ADMIN prepares a return; OWNER or explicitly-authorized checker approves/rejects.
-- STORE KEEPER / ACCOUNTANT remain read-only for returns.

create or replace function public.submit_return_for_approval(p_type text,p_source uuid,p_lines jsonb,p_reason text,p_request_key text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r uuid;existing uuid;x jsonb;i uuid;q numeric;allowed numeric;stock numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'admin' then raise exception 'Admin authorization required';end if;
 if p_type not in('sales_return','purchase_return') then raise exception 'Invalid return type';end if;
 if p_source is null or nullif(trim(p_reason),'') is null or nullif(trim(p_request_key),'') is null then raise exception 'Source, reason and request key required';end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'Return items required';end if;
 if exists(select 1 from(select e->>'item_id'i,count(*)c from jsonb_array_elements(p_lines)e group by e->>'item_id')s where i is null or c>1)then raise exception 'Duplicate/missing return item';end if;
 if p_type='sales_return' and not exists(select 1 from delivery_stock_finalizations where estimate_id=p_source)then raise exception 'Actual delivered Estimate required';end if;
 if p_type='purchase_return' then
  if not exists(select 1 from purchase_stock_receipts where purchase_id=p_source and reversed_at is null)then raise exception 'Received unreversed Purchase required';end if;
  if exists(select 1 from purchase_requirement_links where purchase_id=p_source and reversed_at is null)then raise exception 'Reverse active Purchase Requirement links before Purchase Return';end if;
 end if;
 for x in select * from jsonb_array_elements(p_lines) loop
  begin i:=(x->>'item_id')::uuid;q:=(x->>'qty')::numeric;exception when others then raise exception 'Invalid return line';end;
  if q<=0 then raise exception 'Return quantity must be positive';end if;
  if p_type='sales_return' then
   select coalesce(sum(l.qty),0)-coalesce((select sum(rl.qty) from transaction_return_lines rl join transaction_returns rr on rr.id=rl.return_id where rr.return_type='sales_return' and rr.source_id=p_source and rr.status='completed' and rl.item_id=i),0) into allowed from sales_document_lines l where l.document_id=p_source and l.item_id=i;
  else
   select coalesce(sum(l.qty),0)-coalesce((select sum(rl.qty) from transaction_return_lines rl join transaction_returns rr on rr.id=rl.return_id where rr.return_type='purchase_return' and rr.source_id=p_source and rr.status='completed' and rl.item_id=i),0) into allowed from purchase_lines l where l.purchase_id=p_source and l.item_id=i;
   select current_qty into stock from inventory where item_id=i;if coalesce(stock,0)<q then raise exception 'Insufficient current stock for Purchase Return';end if;
  end if;
  if q>coalesce(allowed,0) then raise exception 'Return quantity exceeds returnable quantity';end if;
 end loop;
 select id into existing from approval_requests where module='reversal' and entity_type=p_type and entity_id=p_source::text and action_type=upper(p_type) and status='pending_approval';if found then return existing;end if;
 insert into approval_requests(module,entity_type,entity_id,action_type,maker_id,summary,payload_snapshot)
 values('reversal',p_type,p_source::text,upper(p_type),a.id,upper(replace(p_type,'_',' '))||' · '||upper(trim(p_reason)),jsonb_build_object('return_type',p_type,'source_id',p_source,'lines',p_lines,'reason',upper(trim(p_reason)),'request_key',trim(p_request_key))) returning id into r;
 insert into approval_history(approval_id,action,actor_id,details)values(r,'submitted',a.id,jsonb_build_object('return_type',p_type,'source_id',p_source));
 insert into audit_log(actor_id,action,entity_type,entity_id,details)values(a.id,'RETURN_APPROVAL_SUBMITTED','approval_request',r::text,jsonb_build_object('return_type',p_type,'source_id',p_source));return r;
end;$$;

create or replace function public.decide_return_approval(p_approval uuid,p_decision text,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r approval_requests%rowtype;perm approval_permissions%rowtype;allowed boolean:=false;result_id uuid;t text;s uuid;l jsonb;rs text;k text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found then raise exception 'Not authorized';end if;
 select * into r from approval_requests where id=p_approval for update;if not found or r.module<>'reversal' or r.entity_type not in('sales_return','purchase_return')then raise exception 'Return approval not found';end if;if r.status<>'pending_approval'then raise exception 'Approval request already decided';end if;if lower(trim(p_decision))not in('approved','rejected')then raise exception 'Decision must be APPROVED or REJECTED';end if;
 if a.role='owner'then allowed:=true;elsif a.role in('admin','accountant')then select * into perm from approval_permissions where user_id=a.id;allowed:=found and perm.can_approve_transactions;end if;if not allowed then raise exception 'Approval permission required';end if;if r.maker_id=a.id and a.role<>'owner' and not coalesce(perm.can_approve_own_entry,false)then raise exception 'Self approval is not permitted';end if;
 if lower(trim(p_decision))='rejected'then update approval_requests set status='rejected',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now()where id=r.id;insert into approval_history(approval_id,action,actor_id,note)values(r.id,'rejected',a.id,nullif(upper(trim(coalesce(p_note,''))),''));return null;end if;
 t:=r.payload_snapshot->>'return_type';s:=(r.payload_snapshot->>'source_id')::uuid;l:=r.payload_snapshot->'lines';rs:=r.payload_snapshot->>'reason';k:=r.payload_snapshot->>'request_key';
 -- Revalidate and apply through the canonical return RPC under the checker identity.
 if t='sales_return'then result_id:=complete_sales_return(s,l,rs,k);else result_id:=complete_purchase_return(s,l,rs,k);end if;
 update approval_requests set status='approved',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now(),payload_snapshot=payload_snapshot||jsonb_build_object('return_id',result_id,'effect_applied_at',now()) where id=r.id;
 insert into approval_history(approval_id,action,actor_id,note,details)values(r.id,'approved',a.id,nullif(upper(trim(coalesce(p_note,''))),''),jsonb_build_object('return_id',result_id));insert into audit_log(actor_id,action,entity_type,entity_id,details)values(a.id,'RETURN_APPROVAL_APPLIED','approval_request',r.id::text,jsonb_build_object('return_id',result_id,'return_type',t,'source_id',s));return result_id;
end;$$;
revoke all on function public.submit_return_for_approval(text,uuid,jsonb,text,text),public.decide_return_approval(uuid,text,text) from public,anon;grant execute on function public.submit_return_for_approval(text,uuid,jsonb,text,text),public.decide_return_approval(uuid,text,text) to authenticated;
