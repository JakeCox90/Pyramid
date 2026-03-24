-- Migration: 20260308_wallet_tables
-- Description: Wallet system — wallet_transactions table, user_wallet_balances view, RLS policies.
-- ROLLBACK: DROP VIEW IF EXISTS public.user_wallet_balances; DROP TABLE IF EXISTS public.wallet_transactions; DROP TYPE IF EXISTS public.wallet_transaction_type;

-- ─── Enum ─────────────────────────────────────────────────────────────────────

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'wallet_transaction_type'
  ) then
    create type public.wallet_transaction_type as enum (
      'top_up', 'stake', 'stake_refund', 'winnings', 'withdrawal'
    );
  end if;
end
$$;

-- ─── wallet_transactions ──────────────────────────────────────────────────────

create table if not exists public.wallet_transactions (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null references public.profiles(id) on delete cascade,
  type                      public.wallet_transaction_type not null,
  amount_pence              integer not null check (amount_pence > 0),
  balance_after_pence       integer,          -- snapshot for audit (available_to_play after this tx)
  dispute_window_expires_at timestamptz,      -- non-null for type = 'winnings'
  reference_id              uuid,             -- FK to league_id, pick_id, or payout_id (contextual)
  created_at                timestamptz not null default now(),
  notes                     text,             -- human-readable for support

  -- Idempotency key prevents double-crediting winnings or double-processing top-ups.
  -- Format: '<type>:<reference_id>' e.g. 'winnings:league-uuid:round-uuid'
  idempotency_key           text unique
);

comment on table public.wallet_transactions is
  'Immutable ledger of all wallet movements. Every credit or debit writes a row here. '
  'Direction is implied by type: top_up/stake_refund/winnings credit the user; '
  'stake/withdrawal debit the user.';

create index if not exists wallet_transactions_user_idx  on public.wallet_transactions(user_id);
create index if not exists wallet_transactions_type_idx  on public.wallet_transactions(type);
create index if not exists wallet_transactions_dispute_idx on public.wallet_transactions(dispute_window_expires_at)
  where dispute_window_expires_at is not null;

alter table public.wallet_transactions enable row level security;

-- Users can read their own transactions only.
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

-- Only service-role Edge Functions write transactions (no client inserts).

-- ─── user_wallet_balances view ────────────────────────────────────────────────
-- available_to_play: credits (top_up + stake_refund + winnings) minus debits (stake + withdrawal)
--   This includes winnings that are still within the dispute window — they are available to
--   re-stake into new leagues even before the window expires (rules §6.1).
-- withdrawable: winnings whose dispute_window_expires_at <= now, plus top_up funds minus stakes.
--   Specifically: top_up + stake_refund credits + winnings past dispute window, minus stake + withdrawal debits.

create or replace view public.user_wallet_balances as
  select
    user_id,
    -- Available to play: all credits minus all debits
    coalesce(sum(
      case
        when type in ('top_up', 'stake_refund', 'winnings') then  amount_pence
        when type in ('stake', 'withdrawal')                then -amount_pence
      end
    ), 0) as available_to_play_pence,

    -- Withdrawable: only winnings past the dispute window, plus top-up/refund credits, minus debits
    coalesce(sum(
      case
        when type = 'top_up'                                                         then  amount_pence
        when type = 'stake_refund'                                                   then  amount_pence
        when type = 'winnings' and dispute_window_expires_at <= now()                then  amount_pence
        when type = 'stake'                                                          then -amount_pence
        when type = 'withdrawal'                                                     then -amount_pence
        else 0
      end
    ), 0) as withdrawable_pence,

    -- Pending: winnings still within dispute window (informational — shown as countdown in UI)
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
  'Computed wallet balances per user. Reads from wallet_transactions. '
  'pending_pence = winnings within dispute window (cannot be withdrawn, can be re-staked).';
