-- TORVO V2 SERVICE BOOK MEDIA PATH INTEGRITY
-- Job creation accepts only the authenticated Dealer's private incoming upload path.
create or replace function dealer_service_job_create(p_device_id text,p_session_token text,p_customer_name text,p_mobile text,p_whatsapp text,p_address text,p_machine_photo_url text,p_machine_brand text,p_machine_type text,p_machine_model text,p_serial_no text,p_complaint_code text,p_complaint_note text)
returns uuid language plpgsql security definer set search_path=public as $$declare did uuid;jid uuid;photo_path text;begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 photo_path:=trim(coalesce(p_machine_photo_url,''));
 if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'CUSTOMER NAME REQUIRED';end if;
 if length(photo_path)<4 then raise exception 'ORIGINAL MACHINE PHOTO REQUIRED';end if;
 if photo_path not like did::text||'/incoming/%' or photo_path like '%..%' then raise exception 'INVALID SERVICE BOOK MEDIA PATH';end if;
 if length(trim(coalesce(p_machine_brand,'')))<1 then raise exception 'MACHINE BRAND REQUIRED';end if;
 if length(trim(coalesce(p_complaint_code,'')))<2 then raise exception 'COMPLAINT REQUIRED';end if;
 insert into dealer_service_jobs(dealer_id,customer_name,mobile,whatsapp,address,machine_photo_url,machine_brand,machine_type,machine_model,serial_no,complaint_code,complaint_note)
 values(did,left(trim(p_customer_name),120),nullif(left(trim(coalesce(p_mobile,'')),20),''),nullif(left(trim(coalesce(p_whatsapp,'')),20),''),nullif(left(trim(coalesce(p_address,'')),300),''),left(photo_path,1000),left(trim(p_machine_brand),100),nullif(left(trim(coalesce(p_machine_type,'')),100),''),nullif(left(trim(coalesce(p_machine_model,'')),120),''),nullif(left(trim(coalesce(p_serial_no,'')),120),''),left(upper(trim(p_complaint_code)),100),nullif(left(trim(coalesce(p_complaint_note,'')),1000),''))
 returning id into jid;return jid;
end$$;
revoke all on function dealer_service_job_create(text,text,text,text,text,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function dealer_service_job_create(text,text,text,text,text,text,text,text,text,text,text,text,text) to authenticated;
