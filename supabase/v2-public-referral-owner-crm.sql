-- TORVO V2 PUBLIC REFERRAL OWNER/ADMIN CRM
-- Install after v2-public-dealer-referral-integrity.sql.
-- Private lifecycle/read layer. Never grant to anon.

alter table public.customer_dealer_referrals add column if not exists owner_note text;
alter table public.customer_dealer_referrals add column if not exists contacted_at timestamptz;
alter table public.customer_dealer_referrals add column if not exists converted_at timestamptz;
alter table public.customer_dealer_referrals add column if not exists closed_at timestamptz;
alter table public.customer_dealer_referrals add column if not exists updated_at timestamptz not null default now();

-- The base referral migration originally allowed only CREATED/DEALER_SELECTED/VERIFIED/BENEFIT states.
-- CRM lifecycle actions below need CONTACTED/CONVERTED/CLOSED as authoritative persisted states.
alter table public.customer_dealer_referrals drop constraint if exists customer_dealer_referrals_status_check;
alter table public.customer_dealer_referrals add constraint customer_dealer_referrals_status_check
 check(status in('created','dealer_selected','verified_by_dealer','benefit_given','expired','cancelled','contacted','converted','closed'));

create index if not exists customer_dealer_referrals_status_created_idx on public.customer_dealer_referrals(status,created_at desc);
create index if not exists customer_dealer_referrals_dealer_created_idx on public.customer_dealer_referrals(dealer_id,created_at desc);
create index if not exists dealer_referral_events_enquiry_event_idx on public.dealer_referral_events(enquiry_id,event_type,created_at desc);

create or replace function public.torvo_assert_referral_crm_admin()
returns void language plpgsql security definer set search_path=public as $$begin
 if not exists(select 1 from app_users u where u.auth_user_id=auth.uid() and upper(coalesce(u.role,'')) in('OWNER','ADMIN') and coalesce(u.is_active,true)=true) then raise exception 'OWNER / ADMIN ACCESS REQUIRED'; end if;
end$$;
revoke all on function public.torvo_assert_referral_crm_admin() from public;
grant execute on function public.torvo_assert_referral_crm_admin() to authenticated;

create or replace function public.admin_public_referral_crm(p_status text default null,p_search text default null,p_limit integer default 100)
returns table(referral_id uuid,referral_code text,created_at timestamptz,status text,lead_source text,customer_name text,mobile_whatsapp text,pin_code text,product_id uuid,item_code text,product_name text,dealer_id uuid,shop_name text,contacted_at timestamptz,converted_at timestamptz,closed_at timestamptz,owner_note text,enquiry_id uuid,last_activity_at timestamptz)
language plpgsql security definer set search_path=public as $$declare s text:=upper(btrim(coalesce(p_status,'')));q text:='%'||upper(btrim(coalesce(p_search,'')))||'%';begin
 perform torvo_assert_referral_crm_admin();
 if s<>'' and s not in('DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED') then raise exception 'INVALID REFERRAL STATUS'; end if;
 return query
 select r.id,r.referral_code,r.created_at,upper(r.status),upper(coalesce(r.lead_source,'WEBSITE')),c.full_name,coalesce(nullif(c.whatsapp,''),c.mobile),r.customer_pin_code,i.id,i.item_code,i.name,d.id,d.shop_name,r.contacted_at,r.converted_at,r.closed_at,r.owner_note,ev.enquiry_id,greatest(r.updated_at,coalesce(ev.last_activity_at,r.created_at))
 from customer_dealer_referrals r
 join customer_contacts c on c.id=r.customer_id
 join catalog_items i on i.id=r.product_id
 join dealers d on d.id=r.dealer_id
 left join lateral(select e.enquiry_id,max(e.created_at) as last_activity_at from dealer_referral_events e where e.dealer_id=r.dealer_id and e.product_id=r.product_id and e.event_type='REFERRAL_CREATED' and e.created_at between r.created_at-interval '1 minute' and r.created_at+interval '5 minutes' group by e.enquiry_id order by max(e.created_at) desc limit 1)ev on true
 where upper(coalesce(r.status,'')) in('DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED') and (s='' or upper(r.status)=s) and (p_search is null or btrim(p_search)='' or upper(coalesce(r.referral_code,'')) like q or upper(coalesce(c.full_name,'')) like q or coalesce(c.mobile,'') like q or upper(coalesce(i.item_code,'')) like q or upper(coalesce(i.name,'')) like q or upper(coalesce(d.shop_name,'')) like q or coalesce(r.customer_pin_code,'') like q)
 order by greatest(r.updated_at,r.created_at) desc limit greatest(1,least(coalesce(p_limit,100),500));
end$$;
revoke all on function public.admin_public_referral_crm(text,text,integer) from public;
grant execute on function public.admin_public_referral_crm(text,text,integer) to authenticated;

create or replace function public.admin_public_referral_summary()
returns table(total bigint,awaiting_followup bigint,contacted bigint,converted bigint,closed bigint,conversion_rate numeric)
language plpgsql security definer set search_path=public as $$begin
 perform torvo_assert_referral_crm_admin();
 return query select count(*)filter(where upper(status) in('DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED'))::bigint,count(*)filter(where lower(status)='dealer_selected')::bigint,count(*)filter(where lower(status)='contacted')::bigint,count(*)filter(where lower(status)='converted')::bigint,count(*)filter(where lower(status)='closed')::bigint,round(case when count(*)filter(where upper(status) in('DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED'))=0 then 0 else count(*)filter(where lower(status)='converted')::numeric*100/count(*)filter(where upper(status) in('DEALER_SELECTED','CONTACTED','CONVERTED','CLOSED')) end,2) from customer_dealer_referrals;
end$$;
revoke all on function public.admin_public_referral_summary() from public;
grant execute on function public.admin_public_referral_summary() to authenticated;

create or replace function public.admin_update_public_referral(p_referral_id uuid,p_action text,p_note text default null)
returns table(referral_id uuid,status text,contacted_at timestamptz,converted_at timestamptz,closed_at timestamptz)
language plpgsql security definer set search_path=public as $$declare a text:=upper(btrim(coalesce(p_action,'')));r customer_dealer_referrals%rowtype;n text:=nullif(btrim(coalesce(p_note,'')),'');qid uuid;begin
 perform torvo_assert_referral_crm_admin();
 if p_referral_id is null then raise exception 'REFERRAL ID REQUIRED'; end if;
 if a not in('MARK_CONTACTED','MARK_CONVERTED','CLOSE','REOPEN') then raise exception 'INVALID REFERRAL ACTION'; end if;
 if length(coalesce(n,''))>1000 then raise exception 'OWNER / ADMIN NOTE MUST BE 1000 CHARACTERS OR LESS'; end if;
 if n is not null then n:=upper(n); end if;
 select * into r from customer_dealer_referrals where id=p_referral_id for update;if not found then raise exception 'REFERRAL NOT FOUND'; end if;
 if r.dealer_id is null or r.product_id is null then raise exception 'REFERRAL DEALER / PRODUCT LINK REQUIRED'; end if;
 if r.expires_at<=now() and a not in('CLOSE') then raise exception 'EXPIRED REFERRAL CANNOT BE ADVANCED OR REOPENED'; end if;
 if not exists(select 1 from dealers d where d.id=r.dealer_id and lower(coalesce(d.status,''))='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null and d.product_sales_available=true) and a not in('CLOSE') then raise exception 'ASSIGNED DEALER IS NO LONGER AVAILABLE FOR REFERRALS'; end if;
 if not exists(select 1 from catalog_items i where i.id=r.product_id and coalesce(i.active,true)=true) and a not in('CLOSE') then raise exception 'REFERRAL PRODUCT IS NO LONGER ACTIVE'; end if;
 select e.enquiry_id into qid from dealer_referral_events e where e.dealer_id=r.dealer_id and e.product_id=r.product_id and e.event_type='REFERRAL_CREATED' and e.created_at between r.created_at-interval '1 minute' and r.created_at+interval '5 minutes' order by e.created_at desc limit 1;
 if a='MARK_CONTACTED' then
  if lower(coalesce(r.status,''))<>'dealer_selected' then raise exception 'ONLY DEALER SELECTED REFERRAL CAN BE MARKED CONTACTED'; end if;
  update customer_dealer_referrals set status='contacted',contacted_at=coalesce(contacted_at,now()),owner_note=coalesce(n,owner_note),updated_at=now() where id=p_referral_id;
 elsif a='MARK_CONVERTED' then
  if lower(coalesce(r.status,'')) not in('dealer_selected','contacted') then raise exception 'ONLY ACTIVE REFERRAL CAN BE MARKED CONVERTED'; end if;
  update customer_dealer_referrals set status='converted',contacted_at=coalesce(contacted_at,now()),converted_at=coalesce(converted_at,now()),closed_at=coalesce(closed_at,now()),owner_note=coalesce(n,owner_note),updated_at=now() where id=p_referral_id;
  if qid is not null then update customer_product_enquiries set status='FULFILLED',updated_at=now() where id=qid and status<>'CLOSED'; end if;
  if qid is not null and not exists(select 1 from dealer_referral_events e where e.enquiry_id=qid and e.dealer_id=r.dealer_id and e.product_id=r.product_id and e.event_type='CONFIRMED_CONVERSION') then insert into dealer_referral_events(enquiry_id,dealer_id,event_type,product_id)values(qid,r.dealer_id,'CONFIRMED_CONVERSION',r.product_id);end if;
 elsif a='CLOSE' then
  if lower(coalesce(r.status,'')) not in('dealer_selected','contacted') then raise exception 'ONLY ACTIVE REFERRAL CAN BE CLOSED'; end if;
  update customer_dealer_referrals set status='closed',closed_at=coalesce(closed_at,now()),owner_note=coalesce(n,owner_note),updated_at=now() where id=p_referral_id;
  if qid is not null then update customer_product_enquiries set status='CLOSED',updated_at=now() where id=qid; end if;
 else
  if lower(coalesce(r.status,'')) not in('closed','converted') then raise exception 'ONLY CLOSED OR CONVERTED REFERRAL CAN BE REOPENED'; end if;
  update customer_dealer_referrals set status='dealer_selected',contacted_at=null,closed_at=null,converted_at=null,owner_note=coalesce(n,owner_note),updated_at=now() where id=p_referral_id;
  if qid is not null then update customer_product_enquiries set status='DEALER_REFERRED',updated_at=now() where id=qid; end if;
 end if;
 return query select x.id,upper(x.status),x.contacted_at,x.converted_at,x.closed_at from customer_dealer_referrals x where x.id=p_referral_id;
end$$;
revoke all on function public.admin_update_public_referral(uuid,text,text) from public;
grant execute on function public.admin_update_public_referral(uuid,text,text) to authenticated;
