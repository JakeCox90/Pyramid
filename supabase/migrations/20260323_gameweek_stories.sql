-- Gameweek stories (AI-generated editorial content per league per gameweek)
create table public.gameweek_stories (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek int not null,
  headline text,
  body text,
  wildcard_pick_id uuid references public.picks(id),
  upset_fixture_id bigint references public.fixtures(id),
  generated_at timestamptz not null default now(),
  is_mass_elimination boolean not null default false,
  idempotency_key text not null unique
);

alter table public.gameweek_stories enable row level security;

create index gameweek_stories_league_gw_idx
  on public.gameweek_stories(league_id, gameweek);

-- RLS: league members can read stories for their leagues
create policy "League members can view stories"
  on public.gameweek_stories for select
  using (
    exists (
      select 1 from public.league_members lm
      where lm.league_id = gameweek_stories.league_id
        and lm.user_id = auth.uid()
    )
  );

-- RLS: only service role can write
-- (No INSERT/UPDATE/DELETE policies = default deny for anon/authenticated)

-- Story views (tracks whether user has seen the story)
create table public.story_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek int not null,
  viewed_at timestamptz not null default now(),
  unique (user_id, league_id, gameweek)
);

alter table public.story_views enable row level security;

create index story_views_user_idx on public.story_views(user_id);

-- RLS: users can read and insert their own rows only
create policy "Users can view own story views"
  on public.story_views for select
  using (auth.uid() = user_id);

create policy "Users can mark stories as viewed"
  on public.story_views for insert
  with check (auth.uid() = user_id);
