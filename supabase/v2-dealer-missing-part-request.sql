-- TORVO V2 secure authenticated Dealer identity, Missing Spare Part creation and dealer-scoped history.
-- Requires a real Supabase authenticated Dealer identity linked through app_users.
-- Duplicate approved dealer mobile links are rejected instead of guessed.
-- Photo upload is intentionally rejected until private storage is connected.

create or replace function public.dealer_my_profile()
returns table(id uuid,dealer_code text,shop_name text,contact_person text,mobile text,whatsapp text,status text,rate_group text)
language plpgsql security definer set search_path=public as $$
declare v_user app_users%rowtype;v_mobile text;v_count integer;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION REQUIRED';end if;
 select * into v_user from app_users where auth_user_id=auth.uid() and active=true limit 1;
 if not found or lower(coalesce(v_user.role,''))<>'dealer' then raise exception 'ACTIVE DEALER LOGIN REQUIRED';end if;
 v_mobile:=right(regexp_replace(coalesce(v_user.mobile,''),'\D','','g'),10);if length(v_mobile)<>10 then raise exception 'DEALER MOBILE LINK REQUIRED';end if;
 select count(*) into v_count from dealers d where right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10)=v_mobile and lower(coalesce(d.status,''))='approved';
 if v_count=0 then raise exception 'APPROVED DEALER LINK REQUIRED';end if;if v_count>1 then raise exception 'DEALER LINK AMBIGUOUS';end if;
 return query select d.id,d.dealer_code,d.shop_name,d.contact_person,d.mobile,d.whatsapp,d.status,d.rate_group from dealers d where right(regexp_replace(coalesce(d.mobile,''),'\D','','g'),10)=v_mobile and lower(coalesce(d.status,''))='approved' limit 1;
end;$$;

create or replace function public.dealer_create_missing_part_request(p_machine_brand text default null,p_machine_model text default null,p_part_name text default null,p_requested_qty numeric default null,p_dealer_message text default null,p_photo_url text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_dealer record;v_id uuid;v_brand text:=nullif(upper(btrim(coalesce(p_machine_brand,''))),'');v_model text:=nullif(upper(btrim(coalesce(p_machine_model,''))),'');v_part text:=nullif(upper(btrim(coalesce(p_part_name,''))),'');v_message text:=nullif(btrim(coalesce(p_dealer_message,'')),'');v_photo text:=nullif(btrim(coalesce(p_photo_url,'')),'');
begin
 select * into v_dealer from public.dealer_my_profile();if not found then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 if v_part is null and v_message is null then raise exception 'PART NAME OR REQUIREMENT DESCRIPTION REQUIRED';end if;
 if length(coalesce(v_brand,''))>80 then raise exception 'MACHINE BRAND IS TOO LONG';end if;if length(coalesce(v_model,''))>120 then raise exception 'MACHINE MODEL IS TOO LONG';end if;if length(coalesce(v_part,''))>160 then raise exception 'PART NAME IS TOO LONG';end if;if length(coalesce(v_message,''))>1000 then raise exception 'REQUIREMENT DESCRIPTION IS TOO LONG';end if;
 if p_requested_qty is not null and (p_requested_qty<1 or p_requested_qty>9999 or trunc(p_requested_qty)<>p_requested_qty) then raise exception 'QUANTITY MUST BE A WHOLE NUMBER BETWEEN 1 AND 9999';end if;
 if v_photo is not null then raise exception 'SECURE PHOTO UPLOAD IS NOT CONNECTED YET';end if;
 insert into missing_part_requests(dealer_id,photo_url,machine_brand,machine_model,part_name,requested_qty,dealer_message,status) values(v_dealer.id,'',v_brand,v_model,v_part,p_requested_qty,v_message,'new') returning id into v_id;return v_id;
end;$$;

create or replace function public.dealer_my_missing_part_requests()
returns table(id uuid,machine_brand text,machine_model text,part_name text,requested_qty numeric,dealer_message text,status text,reply_text text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare v_dealer record;
begin
 select * into v_dealer from public.dealer_my_profile();if not found then raise exception 'APPROVED DEALER LINK REQUIRED';end if;
 return query select r.id,r.machine_brand,r.machine_model,r.part_name,r.requested_qty,r.dealer_message,r.status,r.reply_text,r.created_at from missing_part_requests r where r.dealer_id=v_dealer.id order by r.created_at desc limit 20;
end;$$;

revoke all on function public.dealer_my_profile() from public,anon;
grant execute on function public.dealer_my_profile() to authenticated;
revoke all on function public.dealer_create_missing_part_request(text,text,text,numeric,text,text) from public,anon;
grant execute on function public.dealer_create_missing_part_request(text,text,text,numeric,text,text) to authenticated;
revoke all on function public.dealer_my_missing_part_requests() from public,anon;
grant execute on function public.dealer_my_missing_part_requests() to authenticated;
