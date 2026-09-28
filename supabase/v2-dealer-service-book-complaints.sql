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
