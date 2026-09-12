-- TORVO V2 CENTRAL MAKER-CHECKER APPROVAL FOUNDATION
-- Owner-controlled approval rights. Accountant may prepare work; authorized checker approves/rejects.
-- Self-approval is OFF unless Owner explicitly grants CAN APPROVE OWN ENTRY.
-- This is a reusable approval engine; modules must gate final business effects through approval before release.
-- STAGING TEST REQUIRED BEFORE PRODUCTION.

create table if not exists public.approval_permissions(
 user_id uuid primary key references public.app_users(id) on delete cascade,
 can_approve_transactions boolean not null default false,
 can_approve_own_entry boolean not null default false,
 granted_by uuid not null references public.app_users(id),
 granted_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.approval_requests(
 id uuid primary key default gen_random_uuid(),
 module text not null check(module in('payment','purchase','payment_out','sales_financial','financial_correction','reversal','other')),
 entity_type text not null,
 entity_id text not null,
 action_type text not null,
 maker_id uuid not null references public.app_users(id),
 status text not null default 'pending_approval' check(status in('pending_approval','approved','rejected','cancelled')),
 amount_snapshot numeric,
 summary text not null,
 payload_snapshot jsonb not null default '{}'::jsonb,
 checker_id uuid references public.app_users(id),
 checker_note text,
 decided_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index if not exists uq_approval_active_entity_action on public.approval_requests(module,entity_type,entity_id,action_type) where status='pending_approval';
create index if not exists idx_approval_pending_created on public.approval_requests(status,created_at desc);
create index if not exists idx_approval_maker_created on public.approval_requests(maker_id,created_at desc);

create table if not exists public.approval_history(
 id bigint generated always as identity primary key,
 approval_id uuid not null references public.approval_requests(id) on delete restrict,
 action text not null check(action in('submitted','approved','rejected','cancelled','permission_changed')),
 actor_id uuid not null references public.app_users(id),
 note text,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

alter table public.approval_permissions enable row level security;
alter table public.approval_requests enable row level security;
alter table public.approval_history enable row level security;
revoke all on public.approval_permissions,public.approval_requests,public.approval_history from anon,authenticated;

create or replace function public.set_transaction_approval_permission(p_user uuid,p_can_approve boolean,p_can_approve_own boolean default false)
returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;t app_users%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role<>'owner' then raise exception 'Owner authorization required';end if;
 select * into t from app_users where id=p_user and active=true for update;
 if not found or t.role not in('accountant','admin') then raise exception 'Only active Accountant/Admin can receive approval permission';end if;
 insert into approval_permissions(user_id,can_approve_transactions,can_approve_own_entry,granted_by,granted_at,updated_at)
 values(t.id,coalesce(p_can_approve,false),case when p_can_approve then coalesce(p_can_approve_own,false) else false end,a.id,now(),now())
 on conflict(user_id) do update set can_approve_transactions=excluded.can_approve_transactions,can_approve_own_entry=excluded.can_approve_own_entry,granted_by=a.id,granted_at=now(),updated_at=now();
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'APPROVAL_PERMISSION_CHANGED','app_user',t.id::text,jsonb_build_object('can_approve_transactions',p_can_approve,'can_approve_own_entry',case when p_can_approve then p_can_approve_own else false end));
end;$$;

create or replace function public.submit_approval_request(p_module text,p_entity_type text,p_entity_id text,p_action_type text,p_summary text,p_amount numeric default null,p_payload jsonb default '{}'::jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r uuid;existing uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 if p_module not in('payment','purchase','payment_out','sales_financial','financial_correction','reversal','other') then raise exception 'Invalid approval module';end if;
 if nullif(trim(p_entity_type),'') is null or nullif(trim(p_entity_id),'') is null or nullif(trim(p_action_type),'') is null or nullif(trim(p_summary),'') is null then raise exception 'Approval details required';end if;
 select id into existing from approval_requests where module=p_module and entity_type=trim(p_entity_type) and entity_id=trim(p_entity_id) and action_type=upper(trim(p_action_type)) and status='pending_approval';
 if found then return existing;end if;
 insert into approval_requests(module,entity_type,entity_id,action_type,maker_id,amount_snapshot,summary,payload_snapshot)
 values(p_module,trim(p_entity_type),trim(p_entity_id),upper(trim(p_action_type)),a.id,p_amount,upper(trim(p_summary)),coalesce(p_payload,'{}'::jsonb)) returning id into r;
 insert into approval_history(approval_id,action,actor_id,details) values(r,'submitted',a.id,jsonb_build_object('module',p_module,'entity_type',p_entity_type,'entity_id',p_entity_id));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'APPROVAL_SUBMITTED','approval_request',r::text,jsonb_build_object('module',p_module,'source_entity_type',p_entity_type,'source_entity_id',p_entity_id,'action_type',upper(trim(p_action_type))));
 return r;
end;$$;

create or replace function public.decide_approval_request(p_approval uuid,p_decision text,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r approval_requests%rowtype;perm approval_permissions%rowtype;allowed boolean:=false;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found then raise exception 'Not authorized';end if;
 select * into r from approval_requests where id=p_approval for update;
 if not found then raise exception 'Approval request not found';end if;
 if r.status<>'pending_approval' then raise exception 'Approval request already decided';end if;
 if lower(trim(p_decision)) not in('approved','rejected') then raise exception 'Decision must be APPROVED or REJECTED';end if;
 if a.role='owner' then allowed:=true;
 elsif a.role in('admin','accountant') then
   select * into perm from approval_permissions where user_id=a.id;
   allowed:=found and perm.can_approve_transactions;
 end if;
 if not allowed then raise exception 'Approval permission required';end if;
 if r.maker_id=a.id and a.role<>'owner' and not coalesce(perm.can_approve_own_entry,false) then raise exception 'Self approval is not permitted';end if;
 update approval_requests set status=lower(trim(p_decision)),checker_id=a.id,checker_note=nullif(upper(trim(coalesce(p_note,''))),''),decided_at=now(),updated_at=now() where id=r.id;
 insert into approval_history(approval_id,action,actor_id,note) values(r.id,lower(trim(p_decision))::text,a.id,nullif(upper(trim(coalesce(p_note,''))),''));
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,case when lower(trim(p_decision))='approved' then 'APPROVAL_APPROVED' else 'APPROVAL_REJECTED' end,'approval_request',r.id::text,jsonb_build_object('module',r.module,'source_entity_type',r.entity_type,'source_entity_id',r.entity_id,'maker_id',r.maker_id));
end;$$;

create or replace function public.get_pending_approval_queue(p_limit integer default 200)
returns table(id uuid,module text,entity_type text,entity_id text,action_type text,maker_id uuid,maker_name text,amount_snapshot numeric,summary text,status text,created_at timestamptz,can_current_user_decide boolean)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;perm approval_permissions%rowtype;can_decide boolean:=false;can_own boolean:=false;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 if a.role='owner' then can_decide:=true;can_own:=true;else select * into perm from approval_permissions where user_id=a.id;can_decide:=found and perm.can_approve_transactions;can_own:=found and perm.can_approve_own_entry;end if;
 return query select r.id,r.module,r.entity_type,r.entity_id,r.action_type,r.maker_id,u.full_name,r.amount_snapshot,r.summary,r.status,r.created_at,(can_decide and(r.maker_id<>a.id or can_own)) from approval_requests r join app_users u on u.id=r.maker_id where r.status='pending_approval' order by r.created_at asc limit greatest(1,least(coalesce(p_limit,200),500));
end;$$;

create or replace function public.get_my_approval_work(p_limit integer default 200)
returns table(id uuid,module text,entity_type text,entity_id text,action_type text,status text,summary text,amount_snapshot numeric,checker_name text,checker_note text,created_at timestamptz,decided_at timestamptz)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin','accountant') then raise exception 'Not authorized';end if;
 return query select r.id,r.module,r.entity_type,r.entity_id,r.action_type,r.status,r.summary,r.amount_snapshot,c.full_name,r.checker_note,r.created_at,r.decided_at from approval_requests r left join app_users c on c.id=r.checker_id where r.maker_id=a.id order by r.created_at desc limit greatest(1,least(coalesce(p_limit,200),500));
end;$$;

revoke all on function public.set_transaction_approval_permission(uuid,boolean,boolean) from public,anon;
revoke all on function public.submit_approval_request(text,text,text,text,text,numeric,jsonb) from public,anon;
revoke all on function public.decide_approval_request(uuid,text,text) from public,anon;
revoke all on function public.get_pending_approval_queue(integer) from public,anon;
revoke all on function public.get_my_approval_work(integer) from public,anon;
grant execute on function public.set_transaction_approval_permission(uuid,boolean,boolean) to authenticated;
grant execute on function public.submit_approval_request(text,text,text,text,text,numeric,jsonb) to authenticated;
grant execute on function public.decide_approval_request(uuid,text,text) to authenticated;
grant execute on function public.get_pending_approval_queue(integer) to authenticated;
grant execute on function public.get_my_approval_work(integer) to authenticated;
