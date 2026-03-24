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
