-- Gameweek stories (AI-generated editorial content per league per gameweek)
CREATE TABLE IF NOT EXISTS public.gameweek_stories (
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

COMMENT ON TABLE public.gameweek_stories IS 'AI-generated editorial story content per league per gameweek. Written by generate-gameweek-story edge function after settlement.';

ALTER TABLE public.gameweek_stories ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS gameweek_stories_league_gw_idx
  ON public.gameweek_stories(league_id, gameweek_id);

-- RLS: league members can read stories for their leagues
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'gameweek_stories'
      AND policyname = 'League members can view stories'
  ) THEN
    CREATE POLICY "League members can view stories"
      ON public.gameweek_stories FOR SELECT
      USING (
        league_id IN (SELECT public.user_league_ids(auth.uid()))
      );
  END IF;
END $$;

-- RLS: only service role can write
-- (No INSERT/UPDATE/DELETE policies = default deny for anon/authenticated)

-- Story views (tracks whether user has seen the story)
CREATE TABLE IF NOT EXISTS public.story_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek_id integer not null references public.gameweeks(id),
  viewed_at timestamptz not null default now(),
  unique (user_id, league_id, gameweek_id)
);

COMMENT ON TABLE public.story_views IS 'Tracks whether a user has viewed the gameweek story for a league. Written client-side on first view (upsert, ignore conflict).';

ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS story_views_user_idx ON public.story_views(user_id);

-- RLS: users can read and insert their own rows only
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'story_views'
      AND policyname = 'Users can view own story views'
  ) THEN
    CREATE POLICY "Users can view own story views"
      ON public.story_views FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'story_views'
      AND policyname = 'Users can mark stories as viewed'
  ) THEN
    CREATE POLICY "Users can mark stories as viewed"
      ON public.story_views FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
