-- TORVO V2 secure rewards ledger.
-- Positive entries add points; redeem/expire entries are negative.
create or replace function reward_available_balance(p_dealer uuid)
returns numeric language sql stable security definer set search_path=public as $$
  select greatest(coalesce(sum(case when entry_type='earn' and expires_at is not null and expires_at<=now() then 0 else points end),0),0)
  from reward_ledger where dealer_id=p_dealer
$$;
revoke all on function reward_available_balance(uuid) from public,anon;
grant execute on function reward_available_balance(uuid) to authenticated;

create or replace function earn_reward_points(p_dealer uuid,p_points numeric,p_reason text,p_expires_at timestamptz default null,p_source_type text default null,p_source_id text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v uuid;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 if p_points is null or p_points<=0 then raise exception 'Points must be greater than zero';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Reason required';end if;
 if p_expires_at is not null and p_expires_at<=now() then raise exception 'Expiry must be in the future';end if;
 if not exists(select 1 from dealers where id=p_dealer and status='approved') then raise exception 'Approved dealer required';end if;
 if (p_source_type is null)<>(p_source_id is null) then raise exception 'Source type and source id must be supplied together';end if;
 insert into reward_ledger(dealer_id,points,reason,expires_at,entry_type,source_type,source_id,created_by)
 values(p_dealer,p_points,trim(p_reason),p_expires_at,'earn',nullif(trim(p_source_type),''),nullif(trim(p_source_id),''),a.id)
 returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REWARD_POINTS_EARNED','reward_ledger',v::text,jsonb_build_object('dealer_id',p_dealer,'points',p_points,'reason',trim(p_reason),'expires_at',p_expires_at,'source_type',p_source_type,'source_id',p_source_id));
 return v;
exception when unique_violation then raise exception 'Reward source already credited';end;$$;
revoke all on function earn_reward_points(uuid,numeric,text,timestamptz,text,text) from public,anon;
grant execute on function earn_reward_points(uuid,numeric,text,timestamptz,text,text) to authenticated;

create or replace function redeem_reward_points(p_dealer uuid,p_points numeric,p_reason text)
returns uuid language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;v uuid;bal numeric;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 if p_points is null or p_points<=0 then raise exception 'Points must be greater than zero';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Reason required';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_dealer::text,0));
 select reward_available_balance(p_dealer) into bal;
 if bal<p_points then raise exception 'Insufficient reward balance';end if;
 insert into reward_ledger(dealer_id,points,reason,entry_type,created_by) values(p_dealer,-p_points,trim(p_reason),'redeem',a.id) returning id into v;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REWARD_POINTS_REDEEMED','reward_ledger',v::text,jsonb_build_object('dealer_id',p_dealer,'points',p_points,'reason',trim(p_reason),'balance_before',bal,'balance_after',bal-p_points));
 return v;end;$$;
revoke all on function redeem_reward_points(uuid,numeric,text) from public,anon;
grant execute on function redeem_reward_points(uuid,numeric,text) to authenticated;

create or replace function expire_reward_points(p_dealer uuid default null)
returns integer language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;r record;v_count integer:=0;v_remaining numeric;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 for r in select e.id,e.dealer_id,e.points,e.reason from reward_ledger e where e.entry_type='earn' and e.points>0 and e.expires_at is not null and e.expires_at<=now() and(p_dealer is null or e.dealer_id=p_dealer) and not exists(select 1 from reward_ledger x where x.dealer_id=e.dealer_id and x.entry_type='expire' and x.source_type='reward_entry' and x.source_id=e.id::text) order by e.dealer_id,e.created_at loop
   perform pg_advisory_xact_lock(hashtextextended(r.dealer_id::text,0));
   v_remaining:=least(r.points,greatest(reward_available_balance(r.dealer_id),0));
   if v_remaining>0 then
     insert into reward_ledger(dealer_id,points,reason,entry_type,source_type,source_id,created_by) values(r.dealer_id,-v_remaining,'Expired: '||r.reason,'expire','reward_entry',r.id::text,a.id);
   else
     insert into reward_ledger(dealer_id,points,reason,entry_type,source_type,source_id,created_by) values(r.dealer_id,0,'Expiry recorded: '||r.reason,'expire','reward_entry',r.id::text,a.id);
   end if;
   v_count:=v_count+1;
 end loop;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'REWARD_EXPIRY_PROCESSED','reward_ledger',coalesce(p_dealer::text,'all'),jsonb_build_object('entries_processed',v_count));
 return v_count;end;$$;
revoke all on function expire_reward_points(uuid) from public,anon;
grant execute on function expire_reward_points(uuid) to authenticated;
