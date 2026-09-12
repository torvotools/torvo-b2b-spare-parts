-- TORVO V2 MAKER-CHECKER PAYMENT GATE
-- Install after v2-maker-checker-approval.sql and v2-delivery-stock-integrity.sql.
-- Accountant submits payment work for approval. Owner may record directly.
-- Authorized checker approval posts the payment exactly once from the trusted server function.

alter table public.approval_requests add column if not exists effect_applied_at timestamptz;
alter table public.approval_requests add column if not exists effect_result jsonb not null default '{}'::jsonb;

create or replace function public.submit_payment_for_approval(p_estimate uuid,p_status text,p_amount numeric,p_request_key text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;e sales_documents%rowtype;r uuid;paid numeric;outstanding numeric;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('accountant','admin') then raise exception 'Accountant/Admin authorization required';end if;
 if p_status not in('cash','received','pending') then raise exception 'Invalid payment status';end if;
 if p_amount is null or p_amount<=0 then raise exception 'Payment amount must be positive';end if;
 if nullif(trim(p_request_key),'') is null then raise exception 'Payment request key required';end if;
 select * into e from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 select coalesce(sum(amount),0) into paid from payments where estimate_id=e.id and status in('cash','received');
 outstanding:=greatest(coalesce(e.final_payable,0)-paid,0);
 if p_status in('cash','received') and p_amount>outstanding then raise exception 'Payment exceeds outstanding amount';end if;
 select id into r from approval_requests where module='payment' and entity_type='estimate' and entity_id=e.id::text and action_type='RECORD PAYMENT' and status='pending_approval';
 if found then raise exception 'A payment approval is already pending for this Estimate';end if;
 insert into approval_requests(module,entity_type,entity_id,action_type,maker_id,status,amount_snapshot,summary,payload_snapshot)
 values('payment','estimate',e.id::text,'RECORD PAYMENT',a.id,'pending_approval',p_amount,'PAYMENT ENTRY REQUIRES CHECKER APPROVAL',jsonb_build_object('estimate_id',e.id,'status',p_status,'amount',p_amount,'request_key',trim(p_request_key))) returning id into r;
 insert into approval_history(approval_id,action,actor_id,details) values(r,'submitted',a.id,jsonb_build_object('status',p_status,'amount',p_amount));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PAYMENT_APPROVAL_SUBMITTED','approval_request',r::text,jsonb_build_object('estimate_id',e.id,'status',p_status,'amount',p_amount));
 return r;
end;$$;

create or replace function public.decide_payment_approval(p_approval uuid,p_decision text,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r approval_requests%rowtype;perm approval_permissions%rowtype;allowed boolean:=false;payment_id uuid;payload jsonb;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found then raise exception 'Not authorized';end if;
 select * into r from approval_requests where id=p_approval for update;
 if not found or r.module<>'payment' then raise exception 'Payment approval not found';end if;
 if r.status<>'pending_approval' then raise exception 'Approval request already decided';end if;
 if lower(trim(p_decision)) not in('approved','rejected') then raise exception 'Decision must be APPROVED or REJECTED';end if;
 if a.role='owner' then allowed:=true;elsif a.role in('admin','accountant') then select * into perm from approval_permissions where user_id=a.id;allowed:=found and perm.can_approve_transactions;end if;
 if not allowed then raise exception 'Approval permission required';end if;
 if r.maker_id=a.id and a.role<>'owner' and not coalesce(perm.can_approve_own_entry,false) then raise exception 'Self approval is not permitted';end if;
 if lower(trim(p_decision))='rejected' then
  update approval_requests set status='rejected',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now() where id=r.id;
  insert into approval_history(approval_id,action,actor_id,note) values(r.id,'rejected',a.id,nullif(upper(trim(coalesce(p_note,''))),''));
  insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PAYMENT_APPROVAL_REJECTED','approval_request',r.id::text,jsonb_build_object('maker_id',r.maker_id));return null;
 end if;
 payload:=r.payload_snapshot;
 payment_id:=public.record_payment((payload->>'estimate_id')::uuid,payload->>'status',(payload->>'amount')::numeric,payload->>'request_key');
 update approval_requests set status='approved',checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now(),effect_applied_at=now(),effect_result=jsonb_build_object('payment_id',payment_id) where id=r.id;
 insert into approval_history(approval_id,action,actor_id,note,details) values(r.id,'approved',a.id,nullif(upper(trim(coalesce(p_note,''))),''),jsonb_build_object('payment_id',payment_id));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PAYMENT_APPROVAL_APPROVED','approval_request',r.id::text,jsonb_build_object('maker_id',r.maker_id,'payment_id',payment_id));return payment_id;
end;$$;

revoke all on function public.submit_payment_for_approval(uuid,text,numeric,text) from public,anon;
revoke all on function public.decide_payment_approval(uuid,text,text) from public,anon;
grant execute on function public.submit_payment_for_approval(uuid,text,numeric,text) to authenticated;
grant execute on function public.decide_payment_approval(uuid,text,text) to authenticated;
