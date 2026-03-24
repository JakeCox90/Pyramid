-- Migration: 20260323_user_stats
-- Description: User stats aggregation — table, RLS, and refresh function for PYR-104.
--
-- Rollback:
--   DROP FUNCTION IF EXISTS public.refresh_user_stats(uuid);
--   DROP TABLE IF EXISTS public.user_stats;

-- ─── Table ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_stats (
  user_id                  uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_leagues_joined     integer NOT NULL DEFAULT 0,
  wins                     integer NOT NULL DEFAULT 0,
  total_picks_made         integer NOT NULL DEFAULT 0,
  longest_survival_streak  integer NOT NULL DEFAULT 0,
  current_streak           integer NOT NULL DEFAULT 0,
  survival_rate_pct        integer NOT NULL DEFAULT 0 CHECK (survival_rate_pct BETWEEN 0 AND 100),
  updated_at               timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.user_stats IS
  'Aggregated per-user stats refreshed after every pick settlement. Read-only for the iOS client.';

COMMENT ON COLUMN public.user_stats.longest_survival_streak IS
  'Max consecutive survived picks ever, computed per-league then global max.';

COMMENT ON COLUMN public.user_stats.current_streak IS
  'Consecutive survived picks from most recent settled_at backwards across all leagues; resets on eliminated.';

COMMENT ON COLUMN public.user_stats.survival_rate_pct IS
  'round((survived / total non-void settled) * 100), 0–100.';

-- ─── Indexes ─────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS user_stats_updated_at_idx ON public.user_stats(updated_at);

-- ─── RLS ─────────────────────────────────────────────────────────────────────

ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

-- Users can read their own stats row.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_stats' AND policyname = 'Users can view own stats'
  ) THEN
    CREATE POLICY "Users can view own stats" ON public.user_stats FOR SELECT USING (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_stats' AND policyname = 'Service role can insert stats'
  ) THEN
    CREATE POLICY "Service role can insert stats" ON public.user_stats FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_stats' AND policyname = 'Service role can update stats'
  ) THEN
    CREATE POLICY "Service role can update stats" ON public.user_stats FOR UPDATE USING (true);
  END IF;
END
$$;

-- ─── refresh_user_stats(target_user_id) ──────────────────────────────────────
--
-- Recomputes all stats for a single user and UPSERTs into user_stats.
-- SECURITY DEFINER so it can read picks/league_members bypassing RLS.
-- Idempotent: calling multiple times produces the same result.
--
-- Stat definitions:
--   total_leagues_joined    COUNT of league_members rows for this user
--   wins                    COUNT of league_members rows with status = 'winner'
--   total_picks_made        COUNT of picks rows for this user
--   survival_rate_pct       round(survived / (survived + eliminated) * 100)
--   current_streak          consecutive 'survived' picks from most recent settled_at backwards,
--                           stopping at first 'eliminated' (void/pending skipped)
--   longest_survival_streak max consecutive 'survived' picks within any single league

CREATE OR REPLACE FUNCTION public.refresh_user_stats(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_total_leagues_joined     integer;
  v_wins                     integer;
  v_total_picks_made         integer;
  v_survived_count           integer;
  v_settled_non_void_count   integer;
  v_survival_rate_pct        integer;
  v_current_streak           integer;
  v_longest_survival_streak  integer;

  -- For current_streak calculation
  rec                        record;

  -- For per-league streak calculation
  league_rec                 record;
  streak_rec                 record;
  league_streak              integer;
  in_streak                  boolean;
BEGIN

  -- ── 1. total_leagues_joined ────────────────────────────────────────────────
  SELECT COUNT(*)
    INTO v_total_leagues_joined
    FROM public.league_members
   WHERE user_id = target_user_id;

  -- ── 2. wins ───────────────────────────────────────────────────────────────
  SELECT COUNT(*)
    INTO v_wins
    FROM public.league_members
   WHERE user_id = target_user_id
     AND status = 'winner';

  -- ── 3. total_picks_made ───────────────────────────────────────────────────
  SELECT COUNT(*)
    INTO v_total_picks_made
    FROM public.picks
   WHERE user_id = target_user_id;

  -- ── 4. survival_rate_pct ──────────────────────────────────────────────────
  --   Non-void settled picks = survived + eliminated (result NOT IN pending, void).
  SELECT
    COUNT(*) FILTER (WHERE result = 'survived'),
    COUNT(*) FILTER (WHERE result IN ('survived', 'eliminated'))
    INTO v_survived_count, v_settled_non_void_count
    FROM public.picks
   WHERE user_id = target_user_id
     AND result NOT IN ('pending', 'void');

  IF v_settled_non_void_count = 0 THEN
    v_survival_rate_pct := 0;
  ELSE
    v_survival_rate_pct := ROUND(v_survived_count::numeric / v_settled_non_void_count::numeric * 100)::integer;
  END IF;

  -- ── 5. current_streak ─────────────────────────────────────────────────────
  --   Walk settled picks newest→oldest across all leagues.
  --   Skip void and pending. Stop counting on first 'eliminated'.
  v_current_streak := 0;

  FOR rec IN
    SELECT result
      FROM public.picks
     WHERE user_id = target_user_id
       AND result IN ('survived', 'eliminated')
     ORDER BY settled_at DESC NULLS LAST
  LOOP
    IF rec.result = 'survived' THEN
      v_current_streak := v_current_streak + 1;
    ELSE
      -- First eliminated — streak broken
      EXIT;
    END IF;
  END LOOP;

  -- ── 6. longest_survival_streak ────────────────────────────────────────────
  --   Compute per-league max streak, then take the global max.
  --   Within each league: walk picks oldest→newest, count consecutive survived,
  --   reset on eliminated.
  v_longest_survival_streak := 0;

  FOR league_rec IN
    SELECT DISTINCT league_id
      FROM public.picks
     WHERE user_id = target_user_id
       AND result IN ('survived', 'eliminated')
  LOOP
    league_streak := 0;
    in_streak     := false;

    FOR streak_rec IN
      SELECT result
        FROM public.picks
       WHERE user_id = target_user_id
         AND league_id = league_rec.league_id
         AND result IN ('survived', 'eliminated')
       ORDER BY settled_at ASC NULLS LAST
    LOOP
      IF streak_rec.result = 'survived' THEN
        league_streak := league_streak + 1;
        IF league_streak > v_longest_survival_streak THEN
          v_longest_survival_streak := league_streak;
        END IF;
      ELSE
        -- Reset streak on eliminated
        league_streak := 0;
      END IF;
    END LOOP;
  END LOOP;

  -- ── 7. UPSERT ─────────────────────────────────────────────────────────────
  INSERT INTO public.user_stats (
    user_id,
    total_leagues_joined,
    wins,
    total_picks_made,
    longest_survival_streak,
    current_streak,
    survival_rate_pct,
    updated_at
  ) VALUES (
    target_user_id,
    v_total_leagues_joined,
    v_wins,
    v_total_picks_made,
    v_longest_survival_streak,
    v_current_streak,
    v_survival_rate_pct,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    total_leagues_joined    = EXCLUDED.total_leagues_joined,
    wins                    = EXCLUDED.wins,
    total_picks_made        = EXCLUDED.total_picks_made,
    longest_survival_streak = EXCLUDED.longest_survival_streak,
    current_streak          = EXCLUDED.current_streak,
    survival_rate_pct       = EXCLUDED.survival_rate_pct,
    updated_at              = EXCLUDED.updated_at;

END;
$$;

COMMENT ON FUNCTION public.refresh_user_stats(uuid) IS
  'Recomputes all stats for a single user from league_members + picks and UPSERTs into user_stats. Idempotent.';
