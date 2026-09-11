-- TORVO V2 payment retry/idempotency protection.
-- Run after v2-schema.sql and before using record_payment from clients.
alter table payments add column if not exists request_key text;
create unique index if not exists ux_payments_request_key on payments(request_key) where request_key is not null;

drop function if exists record_payment(uuid,text,numeric);
drop function if exists record_payment(uuid,text,numeric,text);
create or replace function record_payment(p_estimate uuid,p_status text,p_amount numeric,p_request_key text default null) returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;pid uuid;f numeric;paid numeric;pending numeric;d_status text;k text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 if p_status not in('cash','pending','received') or p_amount is null or p_amount<=0 then raise exception 'Payment amount must be greater than zero';end if;
 k:=nullif(trim(p_request_key),'');
 if k is not null then
  select id into pid from payments where request_key=k;
  if found then return pid;end if;
 end if;
 select final_payable into f from sales_documents where id=p_estimate and doc_type='estimate' for update;
 if not found then raise exception 'Estimate not found';end if;
 if f is null or f<=0 then raise exception 'Estimate final payable is invalid';end if;
 select status into d_status from dispatches where estimate_id=p_estimate for update;
 if d_status='delivered' then raise exception 'Cannot record payment after delivery';end if;
 select coalesce(sum(amount) filter(where status in('cash','received')),0),coalesce(sum(amount) filter(where status='pending'),0) into paid,pending from payments where estimate_id=p_estimate;
 if p_status in('cash','received') and paid+p_amount>f then raise exception 'Payment exceeds outstanding amount';end if;
 if p_status='pending' and paid+pending+p_amount>f then raise exception 'Pending payment exceeds outstanding amount';end if;
 begin
  insert into payments(estimate_id,status,amount,received_at,recorded_by,request_key) values(p_estimate,p_status,p_amount,case when p_status in('cash','received') then now() else null end,a.id,k) returning id into pid;
 exception when unique_violation then
  if k is null then raise;end if;
  select id into pid from payments where request_key=k;
  if pid is null then raise;end if;
  return pid;
 end;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'PAYMENT_RECORDED','estimate',p_estimate::text,jsonb_build_object('payment_id',pid,'status',p_status,'amount',p_amount,'final_payable',f,'received_before',paid,'pending_before',pending,'request_key',k));
 return pid;
end;$$;
revoke all on function record_payment(uuid,text,numeric,text) from public,anon;grant execute on function record_payment(uuid,text,numeric,text) to authenticated;
