-- Migration: 20260327_atomic_withdrawal
-- Description: Postgres function for atomic withdrawals — prevents TOCTOU race
--              and enforces idempotency + 24h cooldown at the DB level.
-- ROLLBACK: DROP FUNCTION IF EXISTS public.atomic_withdrawal;

create or replace function public.atomic_withdrawal(
  p_user_id     uuid,
  p_amount_pence integer,
  p_idempotency_key text
)
returns table (
  transaction_id uuid,
  withdrawable_after_pence integer
)
language plpgsql
security definer
as $$
declare
  v_withdrawable integer;
  v_tx_id uuid;
  v_last_withdrawal timestamptz;
begin
  -- Advisory lock scoped to this user prevents concurrent withdrawal attempts.
  -- hashtext returns a 32-bit int from the user_id text, suitable for pg_advisory_xact_lock.
  perform pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Compute withdrawable balance from the immutable ledger.
  -- This mirrors the user_wallet_balances view logic exactly.
  select coalesce(sum(
    case
      when type in ('top_up', 'stake_refund') then amount_pence
      when type = 'winnings' and dispute_window_expires_at <= now() then amount_pence
      when type in ('stake', 'withdrawal') then -amount_pence
      else 0
    end
  ), 0)
  into v_withdrawable
  from public.wallet_transactions
  where user_id = p_user_id;

  -- Check sufficient balance
  if v_withdrawable < p_amount_pence then
    raise exception 'INSUFFICIENT_BALANCE: available=%p, requested=%p',
      v_withdrawable, p_amount_pence;
  end if;

  -- Check 24h cooldown (rules §8: max 1 withdrawal per day)
  select max(created_at)
  into v_last_withdrawal
  from public.wallet_transactions
  where user_id = p_user_id
    and type = 'withdrawal';

  if v_last_withdrawal is not null
     and v_last_withdrawal > now() - interval '24 hours' then
    raise exception 'WITHDRAWAL_RATE_LIMITED: last_withdrawal=%',
      v_last_withdrawal;
  end if;

  -- Insert the withdrawal transaction with idempotency key.
  -- If a duplicate key exists, Postgres raises 23505 (unique_violation).
  insert into public.wallet_transactions (
    user_id,
    type,
    amount_pence,
    balance_after_pence,
    idempotency_key,
    notes
  ) values (
    p_user_id,
    'withdrawal',
    p_amount_pence,
    v_withdrawable - p_amount_pence,
    p_idempotency_key,
    'Withdrawal request — Stripe payout pending (stub: PYR-25 GATE not yet resolved)'
  )
  returning id into v_tx_id;

  return query select v_tx_id, (v_withdrawable - p_amount_pence)::integer;
end;
$$;

comment on function public.atomic_withdrawal is
  'Atomically validates balance, enforces 24h cooldown, and inserts a withdrawal '
  'transaction. Uses pg_advisory_xact_lock to prevent concurrent withdrawals '
  'for the same user. Called by request-withdrawal Edge Function.';
