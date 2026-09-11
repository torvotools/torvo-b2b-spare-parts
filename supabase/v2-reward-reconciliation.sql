-- TORVO V2 guarded historical reward reconciliation.
-- Run AFTER v2-reward-lots.sql and BEFORE enabling lot-based rewards for an existing production database.
-- This file NEVER guesses FIFO allocations. Ambiguous dealers are reported and remain blocked from automatic migration.

create or replace function reward_reconciliation_status()
returns table(dealer_id uuid,dealer_code text,shop_name text,ledger_earned numeric,ledger_redeemed numeric,ledger_expired numeric,lot_original numeric,lot_remaining numeric,migration_status text)
language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 return query
 with l as(
  select r.dealer_id,
   coalesce(sum(case when r.entry_type='earn' then r.points else 0 end),0) earned,
   abs(coalesce(sum(case when r.entry_type='redeem' then r.points else 0 end),0)) redeemed,
   abs(coalesce(sum(case when r.entry_type='expire' then r.points else 0 end),0)) expired,
   count(*) filter(where r.entry_type in('redeem','expire')) historical_spend
  from reward_ledger r group by r.dealer_id
 ),p as(
  select x.dealer_id,coalesce(sum(x.original_points),0) original,coalesce(sum(x.remaining_points),0) remaining from reward_point_lots x group by x.dealer_id
 )
 select d.id,d.dealer_code,d.shop_name,coalesce(l.earned,0),coalesce(l.redeemed,0),coalesce(l.expired,0),coalesce(p.original,0),coalesce(p.remaining,0),
 case
  when coalesce(l.historical_spend,0)>0 and coalesce(p.original,0)=0 then 'RECONCILIATION_REQUIRED'
  when coalesce(l.earned,0)>0 and coalesce(p.original,0)=0 then 'BACKFILL_REQUIRED'
  when coalesce(p.original,0)>coalesce(l.earned,0) then 'LOT_EXCEEDS_LEDGER'
  else 'LOT_ACCOUNTING_READY'
 end
 from dealers d left join l on l.dealer_id=d.id left join p on p.dealer_id=d.id
 where coalesce(l.earned,0)<>0 or coalesce(p.original,0)<>0
 order by d.dealer_code nulls last,d.shop_name;
end;$$;

-- Guard used before production cutover. It raises when any dealer has historical redeem/expire
-- entries that cannot be reconstructed exactly from the current ledger alone.
create or replace function assert_reward_lot_migration_ready()
returns void language plpgsql stable security definer set search_path=public as $$
declare a app_users%rowtype;n integer;begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 select count(*) into n from reward_reconciliation_status() where migration_status<>'LOT_ACCOUNTING_READY';
 if n>0 then raise exception 'Reward lot migration blocked: % dealer(s) require reconciliation. Run reward_reconciliation_status() and reconcile before production cutover.',n;end if;
end;$$;

revoke all on function reward_reconciliation_status() from public,anon;
revoke all on function assert_reward_lot_migration_ready() from public,anon;
grant execute on function reward_reconciliation_status() to authenticated;
grant execute on function assert_reward_lot_migration_ready() to authenticated;
