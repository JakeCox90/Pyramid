-- Migration: 20260307000000_initial_schema
-- Description: Core schema for Pyramid — Last Man Standing
-- All tables have RLS enabled. Policies are explicit — no table is publicly readable/writable.

-- ─── Extensions ──────────────────────────────────────────────────────────────

-- uuid-ossp not needed — using gen_random_uuid() (built-in since Postgres 13)

-- ─── Profiles ────────────────────────────────────────────────────────────────
-- Extends auth.users. Created automatically on signup via trigger.

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text not null unique,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is 'Public profile for each authenticated user. Mirrors auth.users.';

alter table public.profiles enable row level security;

create policy "Users can view any profile"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Trigger: create profile on auth.users insert
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── Gameweeks ───────────────────────────────────────────────────────────────

create table public.gameweeks (
  id            serial primary key,
  season        integer not null,        -- e.g. 2025 for 2025/26 season
  round_number  integer not null,        -- 1–38
  name          text not null,           -- e.g. "Gameweek 12"
  deadline_at   timestamptz,             -- kick-off of first match in this GW
  is_current    boolean not null default false,
  is_finished   boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  unique (season, round_number)
);

comment on table public.gameweeks is 'Premier League gameweeks for each season.';

alter table public.gameweeks enable row level security;

create policy "Gameweeks are publicly readable"
  on public.gameweeks for select
  using (true);

-- ─── Fixtures ────────────────────────────────────────────────────────────────

create table public.fixtures (
  id                  bigint primary key,    -- API-Football fixture ID
  gameweek_id         integer not null references public.gameweeks(id),
  home_team_id        integer not null,
  home_team_name      text not null,
  home_team_short     text not null,         -- e.g. "MCI"
  away_team_id        integer not null,
  away_team_name      text not null,
  away_team_short     text not null,
  kickoff_at          timestamptz not null,
  status              text not null default 'NS', -- NS, 1H, HT, 2H, FT, PST, CANC, ABD
  home_score          integer,
  away_score          integer,
  settled_at          timestamptz,           -- when settlement was processed
  raw_api_response    jsonb,                 -- full API-Football response for audit
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.fixtures is 'Premier League fixtures sourced from API-Football. Status reflects official result.';

create index fixtures_gameweek_idx on public.fixtures(gameweek_id);
create index fixtures_status_idx on public.fixtures(status);
create index fixtures_home_team_idx on public.fixtures(home_team_id);
create index fixtures_away_team_idx on public.fixtures(away_team_id);

alter table public.fixtures enable row level security;

create policy "Fixtures are publicly readable"
  on public.fixtures for select
  using (true);

-- ─── Leagues ─────────────────────────────────────────────────────────────────

create type public.league_type as enum ('free', 'paid');
create type public.league_status as enum ('pending', 'active', 'completed', 'cancelled');

create table public.leagues (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  join_code         text not null unique,
  type              public.league_type not null default 'free',
  status            public.league_status not null default 'pending',
  created_by        uuid not null references public.profiles(id),
  season            integer not null,
  start_gameweek_id integer not null references public.gameweeks(id),
  max_players       integer,               -- null = no cap
  entry_fee_pence   integer,               -- null for free leagues; stored in pence
  prize_pot_pence   integer default 0,     -- accumulated entry fees minus platform fee
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on table public.leagues is 'Last Man Standing leagues. Settings locked after start_gameweek deadline.';

create index leagues_join_code_idx on public.leagues(join_code);
create index leagues_created_by_idx on public.leagues(created_by);
create index leagues_season_idx on public.leagues(season);

alter table public.leagues enable row level security;

create policy "Anyone can view a league by join code (for join flow)"
  on public.leagues for select
  using (status = 'pending');

-- Note: "League members can view their leagues" policy is created after league_members table below.

-- ─── League Members ──────────────────────────────────────────────────────────

create type public.member_status as enum ('active', 'eliminated', 'winner');

create table public.league_members (
  id          uuid primary key default gen_random_uuid(),
  league_id   uuid not null references public.leagues(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  status      public.member_status not null default 'active',
  joined_at   timestamptz not null default now(),
  eliminated_at timestamptz,
  eliminated_in_gameweek_id integer references public.gameweeks(id),

  unique (league_id, user_id)
);

comment on table public.league_members is 'Players in each league with their current survival status.';

create index league_members_league_idx on public.league_members(league_id);
create index league_members_user_idx on public.league_members(user_id);
create index league_members_status_idx on public.league_members(status);

alter table public.league_members enable row level security;

create policy "League members can view membership for their leagues"
  on public.league_members for select
  using (
    exists (
      select 1 from public.league_members lm
      where lm.league_id = league_id and lm.user_id = auth.uid()
    )
  );

-- Deferred: leagues policy that references league_members (must come after league_members exists)
create policy "League members can view their leagues"
  on public.leagues for select
  using (
    exists (
      select 1 from public.league_members lm
      where lm.league_id = id and lm.user_id = auth.uid()
    )
  );

-- ─── Picks ───────────────────────────────────────────────────────────────────

create type public.pick_result as enum ('pending', 'survived', 'eliminated', 'void');

create table public.picks (
  id              uuid primary key default gen_random_uuid(),
  league_id       uuid not null references public.leagues(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  gameweek_id     integer not null references public.gameweeks(id),
  fixture_id      bigint not null references public.fixtures(id),
  team_id         integer not null,
  team_name       text not null,
  is_locked       boolean not null default false,  -- true after deadline
  result          public.pick_result not null default 'pending',
  submitted_at    timestamptz not null default now(),
  locked_at       timestamptz,
  settled_at      timestamptz,
  idempotency_key text unique,                     -- prevents double-settlement

  unique (league_id, user_id, gameweek_id)         -- one pick per player per GW per league
);

comment on table public.picks is 'Weekly picks. Locked at gameweek deadline. Settled when fixture reaches FT.';

create index picks_league_gameweek_idx on public.picks(league_id, gameweek_id);
create index picks_user_league_idx on public.picks(user_id, league_id);
create index picks_fixture_idx on public.picks(fixture_id);
create index picks_result_idx on public.picks(result);

alter table public.picks enable row level security;

-- Players can see their own picks always
create policy "Users can view their own picks"
  on public.picks for select
  using (auth.uid() = user_id);

-- After deadline: all picks in the same league are visible to fellow members
create policy "League members can view picks after deadline"
  on public.picks for select
  using (
    is_locked = true
    and exists (
      select 1 from public.league_members lm
      where lm.league_id = picks.league_id and lm.user_id = auth.uid()
    )
  );

-- Players can insert their own picks (pre-deadline enforcement in Edge Function)
create policy "Users can insert their own picks"
  on public.picks for insert
  with check (auth.uid() = user_id and is_locked = false);

-- Players can update their own unlocked picks
create policy "Users can update their own unlocked picks"
  on public.picks for update
  using (auth.uid() = user_id and is_locked = false);

-- ─── Pick History (for used-team tracking) ───────────────────────────────────
-- Derived view: which teams has a player already picked in a league this season?

create view public.used_teams as
  select
    p.league_id,
    p.user_id,
    p.team_id,
    p.team_name,
    p.gameweek_id,
    p.result
  from public.picks p
  where p.result != 'void';  -- voided picks (postponed) don't count against team usage

comment on view public.used_teams is 'Teams already used by each player in each league. Voided picks excluded.';

-- ─── Settlement Audit Log ────────────────────────────────────────────────────

create table public.settlement_log (
  id              uuid primary key default gen_random_uuid(),
  fixture_id      bigint not null references public.fixtures(id),
  gameweek_id     integer not null references public.gameweeks(id),
  league_id       uuid not null references public.leagues(id),
  picks_processed integer not null default 0,
  eliminations    integer not null default 0,
  survivors       integer not null default 0,
  voids           integer not null default 0,
  is_mass_elimination boolean not null default false,
  settled_at      timestamptz not null default now(),
  idempotency_key text not null unique,
  notes           text
);

comment on table public.settlement_log is 'Immutable audit log of all settlement runs. Idempotency key prevents double-processing.';

alter table public.settlement_log enable row level security;

-- Settlement log: league members can read their league's log
create policy "League members can view settlement log"
  on public.settlement_log for select
  using (
    exists (
      select 1 from public.league_members lm
      where lm.league_id = settlement_log.league_id and lm.user_id = auth.uid()
    )
  );

-- ─── Updated At Triggers ─────────────────────────────────────────────────────

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger set_gameweeks_updated_at before update on public.gameweeks
  for each row execute procedure public.set_updated_at();

create trigger set_fixtures_updated_at before update on public.fixtures
  for each row execute procedure public.set_updated_at();

create trigger set_leagues_updated_at before update on public.leagues
  for each row execute procedure public.set_updated_at();
