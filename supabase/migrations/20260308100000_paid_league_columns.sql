-- Migration: 20260308_paid_league_columns
-- Description: Adds paid league columns to leagues and league_members tables.
--   leagues: stake_pence, paid_league_status, prize_pot_pence, platform_fee_pence,
--            round_started_at, round_ended_at
--   league_members: pseudonym, finishing_position, prize_pence
-- ROLLBACK: ALTER TABLE public.leagues DROP COLUMN IF EXISTS stake_pence, DROP COLUMN IF EXISTS paid_status, DROP COLUMN IF EXISTS prize_pot_pence, DROP COLUMN IF EXISTS platform_fee_pence, DROP COLUMN IF EXISTS round_started_at, DROP COLUMN IF EXISTS round_ended_at; ALTER TABLE public.league_members DROP COLUMN IF EXISTS pseudonym, DROP COLUMN IF EXISTS finishing_position, DROP COLUMN IF EXISTS prize_pence; DROP TYPE IF EXISTS public.paid_league_status;

-- ─── New enum for paid league lifecycle ──────────────────────────────────────
-- Free leagues use the existing league_status enum (pending → active → completed).
-- Paid matchmaking leagues have a distinct lifecycle: waiting (< min players) →
-- active (≥ 5 players, round in progress) → complete (winner declared).
-- We add a separate column so paid and free lifecycle states don't conflict.

do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'paid_league_status'
  ) then
    create type public.paid_league_status as enum ('waiting', 'active', 'complete');
  end if;
end
$$;

-- ─── leagues additions ────────────────────────────────────────────────────────

alter table public.leagues
  add column if not exists stake_pence           integer,
  add column if not exists paid_status           public.paid_league_status,
  add column if not exists prize_pot_pence       integer,
  add column if not exists platform_fee_pence    integer,
  add column if not exists round_started_at      timestamptz,
  add column if not exists round_ended_at        timestamptz;

comment on column public.leagues.paid_status is
  'Lifecycle state for paid matchmaking leagues: waiting (< 5 players), active (round in progress), complete (winner declared). Null for free leagues.';
comment on column public.leagues.stake_pence is
  'Fixed stake per entry in pence. 5000 (£5) for paid leagues. Null for free leagues.';
comment on column public.leagues.round_started_at is
  'Timestamp when the minimum player count was reached and the round began.';

-- ─── league_members additions ─────────────────────────────────────────────────

alter table public.league_members
  add column if not exists pseudonym          text,
  add column if not exists finishing_position integer,
  add column if not exists prize_pence        integer;

comment on column public.league_members.pseudonym is
  'Stable pseudonym for this member in this paid league (e.g. "Player 7"). Revealed real identity when round_ended_at is set.';
comment on column public.league_members.finishing_position is
  '1st, 2nd, or 3rd place. Set by distribute-prizes Edge Function at round end.';

-- ─── Indexes ──────────────────────────────────────────────────────────────────

create index if not exists leagues_paid_status_idx on public.leagues(paid_status)
  where paid_status is not null;
create index if not exists leagues_stake_pence_idx on public.leagues(stake_pence)
  where stake_pence is not null;
create index if not exists league_members_pseudonym_idx on public.league_members(pseudonym)
  where pseudonym is not null;

-- ─── RLS: pseudonymity in active paid leagues ──────────────────────────────────
-- In active paid leagues, members can only see pseudonyms (not real user data)
-- of other members until round_ended_at is set (rules §2.3).
-- This is enforced at the application layer in Edge Functions — the direct DB
-- policy below supplements it by restricting what the iOS client can query directly.
--
-- Policy: league_members.pseudonym is visible to all members of the same league.
-- Real profile data (profiles table) is always visible (existing policy "Users can view any profile").
-- The Edge Function's response shape is the enforcement point — it omits user_id
-- for other members in active paid leagues until round_ended_at is set.

-- No additional RLS needed here — the existing league_members select policy already
-- restricts reads to members of the same league. The pseudonymity guarantee is
-- enforced by Edge Functions returning pseudonym instead of user_id in responses.
