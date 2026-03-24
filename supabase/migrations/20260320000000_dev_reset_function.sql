-- =============================================================================
-- Pyramid — Dev Reset Function (PYR-128)
-- =============================================================================
-- Postgres function to reset dev seed data in-place.
-- Two modes:
--   "game"  — wipe and re-seed everything (user keeps profile/onboarding)
--   "full"  — wipe and re-seed, but skip test user profile/memberships/picks
--             (simulates fresh install / first-time experience)
--
-- Safety: refuses to run unless app.environment = 'dev'.
-- Called via: supabase.rpc('dev_reset_data', { p_mode, p_caller_id })
-- =============================================================================

CREATE OR REPLACE FUNCTION public.dev_reset_data(p_mode text, p_caller_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_env text;

  -- Gameweek serial IDs (looked up after insert)
  v_gw27 integer;
  v_gw28 integer;
  v_gw29 integer;
  v_gw30 integer;

  -- Bot UUIDs
  v_bot01 uuid := '00000000-0000-0000-0000-000000000001';
  v_bot02 uuid := '00000000-0000-0000-0000-000000000002';
  v_bot03 uuid := '00000000-0000-0000-0000-000000000003';
  v_bot04 uuid := '00000000-0000-0000-0000-000000000004';
  v_bot05 uuid := '00000000-0000-0000-0000-000000000005';
  v_bot06 uuid := '00000000-0000-0000-0000-000000000006';
  v_bot07 uuid := '00000000-0000-0000-0000-000000000007';
  v_bot08 uuid := '00000000-0000-0000-0000-000000000008';
  v_bot09 uuid := '00000000-0000-0000-0000-000000000009';
  v_bot10 uuid := '00000000-0000-0000-0000-000000000010';
  v_bot11 uuid := '00000000-0000-0000-0000-000000000011';
  v_bot12 uuid := '00000000-0000-0000-0000-000000000012';
  v_bot13 uuid := '00000000-0000-0000-0000-000000000013';
  v_bot14 uuid := '00000000-0000-0000-0000-000000000014';
  v_bot15 uuid := '00000000-0000-0000-0000-000000000015';
  v_bot16 uuid := '00000000-0000-0000-0000-000000000016';
  v_bot17 uuid := '00000000-0000-0000-0000-000000000017';
  v_bot18 uuid := '00000000-0000-0000-0000-000000000018';
  v_bot19 uuid := '00000000-0000-0000-0000-000000000019';
  v_bot20 uuid := '00000000-0000-0000-0000-000000000020';

  -- League UUIDs
  v_league_office uuid := 'a0000000-0000-0000-0000-000000000001';
  v_league_sunday uuid := 'a0000000-0000-0000-0000-000000000002';
  v_league_champs uuid := 'a0000000-0000-0000-0000-000000000003';

BEGIN
  -- ═══════════════════════════════════════════════════════════════════════════
  -- SAFETY CHECK — only dev environment
  -- ═══════════════════════════════════════════════════════════════════════════
  v_env := current_setting('app.environment', true);
  IF v_env IS NULL OR v_env <> 'dev' THEN
    RAISE EXCEPTION 'dev_reset_data may only run in dev environment (current: %)', coalesce(v_env, 'NULL');
  END IF;

  IF p_mode NOT IN ('game', 'full') THEN
    RAISE EXCEPTION 'Invalid mode: %. Must be "game" or "full".', p_mode;
  END IF;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- CLEANUP — delete seed data in reverse FK order
  -- ═══════════════════════════════════════════════════════════════════════════

  DELETE FROM public.settlement_log
    WHERE fixture_id BETWEEN 900001 AND 900040;

  DELETE FROM public.picks
    WHERE fixture_id BETWEEN 900001 AND 900040;

  DELETE FROM public.league_members
    WHERE league_id IN (v_league_office, v_league_sunday, v_league_champs);

  DELETE FROM public.leagues
    WHERE id IN (v_league_office, v_league_sunday, v_league_champs);

  DELETE FROM public.fixtures
    WHERE id BETWEEN 900001 AND 900040;

  DELETE FROM public.gameweeks
    WHERE season = 2025 AND round_number BETWEEN 27 AND 30;

  -- Delete bot profiles and auth.users
  DELETE FROM public.profiles
    WHERE id IN (
      v_bot01, v_bot02, v_bot03, v_bot04, v_bot05,
      v_bot06, v_bot07, v_bot08, v_bot09, v_bot10,
      v_bot11, v_bot12, v_bot13, v_bot14, v_bot15,
      v_bot16, v_bot17, v_bot18, v_bot19, v_bot20
    );

  DELETE FROM auth.users
    WHERE id IN (
      v_bot01, v_bot02, v_bot03, v_bot04, v_bot05,
      v_bot06, v_bot07, v_bot08, v_bot09, v_bot10,
      v_bot11, v_bot12, v_bot13, v_bot14, v_bot15,
      v_bot16, v_bot17, v_bot18, v_bot19, v_bot20
    );

  -- Delete test user's profile (both modes clean it; "game" re-inserts it)
  DELETE FROM public.profiles WHERE id = p_caller_id;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RE-SEED: GAMEWEEKS
  -- ═══════════════════════════════════════════════════════════════════════════

  INSERT INTO public.gameweeks (season, round_number, name, deadline_at, is_current, is_finished)
  VALUES
    (2025, 27, 'Gameweek 27', now() - interval '5 days',   false, true),
    (2025, 28, 'Gameweek 28', now() - interval '2 days',   false, true),
    (2025, 29, 'Gameweek 29', now() + interval '2 hours',  true,  false),
    (2025, 30, 'Gameweek 30', now() + interval '9 days',   false, false)
  ON CONFLICT (season, round_number)
  DO UPDATE SET
    deadline_at  = EXCLUDED.deadline_at,
    is_current   = EXCLUDED.is_current,
    is_finished  = EXCLUDED.is_finished,
    updated_at   = now();

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RE-SEED: FIXTURES
  -- ═══════════════════════════════════════════════════════════════════════════

  -- GW27 (all FT)
  INSERT INTO public.fixtures
    (id, gameweek_id, home_team_id, home_team_name, home_team_short,
     away_team_id, away_team_name, away_team_short,
     home_team_logo, away_team_logo,
     kickoff_at, status, home_score, away_score, settled_at)
  VALUES
    (900001, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     42, 'Arsenal', 'ARS', 49, 'Chelsea', 'CHE',
     'https://media.api-sports.io/football/teams/42.png',
     'https://media.api-sports.io/football/teams/49.png',
     now() - interval '5 days 3 hours', 'FT', 2, 1, now() - interval '5 days'),

    (900002, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     66, 'Aston Villa', 'AVL', 35, 'Bournemouth', 'BOU',
     'https://media.api-sports.io/football/teams/66.png',
     'https://media.api-sports.io/football/teams/35.png',
     now() - interval '5 days 3 hours', 'FT', 1, 0, now() - interval '5 days'),

    (900003, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     51, 'Brighton', 'BHA', 55, 'Brentford', 'BRE',
     'https://media.api-sports.io/football/teams/51.png',
     'https://media.api-sports.io/football/teams/55.png',
     now() - interval '5 days 3 hours', 'FT', 2, 2, now() - interval '5 days'),

    (900004, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     52, 'Crystal Palace', 'CRY', 45, 'Everton', 'EVE',
     'https://media.api-sports.io/football/teams/52.png',
     'https://media.api-sports.io/football/teams/45.png',
     now() - interval '5 days 3 hours', 'FT', 3, 1, now() - interval '5 days'),

    (900005, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     36, 'Fulham', 'FUL', 57, 'Ipswich Town', 'IPS',
     'https://media.api-sports.io/football/teams/36.png',
     'https://media.api-sports.io/football/teams/57.png',
     now() - interval '5 days 3 hours', 'FT', 2, 0, now() - interval '5 days'),

    (900006, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     40, 'Liverpool', 'LIV', 46, 'Leicester', 'LEI',
     'https://media.api-sports.io/football/teams/40.png',
     'https://media.api-sports.io/football/teams/46.png',
     now() - interval '5 days 3 hours', 'FT', 4, 0, now() - interval '5 days'),

    (900007, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     50, 'Man City', 'MCI', 33, 'Man United', 'MUN',
     'https://media.api-sports.io/football/teams/50.png',
     'https://media.api-sports.io/football/teams/33.png',
     now() - interval '5 days 3 hours', 'FT', 1, 2, now() - interval '5 days'),

    (900008, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     34, 'Newcastle', 'NEW', 65, 'Nott. Forest', 'NFO',
     'https://media.api-sports.io/football/teams/34.png',
     'https://media.api-sports.io/football/teams/65.png',
     now() - interval '5 days 3 hours', 'FT', 0, 0, now() - interval '5 days'),

    (900009, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     47, 'Tottenham', 'TOT', 41, 'Southampton', 'SOU',
     'https://media.api-sports.io/football/teams/47.png',
     'https://media.api-sports.io/football/teams/41.png',
     now() - interval '5 days 3 hours', 'FT', 3, 0, now() - interval '5 days'),

    (900010, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=27),
     48, 'West Ham', 'WHU', 39, 'Wolves', 'WOL',
     'https://media.api-sports.io/football/teams/48.png',
     'https://media.api-sports.io/football/teams/39.png',
     now() - interval '5 days 3 hours', 'FT', 1, 1, now() - interval '5 days')
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status, home_score = EXCLUDED.home_score, away_score = EXCLUDED.away_score,
    settled_at = EXCLUDED.settled_at, kickoff_at = EXCLUDED.kickoff_at, updated_at = now();

  -- GW28 (all FT)
  INSERT INTO public.fixtures
    (id, gameweek_id, home_team_id, home_team_name, home_team_short,
     away_team_id, away_team_name, away_team_short,
     home_team_logo, away_team_logo,
     kickoff_at, status, home_score, away_score, settled_at)
  VALUES
    (900011, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     49, 'Chelsea', 'CHE', 42, 'Arsenal', 'ARS',
     'https://media.api-sports.io/football/teams/49.png',
     'https://media.api-sports.io/football/teams/42.png',
     now() - interval '2 days 3 hours', 'FT', 0, 1, now() - interval '2 days'),

    (900012, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     35, 'Bournemouth', 'BOU', 66, 'Aston Villa', 'AVL',
     'https://media.api-sports.io/football/teams/35.png',
     'https://media.api-sports.io/football/teams/66.png',
     now() - interval '2 days 3 hours', 'FT', 2, 1, now() - interval '2 days'),

    (900013, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     55, 'Brentford', 'BRE', 51, 'Brighton', 'BHA',
     'https://media.api-sports.io/football/teams/55.png',
     'https://media.api-sports.io/football/teams/51.png',
     now() - interval '2 days 3 hours', 'FT', 1, 3, now() - interval '2 days'),

    (900014, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     45, 'Everton', 'EVE', 52, 'Crystal Palace', 'CRY',
     'https://media.api-sports.io/football/teams/45.png',
     'https://media.api-sports.io/football/teams/52.png',
     now() - interval '2 days 3 hours', 'FT', 0, 2, now() - interval '2 days'),

    (900015, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     57, 'Ipswich Town', 'IPS', 36, 'Fulham', 'FUL',
     'https://media.api-sports.io/football/teams/57.png',
     'https://media.api-sports.io/football/teams/36.png',
     now() - interval '2 days 3 hours', 'FT', 1, 1, now() - interval '2 days'),

    (900016, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     46, 'Leicester', 'LEI', 40, 'Liverpool', 'LIV',
     'https://media.api-sports.io/football/teams/46.png',
     'https://media.api-sports.io/football/teams/40.png',
     now() - interval '2 days 3 hours', 'FT', 0, 3, now() - interval '2 days'),

    (900017, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     33, 'Man United', 'MUN', 50, 'Man City', 'MCI',
     'https://media.api-sports.io/football/teams/33.png',
     'https://media.api-sports.io/football/teams/50.png',
     now() - interval '2 days 3 hours', 'FT', 2, 2, now() - interval '2 days'),

    (900018, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     65, 'Nott. Forest', 'NFO', 34, 'Newcastle', 'NEW',
     'https://media.api-sports.io/football/teams/65.png',
     'https://media.api-sports.io/football/teams/34.png',
     now() - interval '2 days 3 hours', 'FT', 1, 0, now() - interval '2 days'),

    (900019, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     41, 'Southampton', 'SOU', 47, 'Tottenham', 'TOT',
     'https://media.api-sports.io/football/teams/41.png',
     'https://media.api-sports.io/football/teams/47.png',
     now() - interval '2 days 3 hours', 'FT', 0, 1, now() - interval '2 days'),

    (900020, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=28),
     39, 'Wolves', 'WOL', 48, 'West Ham', 'WHU',
     'https://media.api-sports.io/football/teams/39.png',
     'https://media.api-sports.io/football/teams/48.png',
     now() - interval '2 days 3 hours', 'FT', 2, 1, now() - interval '2 days')
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status, home_score = EXCLUDED.home_score, away_score = EXCLUDED.away_score,
    settled_at = EXCLUDED.settled_at, kickoff_at = EXCLUDED.kickoff_at, updated_at = now();

  -- GW29 (current, mixed statuses)
  INSERT INTO public.fixtures
    (id, gameweek_id, home_team_id, home_team_name, home_team_short,
     away_team_id, away_team_name, away_team_short,
     home_team_logo, away_team_logo,
     kickoff_at, status, home_score, away_score, settled_at)
  VALUES
    (900021, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     42, 'Arsenal', 'ARS', 35, 'Bournemouth', 'BOU',
     'https://media.api-sports.io/football/teams/42.png',
     'https://media.api-sports.io/football/teams/35.png',
     now() - interval '1 day', 'FT', 3, 0, now() - interval '21 hours'),

    (900022, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     40, 'Liverpool', 'LIV', 51, 'Brighton', 'BHA',
     'https://media.api-sports.io/football/teams/40.png',
     'https://media.api-sports.io/football/teams/51.png',
     now() - interval '1 day', 'FT', 2, 1, now() - interval '21 hours'),

    (900023, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     50, 'Man City', 'MCI', 55, 'Brentford', 'BRE',
     'https://media.api-sports.io/football/teams/50.png',
     'https://media.api-sports.io/football/teams/55.png',
     now() - interval '30 minutes', '1H', 1, 0, NULL),

    (900024, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     34, 'Newcastle', 'NEW', 49, 'Chelsea', 'CHE',
     'https://media.api-sports.io/football/teams/34.png',
     'https://media.api-sports.io/football/teams/49.png',
     now() - interval '75 minutes', '2H', 2, 1, NULL),

    (900025, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     66, 'Aston Villa', 'AVL', 52, 'Crystal Palace', 'CRY',
     'https://media.api-sports.io/football/teams/66.png',
     'https://media.api-sports.io/football/teams/52.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL),

    (900026, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     45, 'Everton', 'EVE', 36, 'Fulham', 'FUL',
     'https://media.api-sports.io/football/teams/45.png',
     'https://media.api-sports.io/football/teams/36.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL),

    (900027, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     57, 'Ipswich Town', 'IPS', 46, 'Leicester', 'LEI',
     'https://media.api-sports.io/football/teams/57.png',
     'https://media.api-sports.io/football/teams/46.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL),

    (900028, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     47, 'Tottenham', 'TOT', 33, 'Man United', 'MUN',
     'https://media.api-sports.io/football/teams/47.png',
     'https://media.api-sports.io/football/teams/33.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL),

    (900029, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     48, 'West Ham', 'WHU', 65, 'Nott. Forest', 'NFO',
     'https://media.api-sports.io/football/teams/48.png',
     'https://media.api-sports.io/football/teams/65.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL),

    (900030, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=29),
     39, 'Wolves', 'WOL', 41, 'Southampton', 'SOU',
     'https://media.api-sports.io/football/teams/39.png',
     'https://media.api-sports.io/football/teams/41.png',
     now() + interval '1 day', 'NS', NULL, NULL, NULL)
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status, home_score = EXCLUDED.home_score, away_score = EXCLUDED.away_score,
    settled_at = EXCLUDED.settled_at, kickoff_at = EXCLUDED.kickoff_at, updated_at = now();

  -- GW30 (future, all NS)
  INSERT INTO public.fixtures
    (id, gameweek_id, home_team_id, home_team_name, home_team_short,
     away_team_id, away_team_name, away_team_short,
     home_team_logo, away_team_logo,
     kickoff_at, status, home_score, away_score, settled_at)
  VALUES
    (900031, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     35, 'Bournemouth', 'BOU', 42, 'Arsenal', 'ARS',
     'https://media.api-sports.io/football/teams/35.png',
     'https://media.api-sports.io/football/teams/42.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900032, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     51, 'Brighton', 'BHA', 40, 'Liverpool', 'LIV',
     'https://media.api-sports.io/football/teams/51.png',
     'https://media.api-sports.io/football/teams/40.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900033, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     55, 'Brentford', 'BRE', 50, 'Man City', 'MCI',
     'https://media.api-sports.io/football/teams/55.png',
     'https://media.api-sports.io/football/teams/50.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900034, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     49, 'Chelsea', 'CHE', 34, 'Newcastle', 'NEW',
     'https://media.api-sports.io/football/teams/49.png',
     'https://media.api-sports.io/football/teams/34.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900035, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     52, 'Crystal Palace', 'CRY', 66, 'Aston Villa', 'AVL',
     'https://media.api-sports.io/football/teams/52.png',
     'https://media.api-sports.io/football/teams/66.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900036, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     36, 'Fulham', 'FUL', 45, 'Everton', 'EVE',
     'https://media.api-sports.io/football/teams/36.png',
     'https://media.api-sports.io/football/teams/45.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900037, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     46, 'Leicester', 'LEI', 57, 'Ipswich Town', 'IPS',
     'https://media.api-sports.io/football/teams/46.png',
     'https://media.api-sports.io/football/teams/57.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900038, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     33, 'Man United', 'MUN', 47, 'Tottenham', 'TOT',
     'https://media.api-sports.io/football/teams/33.png',
     'https://media.api-sports.io/football/teams/47.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900039, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     65, 'Nott. Forest', 'NFO', 48, 'West Ham', 'WHU',
     'https://media.api-sports.io/football/teams/65.png',
     'https://media.api-sports.io/football/teams/48.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL),

    (900040, (SELECT id FROM public.gameweeks WHERE season=2025 AND round_number=30),
     41, 'Southampton', 'SOU', 39, 'Wolves', 'WOL',
     'https://media.api-sports.io/football/teams/41.png',
     'https://media.api-sports.io/football/teams/39.png',
     now() + interval '9 days', 'NS', NULL, NULL, NULL)
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status, home_score = EXCLUDED.home_score, away_score = EXCLUDED.away_score,
    settled_at = EXCLUDED.settled_at, kickoff_at = EXCLUDED.kickoff_at, updated_at = now();

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RE-SEED: AUTH USERS (bots always, test user auth preserved via DO NOTHING)
  -- ═══════════════════════════════════════════════════════════════════════════

  INSERT INTO auth.users
    (id, instance_id, aud, role, email, encrypted_password,
     email_confirmed_at, created_at, updated_at,
     confirmation_token, recovery_token, email_change_token_new, email_change)
  VALUES
    (v_bot01, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot01@pyramid.test', crypt('bot-password-01', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot02, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot02@pyramid.test', crypt('bot-password-02', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot03, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot03@pyramid.test', crypt('bot-password-03', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot04, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot04@pyramid.test', crypt('bot-password-04', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot05, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot05@pyramid.test', crypt('bot-password-05', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot06, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot06@pyramid.test', crypt('bot-password-06', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot07, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot07@pyramid.test', crypt('bot-password-07', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot08, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot08@pyramid.test', crypt('bot-password-08', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot09, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot09@pyramid.test', crypt('bot-password-09', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot10, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot10@pyramid.test', crypt('bot-password-10', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot11, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot11@pyramid.test', crypt('bot-password-11', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot12, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot12@pyramid.test', crypt('bot-password-12', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot13, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot13@pyramid.test', crypt('bot-password-13', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot14, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot14@pyramid.test', crypt('bot-password-14', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot15, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot15@pyramid.test', crypt('bot-password-15', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot16, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot16@pyramid.test', crypt('bot-password-16', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot17, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot17@pyramid.test', crypt('bot-password-17', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot18, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot18@pyramid.test', crypt('bot-password-18', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot19, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot19@pyramid.test', crypt('bot-password-19', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
    (v_bot20, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot20@pyramid.test', crypt('bot-password-20', gen_salt('bf')), now(), now(), now(), '', '', '', '')
  ON CONFLICT (id) DO NOTHING;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RE-SEED: PROFILES
  -- ═══════════════════════════════════════════════════════════════════════════
  -- Bot profiles always inserted. on_auth_user_created trigger may have
  -- auto-created rows, so use ON CONFLICT DO UPDATE.

  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES
    (v_bot01, 'alexr',     'Alex R',     NULL),
    (v_bot02, 'samk',      'Sam K',      NULL),
    (v_bot03, 'jordanm',   'Jordan M',   NULL),
    (v_bot04, 'chrisp',    'Chris P',    NULL),
    (v_bot05, 'tomw',      'Tom W',      NULL),
    (v_bot06, 'priyas',    'Priya S',    NULL),
    (v_bot07, 'danh',      'Dan H',      NULL),
    (v_bot08, 'oliviac',   'Olivia C',   NULL),
    (v_bot09, 'meganl',    'Megan L',    NULL),
    (v_bot10, 'ryanb',     'Ryan B',     NULL),
    (v_bot11, 'sarahj',    'Sarah J',    NULL),
    (v_bot12, 'jamesf',    'James F',    NULL),
    (v_bot13, 'emmat',     'Emma T',     NULL),
    (v_bot14, 'willn',     'Will N',     NULL),
    (v_bot15, 'lucyg',     'Lucy G',     NULL),
    (v_bot16, 'harryd',    'Harry D',    NULL),
    (v_bot17, 'zoea',      'Zoe A',      NULL),
    (v_bot18, 'marcusv',   'Marcus V',   NULL),
    (v_bot19, 'katiee',    'Katie E',    NULL),
    (v_bot20, 'noahp',     'Noah P',     NULL)
  ON CONFLICT (id) DO UPDATE SET
    username     = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    updated_at   = now();

  -- Test user profile: only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (p_caller_id, 'jakecox', 'Jake Cox', NULL)
    ON CONFLICT (id) DO UPDATE SET
      username     = EXCLUDED.username,
      display_name = EXCLUDED.display_name,
      updated_at   = now();
  END IF;

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RE-SEED: LEAGUES, MEMBERS, PICKS
  -- ═══════════════════════════════════════════════════════════════════════════

  -- Fetch gameweek serial IDs
  SELECT id INTO v_gw27 FROM public.gameweeks WHERE season = 2025 AND round_number = 27;
  SELECT id INTO v_gw28 FROM public.gameweeks WHERE season = 2025 AND round_number = 28;
  SELECT id INTO v_gw29 FROM public.gameweeks WHERE season = 2025 AND round_number = 29;
  SELECT id INTO v_gw30 FROM public.gameweeks WHERE season = 2025 AND round_number = 30;

  -- ─── LEAGUES ──────────────────────────────────────────────────────────────

  -- Office Legends: 21 members, free, active
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_office, 'Office Legends', 'OFFICE1', 'free', 'active', p_caller_id, 2025, v_gw27, 30);

  -- Sunday Club: 16 members, free, active (started GW28)
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_sunday, 'Sunday Club', 'SUNDAY1', 'free', 'active', p_caller_id, 2025, v_gw28, 20);

  -- Champions: 15 members, free, completed (test user is the winner)
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_champs, 'Champions', 'CHAMP1', 'free', 'completed', p_caller_id, 2025, v_gw27, 20);

  -- ─── LEAGUE MEMBERS ──────────────────────────────────────────────────────

  -- Office Legends — bot active members
  INSERT INTO public.league_members (league_id, user_id, status) VALUES
    (v_league_office, v_bot01, 'active'),
    (v_league_office, v_bot04, 'active'),
    (v_league_office, v_bot05, 'active'),
    (v_league_office, v_bot06, 'active'),
    (v_league_office, v_bot07, 'active'),
    (v_league_office, v_bot08, 'active'),
    (v_league_office, v_bot09, 'active'),
    (v_league_office, v_bot10, 'active'),
    (v_league_office, v_bot11, 'active'),
    (v_league_office, v_bot12, 'active'),
    (v_league_office, v_bot13, 'active');

  -- Office Legends — eliminated in GW28
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_office, v_bot02, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot14, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot15, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot16, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot17, 'eliminated', now() - interval '2 days', v_gw28);

  -- Office Legends — eliminated in GW27
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_office, v_bot03, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot18, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot19, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot20, 'eliminated', now() - interval '5 days', v_gw27);

  -- Sunday Club — bot active members
  INSERT INTO public.league_members (league_id, user_id, status) VALUES
    (v_league_sunday, v_bot01, 'active'),
    (v_league_sunday, v_bot02, 'active'),
    (v_league_sunday, v_bot03, 'active'),
    (v_league_sunday, v_bot04, 'active'),
    (v_league_sunday, v_bot05, 'active'),
    (v_league_sunday, v_bot06, 'active'),
    (v_league_sunday, v_bot07, 'active'),
    (v_league_sunday, v_bot08, 'active'),
    (v_league_sunday, v_bot09, 'active'),
    (v_league_sunday, v_bot10, 'active'),
    (v_league_sunday, v_bot11, 'active'),
    (v_league_sunday, v_bot12, 'active'),
    (v_league_sunday, v_bot13, 'active'),
    (v_league_sunday, v_bot14, 'active'),
    (v_league_sunday, v_bot15, 'active');

  -- Champions — bot eliminated in GW27
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_champs, v_bot01, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot02, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot03, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot04, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot05, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot06, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot07, 'eliminated', now() - interval '5 days', v_gw27);

  -- Champions — bot eliminated in GW28
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_champs, v_bot08, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot09, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot10, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot11, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot12, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot13, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot14, 'eliminated', now() - interval '2 days', v_gw28);

  -- Test user league memberships — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.league_members (league_id, user_id, status) VALUES
      (v_league_office, p_caller_id, 'active'),
      (v_league_sunday, p_caller_id, 'active');

    INSERT INTO public.league_members (league_id, user_id, status)
    VALUES (v_league_champs, p_caller_id, 'winner');
  END IF;

  -- ─── PICKS ───────────────────────────────────────────────────────────────

  -- ─── OFFICE LEGENDS — GW27 (bot picks) ───────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_office, v_bot01, v_gw27, 900002, 66, 'Aston Villa',    true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot02, v_gw27, 900003, 51, 'Brighton',       true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot04, v_gw27, 900004, 52, 'Crystal Palace', true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot05, v_gw27, 900005, 36, 'Fulham',         true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot06, v_gw27, 900006, 40, 'Liverpool',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot07, v_gw27, 900007, 33, 'Man United',     true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot08, v_gw27, 900008, 34, 'Newcastle',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot09, v_gw27, 900009, 47, 'Tottenham',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot10, v_gw27, 900010, 48, 'West Ham',       true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot11, v_gw27, 900010, 39, 'Wolves',         true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot12, v_gw27, 900008, 65, 'Nott. Forest',   true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot13, v_gw27, 900003, 55, 'Brentford',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot14, v_gw27, 900001, 42, 'Arsenal',        true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot15, v_gw27, 900006, 40, 'Liverpool',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot16, v_gw27, 900009, 47, 'Tottenham',      true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot17, v_gw27, 900004, 52, 'Crystal Palace', true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    -- Eliminated bots
    (v_league_office, v_bot03, v_gw27, 900004, 45, 'Everton',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot18, v_gw27, 900005, 57, 'Ipswich Town',   true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot19, v_gw27, 900006, 46, 'Leicester',      true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot20, v_gw27, 900009, 41, 'Southampton',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');

  -- Test user Office Legends GW27 pick — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
      (v_league_office, p_caller_id, v_gw27, 900001, 42, 'Arsenal', true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');
  END IF;

  -- ─── OFFICE LEGENDS — GW28 (bot picks) ───────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_office, v_bot01, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot04, v_gw28, 900011, 42, 'Arsenal',        true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot05, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot06, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot07, v_gw28, 900018, 65, 'Nott. Forest',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot08, v_gw28, 900020, 39, 'Wolves',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot09, v_gw28, 900015, 57, 'Ipswich Town',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot10, v_gw28, 900015, 36, 'Fulham',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot11, v_gw28, 900017, 33, 'Man United',     true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot12, v_gw28, 900017, 50, 'Man City',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot13, v_gw28, 900019, 47, 'Tottenham',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- Eliminated in GW28
    (v_league_office, v_bot02, v_gw28, 900011, 49, 'Chelsea',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot14, v_gw28, 900012, 66, 'Aston Villa',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot15, v_gw28, 900013, 55, 'Brentford',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot16, v_gw28, 900016, 46, 'Leicester',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_office, v_bot17, v_gw28, 900018, 34, 'Newcastle',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- Test user Office Legends GW28 pick — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
      (v_league_office, p_caller_id, v_gw28, 900016, 40, 'Liverpool', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');
  END IF;

  -- ─── OFFICE LEGENDS — GW29 (bots only, NO test user pick) ────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_office, v_bot01, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot04, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot05, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    (v_league_office, v_bot06, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    (v_league_office, v_bot07, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot08, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot09, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    (v_league_office, v_bot10, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    (v_league_office, v_bot11, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot12, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_office, v_bot13, v_gw29, 900024, 49, 'Chelsea',    true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL);

  -- ─── SUNDAY CLUB — GW28 (bot picks) ──────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_sunday, v_bot01, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot02, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot03, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot04, v_gw28, 900020, 39, 'Wolves',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot05, v_gw28, 900018, 65, 'Nott. Forest',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot06, v_gw28, 900019, 47, 'Tottenham',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot07, v_gw28, 900016, 40, 'Liverpool',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot08, v_gw28, 900017, 33, 'Man United',     true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot09, v_gw28, 900017, 50, 'Man City',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot10, v_gw28, 900015, 36, 'Fulham',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot11, v_gw28, 900015, 57, 'Ipswich Town',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot12, v_gw28, 900011, 42, 'Arsenal',        true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot13, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot14, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_sunday, v_bot15, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- Test user Sunday Club GW28 pick — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
      (v_league_sunday, p_caller_id, v_gw28, 900011, 42, 'Arsenal', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');
  END IF;

  -- ─── SUNDAY CLUB — GW29 (bots only, NO test user pick) ───────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_sunday, v_bot01, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot02, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot03, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot04, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot05, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    (v_league_sunday, v_bot06, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    (v_league_sunday, v_bot07, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot08, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot09, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot10, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot11, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    (v_league_sunday, v_bot12, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    (v_league_sunday, v_bot13, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    (v_league_sunday, v_bot14, v_gw29, 900024, 49, 'Chelsea',    true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    (v_league_sunday, v_bot15, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL);

  -- ─── CHAMPIONS — GW27 (bot picks) ────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- Survived bots
    (v_league_champs, v_bot08, v_gw27, 900001, 42, 'Arsenal',        true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot09, v_gw27, 900002, 66, 'Aston Villa',    true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot10, v_gw27, 900005, 36, 'Fulham',         true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot11, v_gw27, 900006, 40, 'Liverpool',      true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot12, v_gw27, 900008, 34, 'Newcastle',      true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot13, v_gw27, 900010, 48, 'West Ham',       true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot14, v_gw27, 900007, 33, 'Man United',     true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    -- Eliminated bots
    (v_league_champs, v_bot01, v_gw27, 900001, 49, 'Chelsea',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot02, v_gw27, 900002, 35, 'Bournemouth',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot03, v_gw27, 900004, 45, 'Everton',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot04, v_gw27, 900005, 57, 'Ipswich Town',   true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot05, v_gw27, 900006, 46, 'Leicester',      true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot06, v_gw27, 900007, 50, 'Man City',       true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot07, v_gw27, 900009, 41, 'Southampton',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');

  -- Test user Champions GW27 pick — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
      (v_league_champs, p_caller_id, v_gw27, 900009, 47, 'Tottenham', true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');
  END IF;

  -- ─── CHAMPIONS — GW28 (bot picks) ────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    (v_league_champs, v_bot08, v_gw28, 900011, 49, 'Chelsea',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot09, v_gw28, 900013, 55, 'Brentford',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot10, v_gw28, 900014, 45, 'Everton',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot11, v_gw28, 900016, 46, 'Leicester',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot12, v_gw28, 900019, 41, 'Southampton',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot13, v_gw28, 900012, 66, 'Aston Villa',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    (v_league_champs, v_bot14, v_gw28, 900018, 34, 'Newcastle',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- Test user Champions GW28 pick (winner) — only in "game" mode
  IF p_mode = 'game' THEN
    INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
      (v_league_champs, p_caller_id, v_gw28, 900011, 42, 'Arsenal', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');
  END IF;

  -- No GW29 picks for Champions (league is completed)

  -- ═══════════════════════════════════════════════════════════════════════════
  -- RETURN RESULT
  -- ═══════════════════════════════════════════════════════════════════════════

  RETURN jsonb_build_object(
    'success', true,
    'mode', p_mode,
    'clearOnboarding', (p_mode = 'full')
  );

END;
$$;

-- Grant execute to service role (Edge Functions use service_role)
GRANT EXECUTE ON FUNCTION public.dev_reset_data(text, uuid) TO service_role;
