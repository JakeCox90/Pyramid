-- Gameweek stories (AI-generated editorial content per league per gameweek)
create table public.gameweek_stories (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek_id integer not null references public.gameweeks(id),
  headline text,
  body text,
  wildcard_pick_id uuid references public.picks(id),
  upset_fixture_id bigint references public.fixtures(id),
  generated_at timestamptz not null default now(),
  is_mass_elimination boolean not null default false,
  idempotency_key text not null unique
);

comment on table public.gameweek_stories is 'AI-generated editorial story content per league per gameweek. Written by generate-gameweek-story edge function after settlement.';

alter table public.gameweek_stories enable row level security;

create index gameweek_stories_league_gw_idx
  on public.gameweek_stories(league_id, gameweek_id);

-- RLS: league members can read stories for their leagues
-- Uses security-definer function to avoid RLS recursion on league_members
create policy "League members can view stories"
  on public.gameweek_stories for select
  using (
    league_id in (select public.user_league_ids(auth.uid()))
  );

-- RLS: only service role can write
-- (No INSERT/UPDATE/DELETE policies = default deny for anon/authenticated)

-- Story views (tracks whether user has seen the story)
create table public.story_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek_id integer not null references public.gameweeks(id),
  viewed_at timestamptz not null default now(),
  unique (user_id, league_id, gameweek_id)
);

comment on table public.story_views is 'Tracks whether a user has viewed the gameweek story for a league. Written client-side on first view (upsert, ignore conflict).';

alter table public.story_views enable row level security;

create index story_views_user_idx on public.story_views(user_id);

-- RLS: users can read and insert their own rows only (no update/delete by design)
create policy "Users can view own story views"
  on public.story_views for select
  using (auth.uid() = user_id);

create policy "Users can mark stories as viewed"
  on public.story_views for insert
  with check (auth.uid() = user_id);
