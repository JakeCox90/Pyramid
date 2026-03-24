# PYR-107: Achievements & Badges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 20-badge achievement system with server-side evaluation at settlement time, surfaced via generic design system components (Toast, IconBadge, DetailSheet) and a dedicated achievements screen on the profile.

**Architecture:** Hybrid TypeScript + SQL evaluation. `settle-picks` calls a TypeScript function that fetches match events from API-Football, then delegates to a SQL helper (`check_and_insert_achievements`) for all badge condition checks and idempotent inserts. iOS fetches unlocked badges from `user_achievements` table, compares against a local cache to detect new unlocks, and shows toasts via a generic ToastManager.

**Tech Stack:** Supabase (Postgres, Edge Functions/Deno), SwiftUI (MVVM), API-Football (odds + match events)

**Spec:** `docs/superpowers/specs/2026-03-23-achievements-badges-design.md`

---

## File Structure

### Backend (Supabase)

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260324_achievements.sql` | `user_achievements` table, RLS, odds columns on `fixtures`, `check_and_insert_achievements` SQL function |
| Create | `supabase/migrations/20260324_achievements_backfill.sql` | One-time backfill for historically-earned badges |
| Modify | `supabase/functions/settle-picks/index.ts` | Add `evaluateAchievements()` TypeScript call after settlement |
| Modify | `supabase/functions/sync-fixtures/index.ts` | Fetch and store pre-match odds in `fixtures` table |

### iOS — Design System Components

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `ios/Pyramid/Sources/Shared/DesignSystem/Components/Toast.swift` | Generic slide-in banner view |
| Create | `ios/Pyramid/Sources/Shared/DesignSystem/Components/ToastManager.swift` | Observable toast queue + sequencing |
| Create | `ios/Pyramid/Sources/Shared/DesignSystem/Components/IconBadge.swift` | Icon + label + active/tier state |
| Create | `ios/Pyramid/Sources/Shared/DesignSystem/Components/DetailSheet.swift` | Generic detail sheet (hero icon, title, metadata, body) |

### iOS — Feature Files

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `ios/Pyramid/Sources/Features/Achievements/AchievementCatalog.swift` | Static badge definitions (20 badges) |
| Create | `ios/Pyramid/Sources/Features/Achievements/AchievementsView.swift` | Badge grid grouped by track + singular |
| Create | `ios/Pyramid/Sources/Features/Achievements/AchievementsViewModel.swift` | Fetch, merge with catalog, new badge detection |
| Create | `ios/Pyramid/Sources/Models/Achievement.swift` | Codable model for `user_achievements` row |
| Create | `ios/Pyramid/Sources/Services/AchievementService.swift` | Protocol + implementation for fetching achievements |

### iOS — Integration

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `ios/Pyramid/Sources/App/PyramidApp.swift` | Inject ToastManager into environment |
| Modify | `ios/Pyramid/Sources/App/RootView.swift` | Add toast overlay |
| Modify | `ios/Pyramid/Sources/Features/Profile/ProfileView.swift` | Add Achievements nav row |
| Modify | `ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView.swift` | Register Toast, IconBadge, DetailSheet |
| Modify | `ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView+Features.swift` | Add achievement component demos |

---

## Task 1: Database Migration — `user_achievements` table + odds columns

**Files:**
- Create: `supabase/migrations/20260324_achievements.sql`

**Context:** Follow the pattern in `20260323_user_stats.sql` — section headers with dashes, `COMMENT ON TABLE/COLUMN`, explicit RLS policies, rollback section at bottom.

- [ ] **Step 1: Write the migration**

```sql
-- Migration: Achievements & Badges
-- Description: user_achievements table for badge unlock tracking,
--              odds columns on fixtures for Longshot/Giant Killer evaluation,
--              check_and_insert_achievements() SQL helper function.

-- ─── user_achievements table ────────────────────────────────────────────────

CREATE TABLE public.user_achievements (
    user_id        uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    achievement_id text        NOT NULL,
    unlocked_at    timestamptz NOT NULL DEFAULT now(),
    context        jsonb,
    PRIMARY KEY (user_id, achievement_id)
);

COMMENT ON TABLE public.user_achievements IS 'Badge unlock records — one row per user per badge';
COMMENT ON COLUMN public.user_achievements.achievement_id IS 'Static badge ID e.g. survival_streak_1, icarus';
COMMENT ON COLUMN public.user_achievements.context IS 'Narrative context: league_id, gameweek, team, margin etc.';

CREATE INDEX user_achievements_user_idx ON public.user_achievements(user_id);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements"
    ON public.user_achievements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert achievements"
    ON public.user_achievements FOR INSERT
    WITH CHECK (true);

-- ─── Odds columns on fixtures ───────────────────────────────────────────────

ALTER TABLE public.fixtures ADD COLUMN IF NOT EXISTS home_win_prob numeric(5,2);
ALTER TABLE public.fixtures ADD COLUMN IF NOT EXISTS draw_prob     numeric(5,2);
ALTER TABLE public.fixtures ADD COLUMN IF NOT EXISTS away_win_prob numeric(5,2);

COMMENT ON COLUMN public.fixtures.home_win_prob IS 'Pre-match home win probability 0-100, from API-Football odds';
COMMENT ON COLUMN public.fixtures.draw_prob IS 'Pre-match draw probability 0-100';
COMMENT ON COLUMN public.fixtures.away_win_prob IS 'Pre-match away win probability 0-100';

-- ─── Achievement evaluation helper ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION check_and_insert_achievements(
    target_user_id uuid,
    target_league_id uuid,
    target_gameweek_id integer,
    match_events_json jsonb DEFAULT NULL
)
RETURNS TABLE (achievement_id text, newly_unlocked boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pick_result text;
    v_team_id integer;
    v_fixture_id bigint;
    v_home_score integer;
    v_away_score integer;
    v_home_win_prob numeric(5,2);
    v_away_win_prob numeric(5,2);
    v_is_home boolean;
    v_team_win_prob numeric(5,2);
    v_goal_margin integer;
    v_consecutive_survivals integer;
    v_total_survivals bigint;
    v_total_wins bigint;
    v_total_underdog_wins bigint;
    v_active_at_gw_start bigint;
    v_eliminated_this_gw bigint;
    v_has_prior_elimination boolean;
    v_league_status text;
    v_is_mass_elimination boolean;
    v_all_gws_picked boolean;
BEGIN
    -- ─── Fetch the user's pick for this league/gameweek ─────────────────
    SELECT p.result, p.team_id, p.fixture_id,
           f.home_score, f.away_score, f.home_win_prob, f.away_win_prob,
           (p.team_id = f.home_team_id)
    INTO v_pick_result, v_team_id, v_fixture_id,
         v_home_score, v_away_score, v_home_win_prob, v_away_win_prob,
         v_is_home
    FROM picks p
    JOIN fixtures f ON f.id = p.fixture_id
    WHERE p.user_id = target_user_id
      AND p.league_id = target_league_id
      AND f.gameweek_id = target_gameweek_id
      AND p.result IN ('survived', 'eliminated');

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Derived values
    v_team_win_prob := CASE WHEN v_is_home THEN v_home_win_prob ELSE v_away_win_prob END;
    v_goal_margin := abs(COALESCE(v_home_score, 0) - COALESCE(v_away_score, 0));

    -- Check for mass elimination this GW in this league
    SELECT EXISTS(
        SELECT 1 FROM settlement_log
        WHERE league_id = target_league_id
          AND gameweek_id = target_gameweek_id
          AND details->>'mass_elimination' = 'true'
    ) INTO v_is_mass_elimination;

    -- ─── SURVIVAL STREAK (tiers 1/2/3) ─────────────────────────────────
    -- Only count if survived and not mass elimination
    IF v_pick_result = 'survived' AND NOT v_is_mass_elimination THEN
        -- Count consecutive survivals backwards from this GW in this league
        WITH ordered_picks AS (
            SELECT p.result, f.gameweek_id,
                   ROW_NUMBER() OVER (ORDER BY f.kickoff_at DESC) as rn
            FROM picks p
            JOIN fixtures f ON f.id = p.fixture_id
            LEFT JOIN settlement_log sl ON sl.league_id = p.league_id
                AND sl.gameweek_id = f.gameweek_id
                AND sl.details->>'mass_elimination' = 'true'
            WHERE p.user_id = target_user_id
              AND p.league_id = target_league_id
              AND p.result IN ('survived', 'eliminated')
              AND sl.id IS NULL  -- exclude mass elimination GWs
            ORDER BY f.kickoff_at DESC
        ),
        streak AS (
            SELECT COUNT(*) as len FROM ordered_picks
            WHERE rn <= (
                SELECT COALESCE(MIN(rn) - 1, (SELECT COUNT(*) FROM ordered_picks))
                FROM ordered_picks WHERE result = 'eliminated'
            )
        )
        SELECT len INTO v_consecutive_survivals FROM streak;

        IF v_consecutive_survivals >= 3 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'survival_streak_1',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id, 'streak', v_consecutive_survivals))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_consecutive_survivals >= 5 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'survival_streak_2',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id, 'streak', v_consecutive_survivals))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_consecutive_survivals >= 10 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'survival_streak_3',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id, 'streak', v_consecutive_survivals))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── VETERAN (tiers 1/2/3) — total survivals ───────────────────────
    IF v_pick_result = 'survived' THEN
        SELECT COUNT(*) INTO v_total_survivals
        FROM picks WHERE user_id = target_user_id AND result = 'survived';

        IF v_total_survivals >= 25 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'veteran_1',
                    jsonb_build_object('total_survivals', v_total_survivals))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_survivals >= 50 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'veteran_2',
                    jsonb_build_object('total_survivals', v_total_survivals))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_survivals >= 100 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'veteran_3',
                    jsonb_build_object('total_survivals', v_total_survivals))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── LONGSHOT (tiers 1/2/3) + GIANT KILLER ─────────────────────────
    IF v_pick_result = 'survived' AND v_team_win_prob IS NOT NULL AND v_team_win_prob < 30.00 THEN
        -- Giant Killer (single instance)
        INSERT INTO user_achievements (user_id, achievement_id, context)
        VALUES (target_user_id, 'giant_killer',
                jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                   'team_id', v_team_id, 'win_prob', v_team_win_prob))
        ON CONFLICT DO NOTHING;

        -- Longshot cumulative count
        SELECT COUNT(*) INTO v_total_underdog_wins
        FROM picks p
        JOIN fixtures f ON f.id = p.fixture_id
        WHERE p.user_id = target_user_id
          AND p.result = 'survived'
          AND CASE WHEN p.team_id = f.home_team_id THEN f.home_win_prob ELSE f.away_win_prob END < 30.00;

        IF v_total_underdog_wins >= 3 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'longshot_1',
                    jsonb_build_object('total_underdog_wins', v_total_underdog_wins))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_underdog_wins >= 5 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'longshot_2',
                    jsonb_build_object('total_underdog_wins', v_total_underdog_wins))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_underdog_wins >= 10 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'longshot_3',
                    jsonb_build_object('total_underdog_wins', v_total_underdog_wins))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── AGAINST THE ODDS ──────────────────────────────────────────────
    IF v_pick_result = 'survived' AND NOT v_is_mass_elimination THEN
        -- Count active members at start of this GW:
        -- survived this GW (still active) + eliminated this GW (were active at GW start)
        -- This excludes members eliminated in prior GWs who remain in the table
        SELECT COUNT(*) INTO v_active_at_gw_start
        FROM league_members lm
        WHERE lm.league_id = target_league_id
          AND (
            lm.status = 'active'  -- still surviving
            OR lm.user_id IN (    -- eliminated THIS gameweek specifically
                SELECT p2.user_id FROM picks p2
                JOIN fixtures f2 ON f2.id = p2.fixture_id
                WHERE p2.league_id = target_league_id
                  AND f2.gameweek_id = target_gameweek_id
                  AND p2.result = 'eliminated'
            )
          );

        SELECT COUNT(*) INTO v_eliminated_this_gw
        FROM picks p
        JOIN fixtures f ON f.id = p.fixture_id
        WHERE p.league_id = target_league_id
          AND f.gameweek_id = target_gameweek_id
          AND p.result = 'eliminated';

        IF v_active_at_gw_start > 0 AND
           (v_eliminated_this_gw::numeric / v_active_at_gw_start::numeric) >= 0.5 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'against_the_odds',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                       'eliminated', v_eliminated_this_gw, 'active', v_active_at_gw_start))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── LAST ONE STANDING ──────────────────────────────────────────────
    IF v_pick_result = 'survived' AND NOT v_is_mass_elimination THEN
        -- Check if ALL other active members were eliminated this GW
        IF v_eliminated_this_gw = (v_active_at_gw_start - 1) AND v_active_at_gw_start > 1 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'last_one_standing',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                       'eliminated_count', v_eliminated_this_gw))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── LANDSLIDE ──────────────────────────────────────────────────────
    IF v_pick_result = 'survived' AND v_goal_margin >= 4 THEN
        INSERT INTO user_achievements (user_id, achievement_id, context)
        VALUES (target_user_id, 'landslide',
                jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                   'score', v_home_score || '-' || v_away_score, 'margin', v_goal_margin))
        ON CONFLICT DO NOTHING;
    END IF;

    -- ─── ICARUS ─────────────────────────────────────────────────────────
    IF v_pick_result = 'eliminated' THEN
        -- Reuse streak logic: count prior consecutive survivals (excluding mass elimination GWs)
        WITH ordered_picks AS (
            SELECT p.result,
                   ROW_NUMBER() OVER (ORDER BY f.kickoff_at DESC) as rn
            FROM picks p
            JOIN fixtures f ON f.id = p.fixture_id
            LEFT JOIN settlement_log sl ON sl.league_id = p.league_id
                AND sl.gameweek_id = f.gameweek_id
                AND sl.details->>'mass_elimination' = 'true'
            WHERE p.user_id = target_user_id
              AND p.league_id = target_league_id
              AND p.result IN ('survived', 'eliminated')
              AND f.gameweek_id != target_gameweek_id  -- exclude current (elimination) GW
              AND sl.id IS NULL
            ORDER BY f.kickoff_at DESC
        ),
        streak AS (
            SELECT COUNT(*) as len FROM ordered_picks
            WHERE rn <= (
                SELECT COALESCE(MIN(rn) - 1, (SELECT COUNT(*) FROM ordered_picks))
                FROM ordered_picks WHERE result = 'eliminated'
            )
        )
        SELECT len INTO v_consecutive_survivals FROM streak;

        IF v_consecutive_survivals >= 5 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'icarus',
                    jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                       'streak_before_fall', v_consecutive_survivals))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── NERVES OF STEEL (requires match_events_json) ───────────────────
    IF v_pick_result = 'survived' AND match_events_json IS NOT NULL THEN
        -- Check for 85th min+ winning goal where team was losing/drawing prior
        -- match_events_json format: [{"minute": 90, "team_id": 123, "type": "Goal", ...}]
        -- Reconstruct score at minute 84 to verify team was NOT already winning
        DECLARE
            v_home_goals_before integer := 0;
            v_away_goals_before integer := 0;
            v_team_goals_before integer;
            v_opp_goals_before integer;
            v_has_late_goal boolean := false;
        BEGIN
            -- Count goals by each side before minute 85
            SELECT
                COALESCE(SUM(CASE WHEN (evt->>'team_id')::integer = (SELECT home_team_id FROM fixtures WHERE id = v_fixture_id) THEN 1 ELSE 0 END), 0),
                COALESCE(SUM(CASE WHEN (evt->>'team_id')::integer = (SELECT away_team_id FROM fixtures WHERE id = v_fixture_id) THEN 1 ELSE 0 END), 0)
            INTO v_home_goals_before, v_away_goals_before
            FROM jsonb_array_elements(match_events_json) AS evt
            WHERE (evt->>'type') = 'Goal'
              AND (evt->>'minute')::integer < 85;

            -- Determine picked team's score vs opponent before 85th min
            IF v_is_home THEN
                v_team_goals_before := v_home_goals_before;
                v_opp_goals_before := v_away_goals_before;
            ELSE
                v_team_goals_before := v_away_goals_before;
                v_opp_goals_before := v_home_goals_before;
            END IF;

            -- Check if picked team scored at 85+ (the decisive late goal)
            SELECT EXISTS(
                SELECT 1 FROM jsonb_array_elements(match_events_json) AS evt
                WHERE (evt->>'type') = 'Goal'
                  AND (evt->>'team_id')::integer = v_team_id
                  AND (evt->>'minute')::integer >= 85
            ) INTO v_has_late_goal;

            -- Only award if team was losing or drawing before the late goal
            IF v_has_late_goal AND v_team_goals_before <= v_opp_goals_before THEN
                INSERT INTO user_achievements (user_id, achievement_id, context)
                VALUES (target_user_id, 'nerves_of_steel',
                        jsonb_build_object('league_id', target_league_id, 'gameweek_id', target_gameweek_id,
                                           'fixture_id', v_fixture_id))
                ON CONFLICT DO NOTHING;
            END IF;
        END;
    END IF;

    -- ─── CHAMPION (tiers 1/2/3) — evaluated on winner detection ────────
    SELECT lm.status INTO v_league_status
    FROM league_members lm
    WHERE lm.user_id = target_user_id AND lm.league_id = target_league_id;

    IF v_league_status = 'winner' THEN
        SELECT COUNT(*) INTO v_total_wins
        FROM league_members
        WHERE user_id = target_user_id AND status = 'winner';

        IF v_total_wins >= 1 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'champion_1',
                    jsonb_build_object('league_id', target_league_id, 'total_wins', v_total_wins))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_wins >= 3 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'champion_2',
                    jsonb_build_object('total_wins', v_total_wins))
            ON CONFLICT DO NOTHING;
        END IF;

        IF v_total_wins >= 5 THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'champion_3',
                    jsonb_build_object('total_wins', v_total_wins))
            ON CONFLICT DO NOTHING;
        END IF;

        -- ─── PHOENIX — won after previous elimination ───────────────────
        SELECT EXISTS(
            SELECT 1 FROM league_members
            WHERE user_id = target_user_id
              AND status = 'eliminated'
              AND league_id != target_league_id
        ) INTO v_has_prior_elimination;

        IF v_has_prior_elimination THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'phoenix',
                    jsonb_build_object('league_id', target_league_id))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- ─── FULL HOUSE — pick every GW of a complete round ─────────────────
    -- Only evaluable when the league is complete
    SELECT l.status INTO v_league_status
    FROM leagues l WHERE l.id = target_league_id;

    IF v_league_status = 'completed' THEN
        -- Check if user has a non-void pick for every gameweek in this league's round
        SELECT NOT EXISTS(
            SELECT gw.id FROM gameweeks gw
            JOIN fixtures f ON f.gameweek_id = gw.id
            JOIN picks other_p ON other_p.fixture_id = f.id AND other_p.league_id = target_league_id
            WHERE gw.id NOT IN (
                SELECT f2.gameweek_id FROM picks p2
                JOIN fixtures f2 ON f2.id = p2.fixture_id
                WHERE p2.user_id = target_user_id
                  AND p2.league_id = target_league_id
                  AND p2.result != 'void'
            )
            GROUP BY gw.id
        ) INTO v_all_gws_picked;

        IF v_all_gws_picked THEN
            INSERT INTO user_achievements (user_id, achievement_id, context)
            VALUES (target_user_id, 'full_house',
                    jsonb_build_object('league_id', target_league_id))
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- Return all achievements for this user (useful for caller)
    RETURN QUERY
    SELECT ua.achievement_id, false as newly_unlocked
    FROM user_achievements ua
    WHERE ua.user_id = target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION check_and_insert_achievements(uuid, uuid, integer, jsonb) TO service_role;

-- ─── Rollback ───────────────────────────────────────────────────────────────
-- DROP FUNCTION IF EXISTS public.check_and_insert_achievements(uuid, uuid, integer, jsonb);
-- ALTER TABLE public.fixtures DROP COLUMN IF EXISTS home_win_prob;
-- ALTER TABLE public.fixtures DROP COLUMN IF EXISTS draw_prob;
-- ALTER TABLE public.fixtures DROP COLUMN IF EXISTS away_win_prob;
-- DROP TABLE IF EXISTS public.user_achievements;
```

- [ ] **Step 2: Apply migration locally**

Run: `cd supabase && supabase db reset`
Expected: Migration applies without errors.

- [ ] **Step 3: Verify table and function exist**

Run: `supabase db dump --schema public | grep -E "user_achievements|check_and_insert_achievements|home_win_prob"`
Expected: All three appear in the schema dump.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260324_achievements.sql
git commit -m "feat(PYR-107): add user_achievements table, odds columns, evaluation function"
```

---

## Task 2: Modify `sync-fixtures` — Store pre-match odds

**Files:**
- Modify: `supabase/functions/sync-fixtures/index.ts`

**Context:** The fixture upsert loop (around lines 112-128) maps API-Football response fields to DB columns. API-Football returns odds in `response.odds` or via the odds endpoint. The `raw_api_response` jsonb column already stores the full response. We add three new fields to the upsert map.

- [ ] **Step 1: Add odds extraction to fixture mapping**

In `sync-fixtures/index.ts`, find the `fixtureRows` mapping (around line 112). After `raw_api_response: f`, add odds extraction. API-Football fixtures endpoint returns odds in the `odds` object when available.

Add a helper function before the main handler:

```typescript
function extractWinProbabilities(fixture: any): {
  home_win_prob: number | null;
  draw_prob: number | null;
  away_win_prob: number | null;
} {
  // API-Football returns odds in fixture.odds.response or raw betting data
  // Try to find 1X2 (Match Winner) odds from the fixture data
  try {
    const rawOdds = fixture?.odds;
    if (!rawOdds || !Array.isArray(rawOdds) || rawOdds.length === 0) {
      return { home_win_prob: null, draw_prob: null, away_win_prob: null };
    }
    // Find "Match Winner" market (id: 1)
    const matchWinner = rawOdds
      .flatMap((bookmaker: any) => bookmaker.bets || [])
      .find((bet: any) => bet.id === 1 || bet.name === "Match Winner");

    if (!matchWinner?.values) {
      return { home_win_prob: null, draw_prob: null, away_win_prob: null };
    }

    // Convert decimal odds to implied probability: 1/odds * 100
    const homeOdds = parseFloat(matchWinner.values.find((v: any) => v.value === "Home")?.odd || "0");
    const drawOdds = parseFloat(matchWinner.values.find((v: any) => v.value === "Draw")?.odd || "0");
    const awayOdds = parseFloat(matchWinner.values.find((v: any) => v.value === "Away")?.odd || "0");

    if (homeOdds <= 0 || drawOdds <= 0 || awayOdds <= 0) {
      return { home_win_prob: null, draw_prob: null, away_win_prob: null };
    }

    // Normalize to remove overround (sum to 100%)
    const rawSum = (1 / homeOdds + 1 / drawOdds + 1 / awayOdds) * 100;
    return {
      home_win_prob: Math.round(((1 / homeOdds) * 10000) / rawSum * 100) / 100,
      draw_prob: Math.round(((1 / drawOdds) * 10000) / rawSum * 100) / 100,
      away_win_prob: Math.round(((1 / awayOdds) * 10000) / rawSum * 100) / 100,
    };
  } catch {
    return { home_win_prob: null, draw_prob: null, away_win_prob: null };
  }
}
```

Then in the `fixtureRows` mapping, add the odds fields:

```typescript
const odds = extractWinProbabilities(f);
// Add to the fixture row object:
home_win_prob: odds.home_win_prob,
draw_prob: odds.draw_prob,
away_win_prob: odds.away_win_prob,
```

- [ ] **Step 2: Type-check**

Run: `cd supabase/functions/sync-fixtures && deno check index.ts`
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/sync-fixtures/index.ts
git commit -m "feat(PYR-107): extract and store pre-match odds in fixtures table"
```

---

## Task 3: Modify `settle-picks` — Add achievement evaluation hook

**Files:**
- Modify: `supabase/functions/settle-picks/index.ts`

**Context:** After the per-league settlement loop (around lines 594-609, where PYR-104's stats refresh was added), add achievement evaluation. Follow the same fire-and-forget pattern as stats refresh. Fetch match events from API-Football for Nerves of Steel, then call the SQL function.

- [ ] **Step 1: Add match events fetcher**

Add before the main handler:

```typescript
async function fetchMatchEvents(fixtureId: number, apiKey: string): Promise<any[] | null> {
  try {
    const resp = await fetch(
      `https://v3.football.api-sports.io/fixtures/events?fixture=${fixtureId}`,
      { headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": "v3.football.api-sports.io" } },
    );
    if (!resp.ok) return null;
    const data = await resp.json();
    return data?.response ?? null;
  } catch {
    return null;
  }
}
```

- [ ] **Step 2: Add achievement evaluation after stats refresh**

In the per-league settlement loop, after the stats refresh block (around line 609), add:

```typescript
// ── Achievement evaluation (fire-and-forget, non-critical) ──
const apiKey = Deno.env.get("API_FOOTBALL_KEY") ?? "";
const matchEvents = apiKey
  ? await fetchMatchEvents(fixture.id, apiKey).catch(() => null)
  : null;

const matchEventsJson = matchEvents
  ? JSON.stringify(
      matchEvents
        .filter((e: any) => e.type === "Goal")
        .map((e: any) => ({
          minute: e.time?.elapsed ?? 0,
          team_id: e.team?.id ?? 0,
          type: "Goal",
        })),
    )
  : null;

for (const userId of settledUserIds) {
  db.rpc("check_and_insert_achievements", {
    target_user_id: userId,
    target_league_id: leagueId,
    target_gameweek_id: gameweekId,
    match_events_json: matchEventsJson,
  })
    .then(({ error: achErr }: { error: unknown }) => {
      if (achErr) {
        log.error("check_and_insert_achievements failed (non-fatal)", achErr, { userId, leagueId });
      }
    })
    .catch((err: unknown) => {
      log.error("check_and_insert_achievements threw (non-fatal)", err, { userId, leagueId });
    });
}
```

- [ ] **Step 3: Type-check**

Run: `cd supabase/functions/settle-picks && deno check index.ts`
Expected: No type errors.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/settle-picks/index.ts
git commit -m "feat(PYR-107): add achievement evaluation hook to settle-picks"
```

---

## Task 4: Backfill migration

**Files:**
- Create: `supabase/migrations/20260324_achievements_backfill.sql`

**Context:** Run `check_and_insert_achievements` for every user with historical picks. Odds-dependent badges (Longshot, Giant Killer) and Nerves of Steel won't backfill since historical data is missing — this is expected.

- [ ] **Step 1: Write the backfill migration**

```sql
-- Migration: Achievements backfill
-- Description: One-time evaluation of historically-earned badges for existing users.
-- Longshot, Giant Killer, and Nerves of Steel will not backfill (no historical odds/events).

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT DISTINCT p.user_id, p.league_id, f.gameweek_id
        FROM picks p
        JOIN fixtures f ON f.id = p.fixture_id
        WHERE p.result IN ('survived', 'eliminated')
        ORDER BY f.gameweek_id
    LOOP
        PERFORM check_and_insert_achievements(r.user_id, r.league_id, r.gameweek_id, NULL);
    END LOOP;
END;
$$;
```

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/20260324_achievements_backfill.sql
git commit -m "feat(PYR-107): one-time backfill of historically-earned achievements"
```

---

## Task 5: Design System — Toast + ToastManager

**Files:**
- Create: `ios/Pyramid/Sources/Shared/DesignSystem/Components/Toast.swift`
- Create: `ios/Pyramid/Sources/Shared/DesignSystem/Components/ToastManager.swift`

**Context:** Generic toast system. ToastManager is an ObservableObject injected via environment. Toast is a pure view. Both must be completely agnostic — no knowledge of achievements or any specific feature. Follow the existing design system patterns (Theme tokens, BadgeIntent for styling).

- [ ] **Step 1: Create ToastManager**

```swift
// ToastManager.swift
import SwiftUI

struct ToastConfiguration: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let style: BadgeIntent
    let duration: TimeInterval

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        style: BadgeIntent = .success,
        duration: TimeInterval = 3.0
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.duration = duration
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ToastManager: ObservableObject {
    @Published private(set) var current: ToastConfiguration?
    private var queue: [ToastConfiguration] = []
    private var dismissTask: Task<Void, Never>?

    func show(_ config: ToastConfiguration) {
        queue.append(config)
        if current == nil {
            showNext()
        }
    }

    func show(
        icon: String,
        title: String,
        subtitle: String? = nil,
        style: BadgeIntent = .success
    ) {
        show(ToastConfiguration(
            icon: icon,
            title: title,
            subtitle: subtitle,
            style: style
        ))
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            current = nil
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            showNext()
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        withAnimation(.spring(duration: 0.3)) {
            current = next
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(next.duration))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }
}
```

- [ ] **Step 2: Create Toast view**

```swift
// Toast.swift
import SwiftUI

struct Toast: View {
    let config: ToastConfiguration
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: config.icon)
                .font(Theme.Typography.body)
                .foregroundStyle(config.style.foreground)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .lineLimit(1)

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.elevated
        )
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
        )
        .shadow(
            color: .black.opacity(0.3),
            radius: 8, y: 4
        )
        .padding(.horizontal, Theme.Spacing.s40)
        .onTapGesture { onDismiss?() }
    }
}
```

- [ ] **Step 3: Run `xcodegen generate`**

Run: `cd ios && xcodegen generate`
Expected: Project regenerated successfully.

- [ ] **Step 4: Build to verify**

Run: `xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add ios/Pyramid/Sources/Shared/DesignSystem/Components/Toast.swift \
        ios/Pyramid/Sources/Shared/DesignSystem/Components/ToastManager.swift
git commit -m "feat(PYR-107): add generic Toast and ToastManager design system components"
```

---

## Task 6: Design System — IconBadge

**Files:**
- Create: `ios/Pyramid/Sources/Shared/DesignSystem/Components/IconBadge.swift`

**Context:** Agnostic icon + label + state component. Uses existing `BadgeIntent` from `Card.swift`. No knowledge of achievements.

- [ ] **Step 1: Create IconBadge**

```swift
import SwiftUI

struct IconBadgeConfiguration {
    let icon: String
    let label: String
    let isActive: Bool
    let tier: Int?
    let style: BadgeIntent

    init(
        icon: String,
        label: String,
        isActive: Bool = true,
        tier: Int? = nil,
        style: BadgeIntent = .success
    ) {
        self.icon = icon
        self.label = label
        self.isActive = isActive
        self.tier = tier
        self.style = style
    }
}

struct IconBadge: View {
    let config: IconBadgeConfiguration

    var body: some View {
        VStack(spacing: Theme.Spacing.s10) {
            ZStack {
                Circle()
                    .fill(
                        config.isActive
                            ? config.style.background
                            : Theme.Color.Surface.Background
                                .container
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: config.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        config.isActive
                            ? config.style.foreground
                            : Theme.Color.Content.Text.subtle
                                .opacity(0.4)
                    )
            }
            .overlay(alignment: .topTrailing) {
                if let tier = config.tier, config.isActive {
                    tierIndicator(tier)
                }
            }

            Text(config.label)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    config.isActive
                        ? Theme.Color.Content.Text.default
                        : Theme.Color.Content.Text.subtle
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72)
        }
    }

    private func tierIndicator(_ tier: Int) -> some View {
        Text("\(tier)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
            .frame(width: 18, height: 18)
            .background(config.style.foreground)
            .clipShape(Circle())
            .offset(x: 4, y: -4)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

Run: `cd ios && xcodegen generate && cd .. && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Shared/DesignSystem/Components/IconBadge.swift
git commit -m "feat(PYR-107): add generic IconBadge design system component"
```

---

## Task 7: Design System — DetailSheet

**Files:**
- Create: `ios/Pyramid/Sources/Shared/DesignSystem/Components/DetailSheet.swift`

- [ ] **Step 1: Create DetailSheet**

```swift
import SwiftUI

struct DetailSheetConfiguration {
    let icon: String
    let iconStyle: BadgeIntent
    let title: String
    let subtitle: String?
    let metadata: [(label: String, value: String)]
    let body: String?

    init(
        icon: String,
        iconStyle: BadgeIntent = .success,
        title: String,
        subtitle: String? = nil,
        metadata: [(label: String, value: String)] = [],
        body: String? = nil
    ) {
        self.icon = icon
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.body = body
    }
}

struct DetailSheet: View {
    let config: DetailSheetConfiguration

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            heroIcon
            titleSection
            if !config.metadata.isEmpty {
                metadataSection
            }
            if let body = config.body {
                bodySection(body)
            }
        }
        .padding(Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s20)
        .frame(maxWidth: .infinity)
        .background(
            Theme.Color.Surface.Background.elevated
        )
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(config.iconStyle.background)
                .frame(width: 80, height: 80)

            Image(systemName: config.icon)
                .font(.system(size: 36))
                .foregroundStyle(config.iconStyle.foreground)
        }
    }

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(config.title)
                .font(Theme.Typography.h1)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var metadataSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            ForEach(
                Array(config.metadata.enumerated()),
                id: \.offset
            ) { _, item in
                HStack {
                    Text(item.label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                    Spacer()
                    Text(item.value)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                }
            }
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
    }

    private func bodySection(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.body)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.s20)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

Run: `cd ios && xcodegen generate && cd .. && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Shared/DesignSystem/Components/DetailSheet.swift
git commit -m "feat(PYR-107): add generic DetailSheet design system component"
```

---

## Task 8: Register design system components in browser

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView.swift`
- Modify: `ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView+Features.swift`

**Context:** Add Toast, IconBadge, and DetailSheet demos to the component browser's "Core" tab. Follow the existing section pattern: `ComponentHeader` + variants in `VStack`.

- [ ] **Step 1: Add sections to coreContent**

In `ComponentBrowserView.swift`, find the `coreContent` computed property and add after `placeholderSection`:

```swift
toastSection
iconBadgeSection
detailSheetSection
```

- [ ] **Step 2: Implement demo sections**

In `ComponentBrowserView+Features.swift`, add:

```swift
// MARK: - Toast

var toastSection: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
        ComponentHeader(title: "Toast")

        Toast(config: ToastConfiguration(
            icon: "trophy.fill",
            title: "Achievement Unlocked",
            subtitle: "You earned a new badge",
            style: .success
        ))

        Toast(config: ToastConfiguration(
            icon: "exclamationmark.triangle",
            title: "Connection Lost",
            style: .warning
        ))
    }
}

// MARK: - IconBadge

var iconBadgeSection: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
        ComponentHeader(title: "IconBadge")

        ComponentCaption(text: "Active badges")
        HStack(spacing: Theme.Spacing.s20) {
            IconBadge(config: IconBadgeConfiguration(
                icon: "shield.fill",
                label: "Survivor",
                tier: 1,
                style: .success
            ))
            IconBadge(config: IconBadgeConfiguration(
                icon: "trophy.fill",
                label: "Champion",
                tier: 2,
                style: .warning
            ))
        }

        ComponentCaption(text: "Locked badge")
        IconBadge(config: IconBadgeConfiguration(
            icon: "lock.fill",
            label: "Locked",
            isActive: false,
            style: .neutral
        ))
    }
}

// MARK: - DetailSheet

var detailSheetSection: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
        ComponentHeader(title: "DetailSheet")

        DetailSheet(config: DetailSheetConfiguration(
            icon: "flame.fill",
            iconStyle: .warning,
            title: "Iron Wall",
            subtitle: "Survive 5 consecutive gameweeks",
            metadata: [
                ("Unlocked", "March 23, 2026"),
                ("League", "Office League"),
            ],
            body: "You survived 5 gameweeks in a row without being eliminated."
        ))
    }
}
```

- [ ] **Step 3: Regenerate, build, lint**

Run: `cd ios && xcodegen generate && swiftlint --strict 2>&1 | grep -v "^Linting\|^Done\|^Loading"`
Expected: No violations.

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView.swift \
        ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ComponentBrowserView+Features.swift
git commit -m "feat(PYR-107): register Toast, IconBadge, DetailSheet in design system browser"
```

---

## Task 9: Achievement model + catalog + service

**Files:**
- Create: `ios/Pyramid/Sources/Models/Achievement.swift`
- Create: `ios/Pyramid/Sources/Features/Achievements/AchievementCatalog.swift`
- Create: `ios/Pyramid/Sources/Services/AchievementService.swift`

- [ ] **Step 1: Create Achievement model**

```swift
// Achievement.swift
import Foundation

/// Type-erased Codable wrapper for mixed-type JSON values (strings, ints, bools).
/// Used by Achievement.context which contains heterogeneous values like
/// {"league_id": "uuid", "gameweek": 28, "margin": 5, "team": "Arsenal"}.
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else { value = "" }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        case let string as String: try container.encode(string)
        default: try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}

struct Achievement: Codable, Identifiable, Equatable {
    let achievementId: String
    let unlockedAt: Date
    let context: [String: AnyCodable]?

    var id: String { achievementId }

    enum CodingKeys: String, CodingKey {
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
        case context
    }
}
```

- [ ] **Step 2: Create AchievementCatalog**

```swift
// AchievementCatalog.swift
import Foundation

struct BadgeDefinition {
    let id: String
    let name: String
    let description: String
    let icon: String
    let track: String?
    let tier: Int?
    let style: BadgeIntent
}

enum AchievementCatalog {
    // MARK: - Survival Streak
    static let survivalStreak1 = BadgeDefinition(
        id: "survival_streak_1", name: "Survivor",
        description: "Survive 3 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 1, style: .success)
    static let survivalStreak2 = BadgeDefinition(
        id: "survival_streak_2", name: "Iron Wall",
        description: "Survive 5 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 2, style: .success)
    static let survivalStreak3 = BadgeDefinition(
        id: "survival_streak_3", name: "Untouchable",
        description: "Survive 10 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 3, style: .success)

    // MARK: - Champion
    static let champion1 = BadgeDefinition(
        id: "champion_1", name: "Champion",
        description: "Win your first league",
        icon: "trophy.fill", track: "champion", tier: 1, style: .warning)
    static let champion2 = BadgeDefinition(
        id: "champion_2", name: "Dynasty",
        description: "Win 3 leagues",
        icon: "trophy.fill", track: "champion", tier: 2, style: .warning)
    static let champion3 = BadgeDefinition(
        id: "champion_3", name: "Legend",
        description: "Win 5 leagues",
        icon: "trophy.fill", track: "champion", tier: 3, style: .warning)

    // MARK: - Veteran
    static let veteran1 = BadgeDefinition(
        id: "veteran_1", name: "Seasoned",
        description: "Survive 25 total picks",
        icon: "star.fill", track: "veteran", tier: 1, style: .success)
    static let veteran2 = BadgeDefinition(
        id: "veteran_2", name: "Veteran",
        description: "Survive 50 total picks",
        icon: "star.fill", track: "veteran", tier: 2, style: .success)
    static let veteran3 = BadgeDefinition(
        id: "veteran_3", name: "Centurion",
        description: "Survive 100 total picks",
        icon: "star.fill", track: "veteran", tier: 3, style: .success)

    // MARK: - Longshot
    static let longshot1 = BadgeDefinition(
        id: "longshot_1", name: "Longshot I",
        description: "Win 3 picks backing an underdog (<30% win probability)",
        icon: "target", track: "longshot", tier: 1, style: .warning)
    static let longshot2 = BadgeDefinition(
        id: "longshot_2", name: "Longshot II",
        description: "Win 5 underdog picks",
        icon: "target", track: "longshot", tier: 2, style: .warning)
    static let longshot3 = BadgeDefinition(
        id: "longshot_3", name: "Longshot III",
        description: "Win 10 underdog picks",
        icon: "target", track: "longshot", tier: 3, style: .warning)

    // MARK: - Singular Narrative
    static let againstTheOdds = BadgeDefinition(
        id: "against_the_odds", name: "Against the Odds",
        description: "Survive a gameweek where 50%+ of your league was eliminated",
        icon: "bolt.shield.fill", track: nil, tier: nil, style: .success)
    static let landslide = BadgeDefinition(
        id: "landslide", name: "Landslide",
        description: "Your picked team wins by 4+ goals",
        icon: "flame.fill", track: nil, tier: nil, style: .warning)
    static let lastOneStanding = BadgeDefinition(
        id: "last_one_standing", name: "Last One Standing",
        description: "Be the sole survivor when all others are eliminated",
        icon: "person.fill.checkmark", track: nil, tier: nil, style: .success)
    static let giantKiller = BadgeDefinition(
        id: "giant_killer", name: "Giant Killer",
        description: "Survive by picking an underdog with <30% win probability",
        icon: "figure.fencing", track: nil, tier: nil, style: .warning)
    static let nervesOfSteel = BadgeDefinition(
        id: "nerves_of_steel", name: "Nerves of Steel",
        description: "Your pick wins with a goal in the 85th minute or later",
        icon: "timer", track: nil, tier: nil, style: .success)
    static let phoenix = BadgeDefinition(
        id: "phoenix", name: "Phoenix",
        description: "Get eliminated, then win a different league",
        icon: "bird.fill", track: nil, tier: nil, style: .warning)
    static let fullHouse = BadgeDefinition(
        id: "full_house", name: "Full House",
        description: "Pick every gameweek of a complete round without missing a deadline",
        icon: "checkmark.seal.fill", track: nil, tier: nil, style: .success)
    static let icarus = BadgeDefinition(
        id: "icarus", name: "Icarus",
        description: "Survive 5+ gameweeks in a row, then get eliminated",
        icon: "sun.max.fill", track: nil, tier: nil, style: .neutral)

    // MARK: - All badges

    static let allBadges: [BadgeDefinition] = [
        survivalStreak1, survivalStreak2, survivalStreak3,
        champion1, champion2, champion3,
        veteran1, veteran2, veteran3,
        longshot1, longshot2, longshot3,
        againstTheOdds, landslide, lastOneStanding,
        giantKiller, nervesOfSteel, phoenix, fullHouse, icarus,
    ]

    static let tracks: [(name: String, key: String)] = [
        ("Survival Streak", "survival_streak"),
        ("Champion", "champion"),
        ("Veteran", "veteran"),
        ("Longshot", "longshot"),
    ]

    static func badge(for id: String) -> BadgeDefinition? {
        allBadges.first { $0.id == id }
    }
}
```

- [ ] **Step 3: Create AchievementService**

Follow the `LeaderboardService.swift` pattern exactly.

```swift
// AchievementService.swift
import Foundation
import Supabase

protocol AchievementServiceProtocol: Sendable {
    func fetchUnlocked() async throws -> [Achievement]
}

final class AchievementService: AchievementServiceProtocol {
    private let client: SupabaseClient

    init(
        client: SupabaseClient = SupabaseDependency.shared.client
    ) {
        self.client = client
    }

    func fetchUnlocked() async throws -> [Achievement] {
        try await client
            .from("user_achievements")
            .select("achievement_id, unlocked_at, context")
            .execute()
            .value
    }
}
```

- [ ] **Step 4: Regenerate and build**

Run: `cd ios && xcodegen generate && cd .. && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`

- [ ] **Step 5: Commit**

```bash
git add ios/Pyramid/Sources/Models/Achievement.swift \
        ios/Pyramid/Sources/Features/Achievements/AchievementCatalog.swift \
        ios/Pyramid/Sources/Services/AchievementService.swift
git commit -m "feat(PYR-107): add Achievement model, catalog (20 badges), and service"
```

---

## Task 10: AchievementsViewModel + new badge detection

**Files:**
- Create: `ios/Pyramid/Sources/Features/Achievements/AchievementsViewModel.swift`

**Context:** Fetches unlocked achievements, merges with catalog, detects new badges via UserDefaults cache, triggers toasts.

- [ ] **Step 1: Create AchievementsViewModel**

```swift
import Foundation
import SwiftUI

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var displayBadges: [DisplayBadge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AchievementServiceProtocol
    private let cacheKey = "unlocked_achievement_ids"

    struct DisplayBadge: Identifiable {
        let definition: BadgeDefinition
        let unlocked: Achievement?
        var isUnlocked: Bool { unlocked != nil }
        var id: String { definition.id }
    }

    init(
        service: AchievementServiceProtocol = AchievementService()
    ) {
        self.service = service
    }

    func loadAchievements() async {
        isLoading = true
        errorMessage = nil
        do {
            let unlocked = try await service.fetchUnlocked()
            let unlockedMap = Dictionary(
                uniqueKeysWithValues: unlocked.map {
                    ($0.achievementId, $0)
                }
            )

            displayBadges = AchievementCatalog.allBadges.map {
                DisplayBadge(
                    definition: $0,
                    unlocked: unlockedMap[$0.id]
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkForNewBadges(
        toastManager: ToastManager
    ) async {
        do {
            let unlocked = try await service.fetchUnlocked()
            let currentIds = Set(
                unlocked.map { $0.achievementId }
            )
            let cachedIds = Set(
                UserDefaults.standard.stringArray(
                    forKey: cacheKey
                ) ?? []
            )
            let newIds = currentIds.subtracting(cachedIds)

            for newId in newIds {
                if let badge = AchievementCatalog.badge(
                    for: newId
                ) {
                    toastManager.show(
                        icon: badge.icon,
                        title: badge.name,
                        subtitle: badge.description,
                        style: badge.style
                    )
                }
            }

            UserDefaults.standard.set(
                Array(currentIds),
                forKey: cacheKey
            )
        } catch {
            // Non-critical — silently fail
        }
    }
}
```

- [ ] **Step 2: Regenerate and build**

Run: `cd ios && xcodegen generate && cd .. && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Achievements/AchievementsViewModel.swift
git commit -m "feat(PYR-107): add AchievementsViewModel with new badge detection"
```

---

## Task 11: AchievementsView

**Files:**
- Create: `ios/Pyramid/Sources/Features/Achievements/AchievementsView.swift`

**Context:** Grid of all badges, grouped by track + singular section. Unlocked badges full colour, locked badges greyed. Tapping opens DetailSheet. Follows the pattern of `LeaderboardView` for loading/error/empty states.

- [ ] **Step 1: Create AchievementsView**

```swift
import SwiftUI

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedBadge: AchievementsViewModel.DisplayBadge?

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.Color.Surface.Background.page
                        .ignoresSafeArea()
                )
                .navigationTitle("Achievements")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .task { await viewModel.loadAchievements() }
                .sheet(item: $selectedBadge) { badge in
                    badgeDetail(badge)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        } else if let error = viewModel.errorMessage {
            PlaceholderView(
                icon: "exclamationmark.triangle",
                title: "Something went wrong",
                message: error
            )
        } else {
            badgeGrid
        }
    }

    private var badgeGrid: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s40
            ) {
                ForEach(
                    AchievementCatalog.tracks,
                    id: \.key
                ) { track in
                    trackSection(track)
                }

                singularSection
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s30)
        }
    }

    private func trackSection(
        _ track: (name: String, key: String)
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text(track.name)
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            let trackBadges = viewModel.displayBadges
                .filter { $0.definition.track == track.key }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 80), spacing: Theme.Spacing.s20),
                ],
                spacing: Theme.Spacing.s20
            ) {
                ForEach(trackBadges) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        IconBadge(config: IconBadgeConfiguration(
                            icon: badge.isUnlocked
                                ? badge.definition.icon
                                : "lock.fill",
                            label: badge.isUnlocked
                                ? badge.definition.name
                                : "???",
                            isActive: badge.isUnlocked,
                            tier: badge.definition.tier,
                            style: badge.definition.style
                        ))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var singularSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Moments")
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            let singular = viewModel.displayBadges
                .filter { $0.definition.track == nil }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 80), spacing: Theme.Spacing.s20),
                ],
                spacing: Theme.Spacing.s20
            ) {
                ForEach(singular) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        IconBadge(config: IconBadgeConfiguration(
                            icon: badge.isUnlocked
                                ? badge.definition.icon
                                : "lock.fill",
                            label: badge.isUnlocked
                                ? badge.definition.name
                                : "???",
                            isActive: badge.isUnlocked,
                            style: badge.definition.style
                        ))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func badgeDetail(
        _ badge: AchievementsViewModel.DisplayBadge
    ) -> some View {
        DetailSheet(config: DetailSheetConfiguration(
            icon: badge.definition.icon,
            iconStyle: badge.isUnlocked
                ? badge.definition.style
                : .neutral,
            title: badge.isUnlocked
                ? badge.definition.name
                : "???",
            subtitle: badge.isUnlocked
                ? badge.definition.description
                : "Keep playing to unlock this badge",
            metadata: badge.unlocked.map { achievement in
                [("Unlocked", achievement.unlockedAt
                    .formatted(date: .abbreviated, time: .omitted))]
            } ?? [],
            body: badge.unlocked?.context?["team"]
                .map { "Earned with \($0)" }
        ))
    }
}
```

- [ ] **Step 2: Regenerate, build, lint**

Run: `cd ios && xcodegen generate && swiftlint --strict 2>&1 | grep -v "^Linting\|^Done\|^Loading"`
Expected: No violations. Check file length < 300 lines.

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Achievements/AchievementsView.swift
git commit -m "feat(PYR-107): add AchievementsView with badge grid and detail sheet"
```

---

## Task 12: Integration — ToastManager injection, toast overlay, profile nav, foreground check

**Dependencies:** Task 5 (Toast + ToastManager must exist), Task 10 (AchievementsViewModel must exist), Task 11 (AchievementsView must exist).

**Files:**
- Modify: `ios/Pyramid/Sources/App/PyramidApp.swift` — inject ToastManager
- Modify: `ios/Pyramid/Sources/App/RootView.swift` — toast overlay + foreground check
- Modify: `ios/Pyramid/Sources/Features/Profile/ProfileView.swift` — achievements nav row

- [ ] **Step 1: Inject ToastManager in PyramidApp.swift**

Add `@StateObject private var toastManager = ToastManager()` alongside the existing `appState`. Add `.environmentObject(toastManager)` to the RootView:

```swift
RootView()
    .environmentObject(appState)
    .environmentObject(toastManager)
```

- [ ] **Step 2: Add toast overlay and foreground check to RootView.swift**

Add `@EnvironmentObject private var toastManager: ToastManager` to RootView.

Add `@Environment(\.scenePhase) private var scenePhase` for foreground detection.

Add `@StateObject private var achievementsVM = AchievementsViewModel()` for badge checking.

After the `.task` modifier, add:

```swift
.overlay(alignment: .top) {
    if let toast = toastManager.current {
        Toast(config: toast, onDismiss: { toastManager.dismiss() })
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
            )
            .padding(.top, Theme.Spacing.s60)
            .zIndex(999)
    }
}
.animation(.spring(duration: 0.3), value: toastManager.current)
.onChange(of: scenePhase) { phase in
    if phase == .active {
        Task {
            await achievementsVM.checkForNewBadges(
                toastManager: toastManager
            )
        }
    }
}
```

- [ ] **Step 3: Add achievements row to ProfileView.swift**

In the `settingsSection` computed property, add between the Leaderboard and Notifications rows:

```swift
settingsRow(
    title: "Achievements",
    icon: "trophy.circle.fill",
    destination: AchievementsView()
)
```

- [ ] **Step 4: Regenerate, build, lint**

Run: `cd ios && xcodegen generate && cd .. && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Then: `cd ios && swiftlint --strict 2>&1 | grep -v "^Linting\|^Done\|^Loading"`

Check ProfileView.swift line count — must stay under 300.

- [ ] **Step 5: Commit**

```bash
git add ios/Pyramid/Sources/App/PyramidApp.swift \
        ios/Pyramid/Sources/App/RootView.swift \
        ios/Pyramid/Sources/Features/Profile/ProfileView.swift
git commit -m "feat(PYR-107): integrate toast overlay, foreground badge check, profile nav"
```

---

## Task 13: Final verification

- [ ] **Step 1: Full build**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid && xcodebuild build -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -10`
Expected: Build succeeds with only pre-existing warnings.

- [ ] **Step 2: SwiftLint**

Run: `cd ios && swiftlint --strict 2>&1 | grep -v "^Linting\|^Done\|^Loading\|^Found"`
Expected: No violations.

- [ ] **Step 3: Verify file counts**

Run: `wc -l ios/Pyramid/Sources/Features/Achievements/*.swift ios/Pyramid/Sources/Features/Profile/ProfileView.swift ios/Pyramid/Sources/App/RootView.swift`
Expected: All files under 300 lines.

- [ ] **Step 4: Verify all 20 badges in catalog**

Run: `grep -c "BadgeDefinition(" ios/Pyramid/Sources/Features/Achievements/AchievementCatalog.swift`
Expected: `20`

- [ ] **Step 5: Final commit if any adjustments needed**
