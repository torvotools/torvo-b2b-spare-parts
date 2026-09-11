-- TORVO V2 reward lot accounting migration.
-- Run after v2-extended-schema.sql and before v2-rewards-rpcs.sql.
-- The ledger remains append-only for audit. Spendable balance lives in reward_point_lots.

create table if not exists reward_point_lots(
  id uuid primary key default gen_random_uuid(),
  dealer_id uuid not null references dealers(id),
  earn_entry_id uuid not null unique references reward_ledger(id),
  original_points numeric not null check(original_points>0),
  remaining_points numeric not null check(remaining_points>=0 and remaining_points<=original_points),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  expired_at timestamptz
);

create index if not exists idx_reward_lots_fifo
  on reward_point_lots(dealer_id,expires_at,created_at)
  where remaining_points>0;

create table if not exists reward_redemption_allocations(
  id bigint generated always as identity primary key,
  redemption_entry_id uuid not null references reward_ledger(id),
  lot_id uuid not null references reward_point_lots(id),
  points numeric not null check(points>0),
  created_at timestamptz not null default now(),
  unique(redemption_entry_id,lot_id)
);

-- Safe backfill is intentionally conservative: only dealers whose historical ledger
-- contains earn entries and no redeem/expire entries can be reconstructed exactly.
insert into reward_point_lots(dealer_id,earn_entry_id,original_points,remaining_points,expires_at,created_at,expired_at)
select e.dealer_id,e.id,e.points,
       case when e.expires_at is not null and e.expires_at<=now() then 0 else e.points end,
       e.expires_at,e.created_at,
       case when e.expires_at is not null and e.expires_at<=now() then e.expires_at else null end
from reward_ledger e
where e.entry_type='earn' and e.points>0
  and not exists(select 1 from reward_ledger h where h.dealer_id=e.dealer_id and h.entry_type in('redeem','expire'))
on conflict(earn_entry_id) do nothing;

alter table reward_point_lots enable row level security;
alter table reward_redemption_allocations enable row level security;

-- No direct client writes. SECURITY DEFINER RPCs own all mutations.
revoke all on reward_point_lots from anon,authenticated;
revoke all on reward_redemption_allocations from anon,authenticated;
