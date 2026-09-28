-- TORVO V2 DEALER SERVICE BOOK PRIVATE SEARCH
-- Dealer-only lookup for daily repair history. Identity is derived from the authenticated device session.
create or replace function dealer_service_jobs_search(
 p_device_id text,p_session_token text,p_query text,p_limit integer default 100
) returns table(id uuid,token_no bigint,customer_name text,mobile text,whatsapp text,address text,machine_photo_url text,machine_brand text,machine_type text,machine_model text,serial_no text,complaint_code text,complaint_note text,status text,repair_charge numeric,machine_in_at timestamptz,ready_at timestamptz,delivered_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare did uuid;q text:=trim(coalesce(p_query,''));lim integer:=least(greatest(coalesce(p_limit,100),1),300);
begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 if length(q)<1 then raise exception 'SEARCH QUERY REQUIRED';end if;
 return query
 select j.id,j.token_no,j.customer_name,j.mobile,j.whatsapp,j.address,j.machine_photo_url,j.machine_brand,j.machine_type,j.machine_model,j.serial_no,j.complaint_code,j.complaint_note,j.status,j.repair_charge,j.machine_in_at,j.ready_at,j.delivered_at
 from dealer_service_jobs j
 where j.dealer_id=did and (
   j.token_no::text=q or
   j.customer_name ilike '%'||q||'%' or
   coalesce(j.mobile,'') ilike '%'||q||'%' or
   coalesce(j.whatsapp,'') ilike '%'||q||'%' or
   j.machine_brand ilike '%'||q||'%' or
   coalesce(j.machine_type,'') ilike '%'||q||'%' or
   coalesce(j.machine_model,'') ilike '%'||q||'%' or
   coalesce(j.serial_no,'') ilike '%'||q||'%'
 )
 order by j.machine_in_at desc limit lim;
end$$;
revoke all on function dealer_service_jobs_search(text,text,text,integer) from public,anon;
grant execute on function dealer_service_jobs_search(text,text,text,integer) to authenticated;
