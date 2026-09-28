-- TORVO V2 SERVICE BOOK COMPLAINT MASTER
-- Structured, extensible repair complaint choices. Existing job complaint_code snapshots remain unchanged.
create table if not exists dealer_service_complaints(
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 label text not null,
 sort_order integer not null default 100 check(sort_order>=0),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(code=upper(trim(code)) and length(trim(code)) between 2 and 100),
 check(length(trim(label)) between 2 and 120)
);
alter table dealer_service_complaints enable row level security;
revoke all on dealer_service_complaints from public,anon,authenticated;

insert into dealer_service_complaints(code,label,sort_order) values
('NOT STARTING','NOT STARTING',10),('LOW POWER','LOW POWER',20),('NOISY / VIBRATION','NOISY / VIBRATION',30),
('HEATING','HEATING',40),('SPARKING','SPARKING',50),('SWITCH PROBLEM','SWITCH PROBLEM',60),
('BEARING / GEAR NOISE','BEARING / GEAR NOISE',70),('CHUCK / HOLDER PROBLEM','CHUCK / HOLDER PROBLEM',80),
('CABLE / POWER PROBLEM','CABLE / POWER PROBLEM',90),('OTHER','OTHER',100)
on conflict(code) do nothing;

create or replace function dealer_service_complaints_read(p_device_id text,p_session_token text)
returns table(code text,label text,sort_order integer)
language plpgsql security definer set search_path=public as $$begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 perform dealer_assert_my_device_session(p_device_id,p_session_token);
 return query select c.code,c.label,c.sort_order from dealer_service_complaints c where c.active=true order by c.sort_order,c.label;
end$$;
revoke all on function dealer_service_complaints_read(text,text) from public,anon;
grant execute on function dealer_service_complaints_read(text,text) to authenticated;


-- Owner/Admin management stays behind authenticated RPCs; Dealers retain read-only device-bound access.
create or replace function admin_service_complaints_read()
returns setof dealer_service_complaints language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if a.id is null or lower(coalesce(a.role,'')) not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 return query select * from dealer_service_complaints order by sort_order,label;
end$$;
revoke all on function admin_service_complaints_read() from public,anon;grant execute on function admin_service_complaints_read() to authenticated;

create or replace function admin_service_complaint_upsert(p_id uuid,p_code text,p_label text,p_sort_order integer,p_active boolean,p_reason text)
returns uuid language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;rid uuid;v_code text:=upper(btrim(coalesce(p_code,'')));v_label text:=upper(btrim(coalesce(p_label,'')));begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;if a.id is null or lower(coalesce(a.role,'')) not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 if v_code!~'^[A-Z0-9][A-Z0-9 /&+()._-]{1,59}$' then raise exception 'VALID COMPLAINT CODE REQUIRED';end if;if length(v_label)<2 or length(v_label)>120 then raise exception 'VALID COMPLAINT LABEL REQUIRED';end if;if coalesce(p_sort_order,-1)<0 then raise exception 'VALID SORT ORDER REQUIRED';end if;if nullif(btrim(p_reason),'') is null then raise exception 'CHANGE REASON REQUIRED';end if;
 if p_id is null then insert into dealer_service_complaints(code,label,sort_order,active) values(v_code,v_label,p_sort_order,coalesce(p_active,true)) returning id into rid;else update dealer_service_complaints set code=v_code,label=v_label,sort_order=p_sort_order,active=coalesce(p_active,true),updated_at=now() where id=p_id returning id into rid;if rid is null then raise exception 'COMPLAINT NOT FOUND';end if;end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'SERVICE_COMPLAINT_UPSERTED','dealer_service_complaint',rid::text,jsonb_build_object('code',v_code,'label',v_label,'sort_order',p_sort_order,'active',coalesce(p_active,true),'reason',upper(btrim(p_reason))));return rid;
end$$;
revoke all on function admin_service_complaint_upsert(uuid,text,text,integer,boolean,text) from public,anon;grant execute on function admin_service_complaint_upsert(uuid,text,text,integer,boolean,text) to authenticated;
