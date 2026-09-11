-- TORVO V2 PRIVATE SUITABLE KNOWLEDGE REWARDS
-- Dealer answers are private from other dealers. Admin verification is mandatory before points credit.

create table if not exists knowledge_challenges (
 id uuid primary key default gen_random_uuid(),
 challenge_type text not null check(challenge_type in('known_part_fitment','mystery_part_photo')),
 item_id uuid references catalog_items(id) on delete restrict,
 title text not null,
 instructions text,
 photo_urls jsonb not null default '[]'::jsonb,
 points_per_verified_answer numeric not null default 0 check(points_per_verified_answer>=0),
 reward_policy text not null default 'verified_correct' check(reward_policy in('first_correct','first_n_correct','verified_correct')),
 first_n_limit integer check(first_n_limit is null or first_n_limit>0),
 active boolean not null default true,
 starts_at timestamptz,
 ends_at timestamptz,
 created_by uuid references app_users(id) on delete restrict,
 created_at timestamptz not null default now()
);

create table if not exists knowledge_submissions (
 id uuid primary key default gen_random_uuid(),
 challenge_id uuid not null references knowledge_challenges(id) on delete restrict,
 dealer_id uuid not null references dealers(id) on delete restrict,
 suggested_part_name text,
 machine_brand text,
 machine_type text,
 machine_model text,
 notes text,
 evidence_photo_urls jsonb not null default '[]'::jsonb,
 status text not null default 'pending' check(status in('pending','verified','partly_correct','rejected','duplicate')),
 admin_note text,
 verified_by uuid references app_users(id) on delete restrict,
 verified_at timestamptz,
 approved_points numeric not null default 0 check(approved_points>=0),
 points_credited_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists idx_knowledge_submission_admin on knowledge_submissions(status,created_at desc);
create index if not exists idx_knowledge_submission_dealer on knowledge_submissions(dealer_id,created_at desc);

create table if not exists knowledge_verified_fitments (
 id uuid primary key default gen_random_uuid(),
 submission_id uuid not null unique references knowledge_submissions(id) on delete restrict,
 item_id uuid references catalog_items(id) on delete restrict,
 machine_brand text not null,
 machine_type text,
 machine_model text not null,
 confidence_count integer not null default 1 check(confidence_count>0),
 suitable_mapping_id uuid references suitable_mappings(id) on delete restrict,
 approved_by uuid not null references app_users(id) on delete restrict,
 approved_at timestamptz not null default now()
);

-- Separate source ledger preserves why points were earned; wallet can aggregate this with other TORVO reward sources.
create table if not exists knowledge_point_ledger (
 id uuid primary key default gen_random_uuid(),
 dealer_id uuid not null references dealers(id) on delete restrict,
 submission_id uuid not null unique references knowledge_submissions(id) on delete restrict,
 points numeric not null check(points>0),
 entry_type text not null default 'knowledge_reward' check(entry_type='knowledge_reward'),
 approved_by uuid not null references app_users(id) on delete restrict,
 created_at timestamptz not null default now()
);

create or replace function submit_knowledge_answer(p_challenge uuid,p_part_name text,p_brand text,p_machine_type text,p_model text,p_notes text default null) returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;c knowledge_challenges%rowtype;rid uuid;
begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true and role='dealer';
 if not found then raise exception 'Approved dealer login required'; end if;
 select * into c from knowledge_challenges where id=p_challenge and active=true and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now());
 if not found then raise exception 'Challenge unavailable'; end if;
 if nullif(trim(p_brand),'') is null or nullif(trim(p_model),'') is null then raise exception 'Machine brand and model required'; end if;
 insert into knowledge_submissions(challenge_id,dealer_id,suggested_part_name,machine_brand,machine_type,machine_model,notes)
 values(p_challenge,u.id,nullif(upper(trim(p_part_name)),''),upper(trim(p_brand)),nullif(upper(trim(p_machine_type)),''),upper(trim(p_model)),nullif(trim(p_notes),'')) returning id into rid;
 return rid;
end;$$;

create or replace function review_knowledge_answer(p_submission uuid,p_status text,p_points numeric,p_admin_note text,p_add_to_private_record boolean default false) returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;s knowledge_submissions%rowtype;c knowledge_challenges%rowtype;item uuid;map_id uuid;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Owner/Admin required'; end if;
 if p_status not in('verified','partly_correct','rejected','duplicate') then raise exception 'Invalid review status'; end if;
 if p_points<0 then raise exception 'Invalid points'; end if;
 select * into s from knowledge_submissions where id=p_submission for update;
 if not found or s.status<>'pending' then raise exception 'Pending submission required'; end if;
 select * into c from knowledge_challenges where id=s.challenge_id;
 if p_status in('rejected','duplicate') and p_points<>0 then raise exception 'Rejected/duplicate answer cannot earn points'; end if;
 if p_points>c.points_per_verified_answer then raise exception 'Points exceed challenge reward'; end if;
 update knowledge_submissions set status=p_status,admin_note=nullif(trim(p_admin_note),''),verified_by=a.id,verified_at=now(),approved_points=p_points where id=p_submission;
 if p_points>0 then insert into knowledge_point_ledger(dealer_id,submission_id,points,approved_by) values(s.dealer_id,s.id,p_points,a.id);update knowledge_submissions set points_credited_at=now() where id=s.id;end if;
 if p_add_to_private_record and p_status in('verified','partly_correct') then
   item:=c.item_id;
   if item is not null then
    insert into suitable_mappings(spare_part_id,machine_brand,machine_model,fitment_notes,visibility,created_by) values(item,s.machine_brand,s.machine_model,'VERIFIED DEALER KNOWLEDGE: '||coalesce(s.notes,''),'private',a.id) returning id into map_id;
    insert into knowledge_verified_fitments(submission_id,item_id,machine_brand,machine_type,machine_model,suitable_mapping_id,approved_by) values(s.id,item,s.machine_brand,s.machine_type,s.machine_model,map_id,a.id);
   end if;
 end if;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'KNOWLEDGE_ANSWER_REVIEWED','knowledge_submission',s.id::text,jsonb_build_object('status',p_status,'points',p_points,'private_record_added',p_add_to_private_record));
end;$$;

revoke all on function submit_knowledge_answer(uuid,text,text,text,text,text),review_knowledge_answer(uuid,text,numeric,text,boolean) from public,anon;
grant execute on function submit_knowledge_answer(uuid,text,text,text,text,text),review_knowledge_answer(uuid,text,numeric,text,boolean) to authenticated;
