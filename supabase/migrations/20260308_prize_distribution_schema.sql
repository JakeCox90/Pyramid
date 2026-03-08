-- Migration: 20260308_prize_distribution_schema
-- Description: Schema additions for prize distribution and stake refund Edge Functions.
--   1. settlement_log: make fixture_id and gameweek_id nullable — prize distribution
--      settlements are not tied to a specific fixture, so requiring NOT NULL was too narrow.
--   2. settlement_log: add payload column to store serialised allocation JSON for idempotency replay.
--   3. leagues: paid_status, prize_pot_pence, platform_fee_pence, round_ended_at (if not already present via PYR-28).
--   NOTE: If migration 20260308_paid_league_columns.sql (PYR-28) has already been applied,
--         the leagues/league_members ALTER TABLE statements below will fail with "column already exists".
--         Run only the settlement_log changes in that case.
-- ROLLBACK:
--   ALTER TABLE public.settlement_log ALTER COLUMN fixture_id SET NOT NULL;
--   ALTER TABLE public.settlement_log ALTER COLUMN gameweek_id SET NOT NULL;
--   ALTER TABLE public.settlement_log DROP COLUMN IF EXISTS payload;

-- ─── settlement_log: make fixture_id / gameweek_id nullable ──────────────────
-- Prize distribution and stake refund are not fixture-scoped operations.
-- Nullable allows these functions to use the same settlement_log for idempotency.

alter table public.settlement_log
  alter column fixture_id drop not null;

alter table public.settlement_log
  alter column gameweek_id drop not null;

-- ─── settlement_log: add payload column ──────────────────────────────────────
-- Stores JSON payload for idempotency replay (e.g. prize allocations).
-- Only populated by distribute-prizes and refund-stake.

alter table public.settlement_log
  add column if not exists payload text;

comment on column public.settlement_log.payload is
  'Optional JSON payload for idempotency replay. Used by distribute-prizes and refund-stake.';

-- ─── leagues: paid league lifecycle columns (PYR-29 standalone) ──────────────
-- These are also added in 20260308_paid_league_columns.sql (PYR-28).
-- Guarded with IF NOT EXISTS via a DO block to be safe if applied independently.

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'paid_league_status'
  ) then
    create type public.paid_league_status as enum ('waiting', 'active', 'complete');
  end if;
end
$$;

alter table public.leagues
  add column if not exists paid_status           public.paid_league_status,
  add column if not exists prize_pot_pence       integer,
  add column if not exists platform_fee_pence    integer,
  add column if not exists round_ended_at        timestamptz,
  add column if not exists round_started_at      timestamptz;

-- ─── league_members: finishing position and prize columns ─────────────────────

alter table public.league_members
  add column if not exists finishing_position integer,
  add column if not exists prize_pence        integer;

comment on column public.league_members.finishing_position is
  '1st, 2nd, or 3rd place. Set by distribute-prizes Edge Function at round end.';
comment on column public.league_members.prize_pence is
  'Amount won in pence. Set by distribute-prizes Edge Function at round end.';

-- ─── wallet_transactions (if not already present via PYR-27) ─────────────────
-- distribute-prizes writes to wallet_transactions. If PYR-27 migration has not
-- been applied, create the minimum required table structure here.

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'wallet_transaction_type'
  ) then
    create type public.wallet_transaction_type as enum (
      'top_up',
      'stake',
      'stake_refund',
      'winnings',
      'withdrawal'
    );
  end if;
end
$$;

create table if not exists public.wallet_transactions (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null references public.profiles(id) on delete cascade,
  type                      public.wallet_transaction_type not null,
  amount_pence              integer not null check (amount_pence > 0),
  balance_after_pence       integer,
  dispute_window_expires_at timestamptz,
  reference_id              uuid,
  created_at                timestamptz not null default now(),
  notes                     text,
  idempotency_key           text unique
);

comment on table public.wallet_transactions is
  'Immutable ledger of all wallet movements.';

create index if not exists wallet_transactions_user_idx on public.wallet_transactions(user_id);
create index if not exists wallet_transactions_type_idx on public.wallet_transactions(type);

alter table public.wallet_transactions enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'wallet_transactions'
      and policyname = 'Users can view their own wallet transactions'
  ) then
    execute $policy$
      create policy "Users can view their own wallet transactions"
        on public.wallet_transactions for select
        using (auth.uid() = user_id)
    $policy$;
  end if;
end
$$;

-- ─── user_wallet_balances view (if not already present via PYR-27) ────────────

create or replace view public.user_wallet_balances as
  select
    user_id,
    coalesce(sum(
      case
        when type in ('top_up', 'stake_refund', 'winnings') then  amount_pence
        when type in ('stake', 'withdrawal')                then -amount_pence
      end
    ), 0) as available_to_play_pence,
    coalesce(sum(
      case
        when type = 'top_up'                                                        then  amount_pence
        when type = 'stake_refund'                                                  then  amount_pence
        when type = 'winnings' and dispute_window_expires_at <= now()               then  amount_pence
        when type = 'stake'                                                         then -amount_pence
        when type = 'withdrawal'                                                    then -amount_pence
        else 0
      end
    ), 0) as withdrawable_pence,
    coalesce(sum(
      case
        when type = 'winnings' and dispute_window_expires_at > now() then amount_pence
        else 0
      end
    ), 0) as pending_pence,
    max(created_at) as last_transaction_at
  from public.wallet_transactions
  group by user_id;

comment on view public.user_wallet_balances is
  'Computed wallet balances per user. Reads from wallet_transactions.';
