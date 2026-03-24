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

-- No INSERT/UPDATE/DELETE policies — all writes via SECURITY DEFINER function
-- (check_and_insert_achievements), which bypasses RLS. No client-side writes allowed.

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
          AND is_mass_elimination = true
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
                AND sl.is_mass_elimination = true
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
                AND sl.is_mass_elimination = true
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
