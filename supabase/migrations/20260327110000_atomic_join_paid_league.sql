-- Migration: 20260327_atomic_join_paid_league
-- Description: Postgres function for atomic paid league join — prevents joining
--              without paying by combining member insert + stake deduction in one
--              transaction with an advisory lock.
-- ROLLBACK: DROP FUNCTION IF EXISTS public.atomic_join_paid_league;

create or replace function public.atomic_join_paid_league(
  p_user_id       uuid,
  p_league_id     uuid,
  p_pseudonym     text,
  p_stake_pence   integer
)
returns table (
  member_id       uuid,
  new_player_count integer,
  balance_after   integer
)
language plpgsql
security definer
as $$
declare
  v_available    integer;
  v_member_id    uuid;
  v_player_count integer;
  v_balance_after integer;
  v_existing_id  uuid;
begin
  -- Advisory lock scoped to this user prevents concurrent join attempts
  -- from double-spending the same balance.
  perform pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Check if user is already a member (idempotent — return existing)
  select id into v_existing_id
  from public.league_members
  where league_id = p_league_id and user_id = p_user_id;

  if v_existing_id is not null then
    -- Already a member — raise a specific signal the Edge Function can handle
    raise exception 'ALREADY_MEMBER: user=%, league=%', p_user_id, p_league_id;
  end if;

  -- Compute available_to_play balance from the immutable ledger.
  -- This mirrors the user_wallet_balances view logic exactly.
  select coalesce(sum(
    case
      when type in ('top_up', 'stake_refund', 'winnings') then amount_pence
      when type in ('stake', 'withdrawal') then -amount_pence
      else 0
    end
  ), 0)
  into v_available
  from public.wallet_transactions
  where user_id = p_user_id;

  -- Check sufficient balance
  if v_available < p_stake_pence then
    raise exception 'INSUFFICIENT_BALANCE: available=%, required=%',
      v_available, p_stake_pence;
  end if;

  -- Insert league member
  insert into public.league_members (league_id, user_id, status, pseudonym)
  values (p_league_id, p_user_id, 'active', p_pseudonym)
  returning id into v_member_id;

  -- Compute balance after deduction
  v_balance_after := v_available - p_stake_pence;

  -- Insert stake transaction
  insert into public.wallet_transactions (
    user_id,
    type,
    amount_pence,
    balance_after_pence,
    reference_id,
    idempotency_key,
    notes
  ) values (
    p_user_id,
    'stake',
    p_stake_pence,
    v_balance_after,
    p_league_id,
    'stake:' || p_league_id::text || ':' || p_user_id::text,
    'Stake for paid league ' || p_league_id::text
  );

  -- Count current members in the league (after this insert)
  select count(*)::integer
  into v_player_count
  from public.league_members
  where league_id = p_league_id;

  return query select v_member_id, v_player_count, v_balance_after;
end;
$$;

comment on function public.atomic_join_paid_league is
  'Atomically validates balance, inserts league member, and deducts stake '
  'in a single transaction. Uses pg_advisory_xact_lock to prevent concurrent '
  'joins from double-spending. Called by join-paid-league Edge Function.';
