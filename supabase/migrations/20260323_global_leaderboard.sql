-- Migration: Global Leaderboard (PYR-106)
-- Creates get_leaderboard() RPC — free leagues only, min 5 settled picks.

CREATE OR REPLACE FUNCTION get_leaderboard(limit_count int DEFAULT 50)
RETURNS TABLE (
    rank             bigint,
    user_id          uuid,
    display_name     text,
    avatar_url       text,
    survival_rate_pct int,
    longest_streak   int,
    wins             int,
    total_picks      int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user          RECORD;
    v_pick          RECORD;
    v_streak        int;
    v_max_streak    int;
    v_prev_league   uuid;
BEGIN
    -- Temporary table to accumulate per-user stats
    CREATE TEMP TABLE _lb_stats (
        user_id          uuid,
        display_name     text,
        avatar_url       text,
        survived_count   int,
        total_settled    int,
        longest_streak   int,
        wins_count       int
    ) ON COMMIT DROP;

    -- Iterate each user who has picks in free leagues
    FOR v_user IN
        SELECT DISTINCT p.user_id
        FROM picks p
        JOIN leagues l ON l.id = p.league_id
        WHERE l.stake_pence = 0
          AND p.result IN ('survived', 'eliminated')
    LOOP
        DECLARE
            v_survived   int := 0;
            v_total      int := 0;
            v_wins       int := 0;
            v_glob_max   int := 0;
        BEGIN
            -- Count survived + total settled picks in free leagues
            SELECT
                COUNT(*) FILTER (WHERE p.result = 'survived'),
                COUNT(*)
            INTO v_survived, v_total
            FROM picks p
            JOIN leagues l ON l.id = p.league_id
            WHERE l.stake_pence = 0
              AND p.user_id = v_user.user_id
              AND p.result IN ('survived', 'eliminated');

            -- Count wins (league_member with status='winner') in free leagues
            SELECT COUNT(*)
            INTO v_wins
            FROM league_members lm
            JOIN leagues l ON l.id = lm.league_id
            WHERE l.stake_pence = 0
              AND lm.user_id = v_user.user_id
              AND lm.status = 'winner';

            -- Compute longest streak per user+league, take global max
            v_streak      := 0;
            v_max_streak  := 0;
            v_prev_league := NULL;

            FOR v_pick IN
                SELECT p.league_id, p.result
                FROM picks p
                JOIN leagues l ON l.id = p.league_id
                WHERE l.stake_pence = 0
                  AND p.user_id = v_user.user_id
                  AND p.result IN ('survived', 'eliminated')
                ORDER BY p.league_id, p.gameweek_id
            LOOP
                -- Reset streak counter when league changes
                IF v_prev_league IS DISTINCT FROM v_pick.league_id THEN
                    IF v_streak > v_max_streak THEN
                        v_max_streak := v_streak;
                    END IF;
                    v_streak := 0;
                END IF;

                IF v_pick.result = 'survived' THEN
                    v_streak := v_streak + 1;
                ELSE
                    IF v_streak > v_max_streak THEN
                        v_max_streak := v_streak;
                    END IF;
                    v_streak := 0;
                END IF;

                v_prev_league := v_pick.league_id;
            END LOOP;

            -- Capture any trailing streak
            IF v_streak > v_max_streak THEN
                v_max_streak := v_streak;
            END IF;

            v_glob_max := v_max_streak;

            -- Only include users with at least 5 settled picks
            IF v_total >= 5 THEN
                INSERT INTO _lb_stats (
                    user_id,
                    display_name,
                    avatar_url,
                    survived_count,
                    total_settled,
                    longest_streak,
                    wins_count
                )
                SELECT
                    v_user.user_id,
                    pr.display_name,
                    pr.avatar_url,
                    v_survived,
                    v_total,
                    v_glob_max,
                    v_wins
                FROM profiles pr
                WHERE pr.id = v_user.user_id;
            END IF;
        END;
    END LOOP;

    -- Return ranked results
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                ROUND((s.survived_count::numeric / s.total_settled) * 100) DESC,
                s.longest_streak DESC,
                s.total_settled DESC
        )::bigint                                                   AS rank,
        s.user_id,
        s.display_name,
        s.avatar_url,
        ROUND(
            (s.survived_count::numeric / s.total_settled) * 100
        )::int                                                      AS survival_rate_pct,
        s.longest_streak,
        s.wins_count                                                AS wins,
        s.total_settled                                             AS total_picks
    FROM _lb_stats s
    ORDER BY
        survival_rate_pct DESC,
        s.longest_streak DESC,
        s.total_settled DESC
    LIMIT limit_count;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_leaderboard(int) TO authenticated;

-- Rollback:
-- DROP FUNCTION IF EXISTS get_leaderboard(int);
