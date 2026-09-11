-- TORVO V2 automatic scheme reward credit.
-- Run after v2-rewards-rpcs.sql and v2-operations-rpcs.sql.
create or replace function credit_achieved_scheme_rewards(p_dealer uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare r record;v_count integer:=0;v_expiry timestamptz;begin
  for r in
    select dsp.dealer_id,dsp.scheme_id,dsp.achieved_slab_id,s.name,ss.points,s.end_date
    from dealer_scheme_progress dsp
    join schemes s on s.id=dsp.scheme_id
    join scheme_slabs ss on ss.id=dsp.achieved_slab_id
    join scheme_dealers sd on sd.scheme_id=dsp.scheme_id and sd.dealer_id=dsp.dealer_id
    where dsp.dealer_id=p_dealer and ss.points>0 and s.status in('active','closed')
  loop
    -- Scheme points expire 90 days after scheme end by default. The source key makes retry/delivery refresh idempotent.
    v_expiry:=(r.end_date::timestamptz + interval '90 days');
    begin
      insert into reward_ledger(dealer_id,points,reason,expires_at,entry_type,source_type,source_id)
      values(r.dealer_id,r.points,'Scheme achieved: '||r.name,v_expiry,'earn','scheme_slab',r.achieved_slab_id::text);
      v_count:=v_count+1;
    exception when unique_violation then null;
    end;
  end loop;
  return v_count;
end;$$;
revoke all on function credit_achieved_scheme_rewards(uuid) from public,anon,authenticated;

create or replace function recalculate_dealer_scheme_progress(p_dealer uuid)
returns void language plpgsql security definer set search_path=public as $$
declare r record;v_progress numeric;v_slab uuid;begin
  for r in select s.id,s.start_date,s.end_date from schemes s join scheme_dealers sd on sd.scheme_id=s.id where sd.dealer_id=p_dealer and s.status in('active','closed') loop
    select coalesce(sum(e.final_payable),0) into v_progress from sales_documents e join dispatches d on d.estimate_id=e.id where e.doc_type='estimate' and e.dealer_id=p_dealer and d.status='delivered' and d.delivered_at is not null and d.delivered_at::date between r.start_date and r.end_date;
    select ss.id into v_slab from scheme_slabs ss where ss.scheme_id=r.id and v_progress>=ss.min_value and(ss.max_value is null or v_progress<=ss.max_value) order by ss.min_value desc limit 1;
    insert into dealer_scheme_progress(scheme_id,dealer_id,progress_value,achieved_slab_id) values(r.id,p_dealer,v_progress,v_slab) on conflict(scheme_id,dealer_id) do update set progress_value=excluded.progress_value,achieved_slab_id=excluded.achieved_slab_id;
    v_slab:=null;
  end loop;
  perform credit_achieved_scheme_rewards(p_dealer);
end;$$;
revoke all on function recalculate_dealer_scheme_progress(uuid) from public,anon,authenticated;
