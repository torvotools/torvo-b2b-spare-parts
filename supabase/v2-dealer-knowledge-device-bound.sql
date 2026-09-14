-- TORVO V2 FINAL DEALER FITMENT KNOWLEDGE DEVICE BOUNDARY
-- Install after v2-dealer-pin-auth.sql and v2-knowledge-rewards.sql.

drop function if exists dealer_knowledge_challenges();
drop function if exists dealer_knowledge_history();
drop function if exists submit_knowledge_answer(uuid,text,text,text,text,text);

create or replace function dealer_knowledge_challenges(p_device_id text,p_session_token text)
returns table(id uuid,challenge_type text,item_id uuid,title text,instructions text,photo_urls jsonb,starts_at timestamptz,ends_at timestamptz,item_code text,item_name text)
language plpgsql security definer set search_path=public as $$declare d uuid;begin d:=dealer_assert_my_device_session(p_device_id,p_session_token);return query select c.id,c.challenge_type,c.item_id,c.title,c.instructions,c.photo_urls,c.starts_at,c.ends_at,i.item_code,i.name from knowledge_challenges c left join catalog_items i on i.id=c.item_id where c.active=true and(c.starts_at is null or c.starts_at<=now())and(c.ends_at is null or c.ends_at>=now()) order by c.created_at desc;end$$;

create or replace function dealer_knowledge_history(p_device_id text,p_session_token text)
returns table(id uuid,challenge_title text,challenge_type text,machine_brand text,machine_type text,machine_model text,suggested_part_name text,status text,created_at timestamptz)
language plpgsql security definer set search_path=public as $$declare d uuid;begin d:=dealer_assert_my_device_session(p_device_id,p_session_token);return query select s.id,c.title,c.challenge_type,s.machine_brand,s.machine_type,s.machine_model,s.suggested_part_name,s.status,s.created_at from knowledge_submissions s join knowledge_challenges c on c.id=s.challenge_id where s.dealer_id=d order by s.created_at desc;end$$;

create or replace function submit_knowledge_answer(p_challenge uuid,p_part_name text,p_brand text,p_machine_type text,p_model text,p_notes text,p_device_id text,p_session_token text)
returns uuid language plpgsql security definer set search_path=public as $$declare d uuid;u app_users%rowtype;c knowledge_challenges%rowtype;rid uuid;begin d:=dealer_assert_my_device_session(p_device_id,p_session_token);select * into u from app_users where auth_user_id=auth.uid() and active=true and role='dealer';select * into c from knowledge_challenges where id=p_challenge and active=true and(starts_at is null or starts_at<=now())and(ends_at is null or ends_at>=now());if not found then raise exception 'KNOWLEDGE REQUEST UNAVAILABLE';end if;if nullif(trim(p_brand),'') is null or nullif(trim(p_model),'') is null then raise exception 'MACHINE BRAND AND MODEL REQUIRED';end if;if exists(select 1 from knowledge_submissions s where s.challenge_id=p_challenge and s.dealer_id=d and upper(s.machine_brand)=upper(trim(p_brand)) and upper(s.machine_model)=upper(trim(p_model)) and s.status in('pending','verified','partly_correct')) then raise exception 'FITMENT ALREADY SUBMITTED';end if;insert into knowledge_submissions(challenge_id,dealer_id,suggested_part_name,machine_brand,machine_type,machine_model,notes)values(p_challenge,d,nullif(upper(trim(p_part_name)),''),upper(trim(p_brand)),nullif(upper(trim(p_machine_type)),''),upper(trim(p_model)),nullif(trim(p_notes),''))returning id into rid;insert into audit_log(actor_id,action,entity_type,entity_id,details)values(u.id,'DEALER_SUITABLE_SUGGESTION_SUBMITTED','knowledge_submission',rid::text,jsonb_build_object('challenge_id',p_challenge));return rid;end$$;

revoke all on function dealer_knowledge_challenges(text,text),dealer_knowledge_history(text,text),submit_knowledge_answer(uuid,text,text,text,text,text,text,text) from public,anon;
grant execute on function dealer_knowledge_challenges(text,text),dealer_knowledge_history(text,text),submit_knowledge_answer(uuid,text,text,text,text,text,text,text) to authenticated;
