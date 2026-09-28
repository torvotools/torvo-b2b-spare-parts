-- TORVO V2 SERVICE BOOK BILL INTEGRITY
-- Delivered repair totals are server-derived from immutable part selling-rate snapshots + repair charge.
create or replace function dealer_service_job_bill_read(p_device_id text,p_session_token text,p_job_id uuid)
returns table(job_id uuid,token_no bigint,status text,parts_total numeric,repair_charge numeric,grand_total numeric,ready_at timestamptz,delivered_at timestamptz)
language plpgsql security definer set search_path=public as $$declare did uuid;begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 return query select j.id,j.token_no,j.status,coalesce(round(sum(p.qty*p.selling_rate),2),0)::numeric,j.repair_charge,
 (coalesce(round(sum(p.qty*p.selling_rate),2),0)+j.repair_charge)::numeric,j.ready_at,j.delivered_at
 from dealer_service_jobs j left join dealer_service_job_parts p on p.job_id=j.id
 where j.id=p_job_id and j.dealer_id=did group by j.id,j.token_no,j.status,j.repair_charge,j.ready_at,j.delivered_at;
 if not found then raise exception 'SERVICE JOB NOT FOUND';end if;
end$$;
revoke all on function dealer_service_job_bill_read(text,text,uuid) from public,anon;
grant execute on function dealer_service_job_bill_read(text,text,uuid) to authenticated;

create or replace function dealer_service_job_set_status(p_device_id text,p_session_token text,p_job_id uuid,p_status text,p_repair_charge numeric default 0)
returns boolean language plpgsql security definer set search_path=public as $$declare did uuid;s text:=lower(trim(coalesce(p_status,'')));current_status text;begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 if s not in('in_shop','repairing','ready','delivered','cancelled')then raise exception 'INVALID SERVICE STATUS';end if;
 if coalesce(p_repair_charge,0)<0 then raise exception 'INVALID REPAIR CHARGE';end if;
 select status into current_status from dealer_service_jobs where id=p_job_id and dealer_id=did for update;
 if current_status is null then raise exception 'SERVICE JOB NOT FOUND';end if;
 if current_status in('delivered','cancelled') and s<>current_status then raise exception 'CLOSED SERVICE JOB IS IMMUTABLE';end if;
 update dealer_service_jobs set status=s,repair_charge=coalesce(p_repair_charge,0),
 ready_at=case when s='ready' then coalesce(ready_at,now())else ready_at end,
 delivered_at=case when s='delivered' then coalesce(delivered_at,now())else delivered_at end,updated_at=now()
 where id=p_job_id and dealer_id=did;return true;
end$$;
revoke all on function dealer_service_job_set_status(text,text,uuid,text,numeric) from public,anon;
grant execute on function dealer_service_job_set_status(text,text,uuid,text,numeric) to authenticated;
