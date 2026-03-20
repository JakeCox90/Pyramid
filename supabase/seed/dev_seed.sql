-- =============================================================================
-- Pyramid — Dev Seed Data
-- =============================================================================
-- Creates a realistic test environment with:
--   - 4 gameweeks (GW27-30) with rolling timestamps (never goes stale)
--   - 40 fixtures (10 per GW) covering all 20 PL teams
--   - 1 real test user + 20 bot users
--   - 3 leagues: Office Legends (21), Sunday Club (16), Champions (15, completed)
--   - Picks with correct FK references and consistent results
--
-- Safe to re-run (idempotent): uses ON CONFLICT and cleans up seed data first.
-- Do NOT run on staging or production.
-- =============================================================================

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 0. CLEAN SLATE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Delete in reverse FK order. Only touches seed-generated rows.

DELETE FROM public.settlement_log
  WHERE fixture_id BETWEEN 900001 AND 900040;

DELETE FROM public.picks
  WHERE fixture_id BETWEEN 900001 AND 900040;

DELETE FROM public.league_members
  WHERE league_id IN (
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000002'::uuid,
    'a0000000-0000-0000-0000-000000000003'::uuid
  );

DELETE FROM public.leagues
  WHERE id IN (
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000002'::uuid,
    'a0000000-0000-0000-0000-000000000003'::uuid
  );

DELETE FROM public.fixtures
  WHERE id BETWEEN 900001 AND 900040;

-- Test user + bot profiles and auth.users
DELETE FROM public.profiles
  WHERE id IN (
    '10000000-0000-0000-0000-000000000000'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000008'::uuid,
    '00000000-0000-0000-0000-000000000009'::uuid,
    '00000000-0000-0000-0000-000000000010'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,
    '00000000-0000-0000-0000-000000000012'::uuid,
    '00000000-0000-0000-0000-000000000013'::uuid,
    '00000000-0000-0000-0000-000000000014'::uuid,
    '00000000-0000-0000-0000-000000000015'::uuid,
    '00000000-0000-0000-0000-000000000016'::uuid,
    '00000000-0000-0000-0000-000000000017'::uuid,
    '00000000-0000-0000-0000-000000000018'::uuid,
    '00000000-0000-0000-0000-000000000019'::uuid,
    '00000000-0000-0000-0000-000000000020'::uuid
  );

DELETE FROM auth.users
  WHERE id IN (
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000008'::uuid,
    '00000000-0000-0000-0000-000000000009'::uuid,
    '00000000-0000-0000-0000-000000000010'::uuid,
    '00000000-0000-0000-0000-000000000011'::uuid,
    '00000000-0000-0000-0000-000000000012'::uuid,
    '00000000-0000-0000-0000-000000000013'::uuid,
    '00000000-0000-0000-0000-000000000014'::uuid,
    '00000000-0000-0000-0000-000000000015'::uuid,
    '00000000-0000-0000-0000-000000000016'::uuid,
    '00000000-0000-0000-0000-000000000017'::uuid,
    '00000000-0000-0000-0000-000000000018'::uuid,
    '00000000-0000-0000-0000-000000000019'::uuid,
    '00000000-0000-0000-0000-000000000020'::uuid
  );


-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. GAMEWEEKS
-- ═══════════════════════════════════════════════════════════════════════════════
-- GW27: finished (5 days ago)   GW28: finished (2 days ago)
-- GW29: current (deadline +2h)  GW30: future (+9 days)

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


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. FIXTURES — 10 per gameweek, all 20 PL teams each week
-- ═══════════════════════════════════════════════════════════════════════════════
-- Logo URL pattern: https://media.api-sports.io/football/teams/{id}.png
--
-- GW27 Results (all FT):
--   900001 Arsenal(42) 2-1 Chelsea(49)      — ARS win
--   900002 Villa(66) 1-0 Bournemouth(35)    — AVL win
--   900003 Brighton(51) 2-2 Brentford(55)   — Draw
--   900004 Palace(52) 3-1 Everton(45)       — CRY win
--   900005 Fulham(36) 2-0 Ipswich(57)       — FUL win
--   900006 Liverpool(40) 4-0 Leicester(46)  — LIV win
--   900007 Man City(50) 1-2 Man United(33)  — MUN win
--   900008 Newcastle(34) 0-0 Forest(65)     — Draw
--   900009 Spurs(47) 3-0 Southampton(41)    — TOT win
--   900010 West Ham(48) 1-1 Wolves(39)      — Draw
--
-- Surviving teams GW27: ARS,AVL,BHA,BRE,CRY,FUL,LIV,MUN,NEW,NFO,TOT,WHU,WOL (13)
-- Losing teams GW27: CHE,BOU,EVE,IPS,LEI,MCI,SOU (7)

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

-- GW28 Results (all FT):
--   900011 Chelsea(49) 0-1 Arsenal(42)        — ARS win
--   900012 Bournemouth(35) 2-1 Villa(66)      — BOU win
--   900013 Brentford(55) 1-3 Brighton(51)     — BHA win
--   900014 Everton(45) 0-2 Palace(52)         — CRY win
--   900015 Ipswich(57) 1-1 Fulham(36)         — Draw
--   900016 Leicester(46) 0-3 Liverpool(40)    — LIV win
--   900017 Man United(33) 2-2 Man City(50)    — Draw
--   900018 Forest(65) 1-0 Newcastle(34)       — NFO win
--   900019 Southampton(41) 0-1 Spurs(47)      — TOT win
--   900020 Wolves(39) 2-1 West Ham(48)        — WOL win
--
-- Surviving teams GW28: ARS,BOU,BHA,CRY,IPS,FUL,LIV,MUN,MCI,NFO,TOT,WOL (12)
-- Losing teams GW28: CHE,AVL,BRE,EVE,LEI,NEW,SOU,WHU (8)

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

-- GW29 (current, mixed statuses):
--   900021 Arsenal(42) 3-0 Bournemouth(35)     — FT, ARS win
--   900022 Liverpool(40) 2-1 Brighton(51)      — FT, LIV win
--   900023 Man City(50) 1-0 Brentford(55)      — 1H (live)
--   900024 Newcastle(34) 2-1 Chelsea(49)       — 2H (live)
--   900025-900030 — NS (kick off tomorrow)

INSERT INTO public.fixtures
  (id, gameweek_id, home_team_id, home_team_name, home_team_short,
   away_team_id, away_team_name, away_team_short,
   home_team_logo, away_team_logo,
   kickoff_at, status, home_score, away_score, settled_at)
VALUES
  -- FT fixtures (kicked off yesterday)
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

  -- Live fixtures
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

  -- NS fixtures (kick off tomorrow)
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

-- GW30 (future, all NS, +9 days)
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


-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. AUTH USERS (test user + 20 bots)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Minimal auth.users rows. The on_auth_user_created trigger auto-creates
-- profiles, but we override them in section 4 via ON CONFLICT DO UPDATE.
-- Test user uses ON CONFLICT DO NOTHING to preserve existing auth if signed up.

INSERT INTO auth.users
  (id, instance_id, aud, role, email, encrypted_password,
   email_confirmed_at, created_at, updated_at,
   confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
  ('10000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'jakecox@hotmail.co.uk', crypt('test-password', gen_salt('bf')), now(), now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.users
  (id, instance_id, aud, role, email, encrypted_password,
   email_confirmed_at, created_at, updated_at,
   confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot01@pyramid.test', crypt('bot-password-01', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot02@pyramid.test', crypt('bot-password-02', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot03@pyramid.test', crypt('bot-password-03', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot04@pyramid.test', crypt('bot-password-04', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot05@pyramid.test', crypt('bot-password-05', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot06@pyramid.test', crypt('bot-password-06', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot07@pyramid.test', crypt('bot-password-07', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot08@pyramid.test', crypt('bot-password-08', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot09@pyramid.test', crypt('bot-password-09', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot10@pyramid.test', crypt('bot-password-10', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot11@pyramid.test', crypt('bot-password-11', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot12@pyramid.test', crypt('bot-password-12', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot13@pyramid.test', crypt('bot-password-13', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot14@pyramid.test', crypt('bot-password-14', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot15@pyramid.test', crypt('bot-password-15', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot16@pyramid.test', crypt('bot-password-16', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot17@pyramid.test', crypt('bot-password-17', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot18@pyramid.test', crypt('bot-password-18', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot19@pyramid.test', crypt('bot-password-19', gen_salt('bf')), now(), now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bot20@pyramid.test', crypt('bot-password-20', gen_salt('bf')), now(), now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. PROFILES (test user + 20 bots)
-- ═══════════════════════════════════════════════════════════════════════════════
-- ON CONFLICT DO UPDATE handles the on_auth_user_created trigger race.

INSERT INTO public.profiles (id, username, display_name, avatar_url)
VALUES
  ('10000000-0000-0000-0000-000000000000', 'jakecox',   'Jake Cox',   NULL),
  ('00000000-0000-0000-0000-000000000001', 'alexr',     'Alex R',     NULL),
  ('00000000-0000-0000-0000-000000000002', 'samk',      'Sam K',      NULL),
  ('00000000-0000-0000-0000-000000000003', 'jordanm',   'Jordan M',   NULL),
  ('00000000-0000-0000-0000-000000000004', 'chrisp',    'Chris P',    NULL),
  ('00000000-0000-0000-0000-000000000005', 'tomw',      'Tom W',      NULL),
  ('00000000-0000-0000-0000-000000000006', 'priyas',    'Priya S',    NULL),
  ('00000000-0000-0000-0000-000000000007', 'danh',      'Dan H',      NULL),
  ('00000000-0000-0000-0000-000000000008', 'oliviac',   'Olivia C',   NULL),
  ('00000000-0000-0000-0000-000000000009', 'meganl',    'Megan L',    NULL),
  ('00000000-0000-0000-0000-000000000010', 'ryanb',     'Ryan B',     NULL),
  ('00000000-0000-0000-0000-000000000011', 'sarahj',    'Sarah J',    NULL),
  ('00000000-0000-0000-0000-000000000012', 'jamesf',    'James F',    NULL),
  ('00000000-0000-0000-0000-000000000013', 'emmat',     'Emma T',     NULL),
  ('00000000-0000-0000-0000-000000000014', 'willn',     'Will N',     NULL),
  ('00000000-0000-0000-0000-000000000015', 'lucyg',     'Lucy G',     NULL),
  ('00000000-0000-0000-0000-000000000016', 'harryd',    'Harry D',    NULL),
  ('00000000-0000-0000-0000-000000000017', 'zoea',      'Zoe A',      NULL),
  ('00000000-0000-0000-0000-000000000018', 'marcusv',   'Marcus V',   NULL),
  ('00000000-0000-0000-0000-000000000019', 'katiee',    'Katie E',    NULL),
  ('00000000-0000-0000-0000-000000000020', 'noahp',     'Noah P',     NULL)
ON CONFLICT (id) DO UPDATE SET
  username     = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  updated_at   = now();


-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. LEAGUES, MEMBERS, AND PICKS (DO block for gameweek ID variables)
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  -- Gameweek serial IDs
  v_gw27 integer;
  v_gw28 integer;
  v_gw29 integer;
  v_gw30 integer;

  -- User UUIDs
  v_test  uuid := '10000000-0000-0000-0000-000000000000';
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

  -- League UUIDs (deterministic)
  v_league_office uuid := 'a0000000-0000-0000-0000-000000000001';
  v_league_sunday uuid := 'a0000000-0000-0000-0000-000000000002';
  v_league_champs uuid := 'a0000000-0000-0000-0000-000000000003';

BEGIN
  -- ─── Fetch gameweek serial IDs ─────────────────────────────────────────────
  SELECT id INTO v_gw27 FROM public.gameweeks WHERE season = 2025 AND round_number = 27;
  SELECT id INTO v_gw28 FROM public.gameweeks WHERE season = 2025 AND round_number = 28;
  SELECT id INTO v_gw29 FROM public.gameweeks WHERE season = 2025 AND round_number = 29;
  SELECT id INTO v_gw30 FROM public.gameweeks WHERE season = 2025 AND round_number = 30;

  -- ═════════════════════════════════════════════════════════════════════════════
  -- LEAGUES
  -- ═════════════════════════════════════════════════════════════════════════════

  -- Office Legends: 21 members, free, active
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_office, 'Office Legends', 'OFFICE1', 'free', 'active', v_test, 2025, v_gw27, 30);

  -- Sunday Club: 16 members, free, active (started GW28)
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_sunday, 'Sunday Club', 'SUNDAY1', 'free', 'active', v_test, 2025, v_gw28, 20);

  -- Champions: 15 members, free, completed (test user is the winner)
  INSERT INTO public.leagues (id, name, join_code, type, status, created_by, season, start_gameweek_id, max_players)
  VALUES (v_league_champs, 'Champions', 'CHAMP1', 'free', 'completed', v_test, 2025, v_gw27, 20);


  -- ═════════════════════════════════════════════════════════════════════════════
  -- LEAGUE MEMBERS
  -- ═════════════════════════════════════════════════════════════════════════════

  -- ─── Office Legends (21 members) ───────────────────────────────────────────
  -- Active (12): test, bot01, bot04-bot13
  INSERT INTO public.league_members (league_id, user_id, status) VALUES
    (v_league_office, v_test,  'active'),
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

  -- Eliminated in GW28 (5): bot02, bot14, bot15, bot16, bot17
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_office, v_bot02, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot14, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot15, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot16, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_office, v_bot17, 'eliminated', now() - interval '2 days', v_gw28);

  -- Eliminated in GW27 (4): bot03, bot18, bot19, bot20
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_office, v_bot03, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot18, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot19, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_office, v_bot20, 'eliminated', now() - interval '5 days', v_gw27);

  -- ─── Sunday Club (16 members, all active) ─────────────────────────────────
  INSERT INTO public.league_members (league_id, user_id, status) VALUES
    (v_league_sunday, v_test,  'active'),
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

  -- ─── Champions (15 members) ───────────────────────────────────────────────
  -- Winner: test user
  INSERT INTO public.league_members (league_id, user_id, status)
  VALUES (v_league_champs, v_test, 'winner');

  -- Eliminated in GW27 (7): bot01-bot07
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_champs, v_bot01, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot02, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot03, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot04, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot05, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot06, 'eliminated', now() - interval '5 days', v_gw27),
    (v_league_champs, v_bot07, 'eliminated', now() - interval '5 days', v_gw27);

  -- Eliminated in GW28 (7): bot08-bot14
  INSERT INTO public.league_members (league_id, user_id, status, eliminated_at, eliminated_in_gameweek_id) VALUES
    (v_league_champs, v_bot08, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot09, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot10, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot11, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot12, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot13, 'eliminated', now() - interval '2 days', v_gw28),
    (v_league_champs, v_bot14, 'eliminated', now() - interval '2 days', v_gw28);


  -- ═════════════════════════════════════════════════════════════════════════════
  -- PICKS
  -- ═════════════════════════════════════════════════════════════════════════════
  -- Key rules enforced:
  --   - Each pick references a valid fixture_id for its gameweek
  --   - survived = team won or drew; eliminated = team lost
  --   - No member reuses a team across GWs in the same league
  --   - Test user has NO GW29 picks (can submit in-app)
  --   - GW29 bot picks only on FT/live fixtures (locked), not NS
  --   - Multiple members CAN pick the same team in a GW (no DB constraint)
  --
  -- GW27 surviving teams: ARS(42), AVL(66), BHA(51), BRE(55), CRY(52),
  --   FUL(36), LIV(40), MUN(33), NEW(34), NFO(65), TOT(47), WHU(48), WOL(39)
  -- GW27 losing teams: CHE(49), BOU(35), EVE(45), IPS(57), LEI(46), MCI(50), SOU(41)
  --
  -- GW28 surviving teams: ARS(42), BOU(35), BHA(51), CRY(52), IPS(57),
  --   FUL(36), LIV(40), MUN(33), MCI(50), NFO(65), TOT(47), WOL(39)
  -- GW28 losing teams: CHE(49), AVL(66), BRE(55), EVE(45), LEI(46), NEW(34), SOU(41), WHU(48)

  -- ─────────────────────────────────────────────────────────────────────────────
  -- OFFICE LEGENDS — GW27 (21 picks: 17 survived, 4 eliminated)
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- Survived (17) — each picks a team that won or drew
    (v_league_office, v_test,  v_gw27, 900001, 42, 'Arsenal',        true, 'survived', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
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
    -- Eliminated (4) — picked teams that lost
    (v_league_office, v_bot03, v_gw27, 900004, 45, 'Everton',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot18, v_gw27, 900005, 57, 'Ipswich Town',   true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot19, v_gw27, 900006, 46, 'Leicester',      true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_office, v_bot20, v_gw27, 900009, 41, 'Southampton',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');

  -- ─────────────────────────────────────────────────────────────────────────────
  -- OFFICE LEGENDS — GW28 (17 picks: 12 survived, 5 eliminated)
  -- Only members who survived GW27. No team reuse per member.
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- Survived (12 active members)
    -- test: GW27=ARS(42) -> pick LIV(40) won
    (v_league_office, v_test,  v_gw28, 900016, 40, 'Liverpool',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot01: GW27=AVL(66) -> pick BOU(35) won
    (v_league_office, v_bot01, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot04: GW27=CRY(52) -> pick ARS(42) won
    (v_league_office, v_bot04, v_gw28, 900011, 42, 'Arsenal',        true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot05: GW27=FUL(36) -> pick BHA(51) won
    (v_league_office, v_bot05, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot06: GW27=LIV(40) -> pick CRY(52) won
    (v_league_office, v_bot06, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot07: GW27=MUN(33) -> pick NFO(65) won
    (v_league_office, v_bot07, v_gw28, 900018, 65, 'Nott. Forest',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot08: GW27=NEW(34) -> pick WOL(39) won
    (v_league_office, v_bot08, v_gw28, 900020, 39, 'Wolves',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot09: GW27=TOT(47) -> pick IPS(57) drew
    (v_league_office, v_bot09, v_gw28, 900015, 57, 'Ipswich Town',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot10: GW27=WHU(48) -> pick FUL(36) drew
    (v_league_office, v_bot10, v_gw28, 900015, 36, 'Fulham',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot11: GW27=WOL(39) -> pick MUN(33) drew
    (v_league_office, v_bot11, v_gw28, 900017, 33, 'Man United',     true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot12: GW27=NFO(65) -> pick MCI(50) drew
    (v_league_office, v_bot12, v_gw28, 900017, 50, 'Man City',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot13: GW27=BRE(55) -> pick TOT(47) won
    (v_league_office, v_bot13, v_gw28, 900019, 47, 'Tottenham',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- Eliminated in GW28 (5) — picked teams that lost
    -- bot02: GW27=BHA(51) -> pick CHE(49) lost
    (v_league_office, v_bot02, v_gw28, 900011, 49, 'Chelsea',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot14: GW27=ARS(42) -> pick AVL(66) lost
    (v_league_office, v_bot14, v_gw28, 900012, 66, 'Aston Villa',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot15: GW27=LIV(40) -> pick BRE(55) lost
    (v_league_office, v_bot15, v_gw28, 900013, 55, 'Brentford',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot16: GW27=TOT(47) -> pick LEI(46) lost
    (v_league_office, v_bot16, v_gw28, 900016, 46, 'Leicester',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot17: GW27=CRY(52) -> pick NEW(34) lost
    (v_league_office, v_bot17, v_gw28, 900018, 34, 'Newcastle',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- ─────────────────────────────────────────────────────────────────────────────
  -- OFFICE LEGENDS — GW29 (11 active bots only, NO test user pick)
  -- Only on FT/live fixtures (900021-900024). No NS fixtures.
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- bot01: used AVL(66), BOU(35) -> pick ARS(42) FT survived
    (v_league_office, v_bot01, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot04: used CRY(52), ARS(42) -> pick LIV(40) FT survived
    (v_league_office, v_bot04, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot05: used FUL(36), BHA(51) -> pick MCI(50) live pending
    (v_league_office, v_bot05, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    -- bot06: used LIV(40), CRY(52) -> pick NEW(34) live pending
    (v_league_office, v_bot06, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    -- bot07: used MUN(33), NFO(65) -> pick ARS(42) FT survived
    (v_league_office, v_bot07, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot08: used NEW(34), WOL(39) -> pick LIV(40) FT survived
    (v_league_office, v_bot08, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot09: used TOT(47), IPS(57) -> pick MCI(50) live pending
    (v_league_office, v_bot09, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    -- bot10: used WHU(48), FUL(36) -> pick NEW(34) live pending
    (v_league_office, v_bot10, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    -- bot11: used WOL(39), MUN(33) -> pick LIV(40) FT survived
    (v_league_office, v_bot11, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot12: used NFO(65), MCI(50) -> pick ARS(42) FT survived
    (v_league_office, v_bot12, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot13: used BRE(55), TOT(47) -> pick CHE(49) live pending
    (v_league_office, v_bot13, v_gw29, 900024, 49, 'Chelsea',    true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL);


  -- ─────────────────────────────────────────────────────────────────────────────
  -- SUNDAY CLUB — GW28 (16 picks, all survived — first GW for this league)
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- test: GW27=LIV(40) -> pick ARS(42) won
    (v_league_sunday, v_test,  v_gw28, 900011, 42, 'Arsenal',        true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot01: GW27=ARS(42) -> pick BOU(35) won
    (v_league_sunday, v_bot01, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot02: GW27=AVL(66) -> pick BHA(51) won
    (v_league_sunday, v_bot02, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot03: GW27=BHA(51) -> pick CRY(52) won
    (v_league_sunday, v_bot03, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot04: GW27=BRE(55) -> pick WOL(39) won
    (v_league_sunday, v_bot04, v_gw28, 900020, 39, 'Wolves',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot05: GW27=CRY(52) -> pick NFO(65) won
    (v_league_sunday, v_bot05, v_gw28, 900018, 65, 'Nott. Forest',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot06: GW27=FUL(36) -> pick TOT(47) won
    (v_league_sunday, v_bot06, v_gw28, 900019, 47, 'Tottenham',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot07: GW27=MUN(33) -> pick LIV(40) won
    (v_league_sunday, v_bot07, v_gw28, 900016, 40, 'Liverpool',      true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot08: GW27=NEW(34) -> pick MUN(33) drew
    (v_league_sunday, v_bot08, v_gw28, 900017, 33, 'Man United',     true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot09: GW27=NFO(65) -> pick MCI(50) drew
    (v_league_sunday, v_bot09, v_gw28, 900017, 50, 'Man City',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot10: GW27=TOT(47) -> pick FUL(36) drew
    (v_league_sunday, v_bot10, v_gw28, 900015, 36, 'Fulham',         true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot11: GW27=WHU(48) -> pick IPS(57) drew
    (v_league_sunday, v_bot11, v_gw28, 900015, 57, 'Ipswich Town',   true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot12: GW27=WOL(39) -> pick ARS(42) won
    (v_league_sunday, v_bot12, v_gw28, 900011, 42, 'Arsenal',        true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot13: GW27=ARS(42) -> pick BOU(35) won
    (v_league_sunday, v_bot13, v_gw28, 900012, 35, 'Bournemouth',    true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot14: GW27=LIV(40) -> pick CRY(52) won
    (v_league_sunday, v_bot14, v_gw28, 900014, 52, 'Crystal Palace', true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot15: GW27=CRY(52) -> pick BHA(51) won
    (v_league_sunday, v_bot15, v_gw28, 900013, 51, 'Brighton',       true, 'survived', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- ─────────────────────────────────────────────────────────────────────────────
  -- SUNDAY CLUB — GW29 (15 bots only, NO test user pick)
  -- Only FT/live fixtures. No NS.
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- bot01: used ARS(42), BOU(35) -> pick LIV(40) FT survived
    (v_league_sunday, v_bot01, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot02: used AVL(66), BHA(51) -> pick ARS(42) FT survived
    (v_league_sunday, v_bot02, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot03: used BHA(51), CRY(52) -> pick ARS(42) FT survived
    (v_league_sunday, v_bot03, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot04: used BRE(55), WOL(39) -> pick LIV(40) FT survived
    (v_league_sunday, v_bot04, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot05: used CRY(52), NFO(65) -> pick MCI(50) live pending
    (v_league_sunday, v_bot05, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    -- bot06: used FUL(36), TOT(47) -> pick NEW(34) live pending
    (v_league_sunday, v_bot06, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    -- bot07: used MUN(33), LIV(40) -> pick ARS(42) FT survived
    (v_league_sunday, v_bot07, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot08: used NEW(34), MUN(33) -> pick LIV(40) FT survived
    (v_league_sunday, v_bot08, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot09: used NFO(65), MCI(50) -> pick ARS(42) FT survived
    (v_league_sunday, v_bot09, v_gw29, 900021, 42, 'Arsenal',    true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot10: used TOT(47), FUL(36) -> pick LIV(40) FT survived
    (v_league_sunday, v_bot10, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot11: used WHU(48), IPS(57) -> pick MCI(50) live pending
    (v_league_sunday, v_bot11, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL),
    -- bot12: used WOL(39), ARS(42) -> pick LIV(40) FT survived
    (v_league_sunday, v_bot12, v_gw29, 900022, 40, 'Liverpool',  true, 'survived', now()-interval '26 hours', now()-interval '1 day', now()-interval '21 hours'),
    -- bot13: used ARS(42), BOU(35) -> pick NEW(34) live pending
    (v_league_sunday, v_bot13, v_gw29, 900024, 34, 'Newcastle',  true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    -- bot14: used LIV(40), CRY(52) -> pick CHE(49) live pending
    (v_league_sunday, v_bot14, v_gw29, 900024, 49, 'Chelsea',    true, 'pending',  now()-interval '26 hours', now()-interval '75 minutes', NULL),
    -- bot15: used CRY(52), BHA(51) -> pick MCI(50) live pending
    (v_league_sunday, v_bot15, v_gw29, 900023, 50, 'Man City',   true, 'pending',  now()-interval '26 hours', now()-interval '30 minutes', NULL);


  -- ─────────────────────────────────────────────────────────────────────────────
  -- CHAMPIONS — GW27 (15 picks: 8 survived, 7 eliminated)
  -- League is completed. Test user is the winner.
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- Survived (8): test + bot08-bot14
    (v_league_champs, v_test,  v_gw27, 900009, 47, 'Tottenham',      true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot08, v_gw27, 900001, 42, 'Arsenal',        true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot09, v_gw27, 900002, 66, 'Aston Villa',    true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot10, v_gw27, 900005, 36, 'Fulham',         true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot11, v_gw27, 900006, 40, 'Liverpool',      true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot12, v_gw27, 900008, 34, 'Newcastle',      true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot13, v_gw27, 900010, 48, 'West Ham',       true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot14, v_gw27, 900007, 33, 'Man United',     true, 'survived',   now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    -- Eliminated (7): bot01-bot07 — picked losing teams
    (v_league_champs, v_bot01, v_gw27, 900001, 49, 'Chelsea',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot02, v_gw27, 900002, 35, 'Bournemouth',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot03, v_gw27, 900004, 45, 'Everton',        true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot04, v_gw27, 900005, 57, 'Ipswich Town',   true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot05, v_gw27, 900006, 46, 'Leicester',      true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot06, v_gw27, 900007, 50, 'Man City',       true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days'),
    (v_league_champs, v_bot07, v_gw27, 900009, 41, 'Southampton',    true, 'eliminated', now()-interval '6 days', now()-interval '5 days 3 hours', now()-interval '5 days');

  -- ─────────────────────────────────────────────────────────────────────────────
  -- CHAMPIONS — GW28 (8 picks: 1 survived [test=winner], 7 eliminated)
  -- ─────────────────────────────────────────────────────────────────────────────
  INSERT INTO public.picks (league_id, user_id, gameweek_id, fixture_id, team_id, team_name, is_locked, result, submitted_at, locked_at, settled_at) VALUES
    -- test: GW27=TOT(47) -> pick ARS(42) won = survived (WINNER)
    (v_league_champs, v_test,  v_gw28, 900011, 42, 'Arsenal',        true, 'survived',   now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot08: GW27=ARS(42) -> pick CHE(49) lost = eliminated
    (v_league_champs, v_bot08, v_gw28, 900011, 49, 'Chelsea',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot09: GW27=AVL(66) -> pick BRE(55) lost = eliminated
    (v_league_champs, v_bot09, v_gw28, 900013, 55, 'Brentford',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot10: GW27=FUL(36) -> pick EVE(45) lost = eliminated
    (v_league_champs, v_bot10, v_gw28, 900014, 45, 'Everton',        true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot11: GW27=LIV(40) -> pick LEI(46) lost = eliminated
    (v_league_champs, v_bot11, v_gw28, 900016, 46, 'Leicester',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot12: GW27=NEW(34) -> pick SOU(41) lost = eliminated
    (v_league_champs, v_bot12, v_gw28, 900019, 41, 'Southampton',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot13: GW27=WHU(48) -> pick AVL(66) lost = eliminated
    (v_league_champs, v_bot13, v_gw28, 900012, 66, 'Aston Villa',    true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days'),
    -- bot14: GW27=MUN(33) -> pick NEW(34) lost = eliminated
    (v_league_champs, v_bot14, v_gw28, 900018, 34, 'Newcastle',      true, 'eliminated', now()-interval '3 days', now()-interval '2 days 3 hours', now()-interval '2 days');

  -- No GW29 picks for Champions (league is completed)

END $$;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. VERIFICATION QUERIES
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '=== GAMEWEEKS ===' AS section;
SELECT id, name, is_current, is_finished,
       deadline_at::text
FROM public.gameweeks
WHERE season = 2025 AND round_number BETWEEN 27 AND 30
ORDER BY round_number;

SELECT '=== FIXTURES PER GAMEWEEK ===' AS section;
SELECT g.name,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE f.status = 'FT') AS ft,
       COUNT(*) FILTER (WHERE f.status IN ('1H','2H','HT')) AS live,
       COUNT(*) FILTER (WHERE f.status = 'NS') AS ns
FROM public.fixtures f
JOIN public.gameweeks g ON g.id = f.gameweek_id
WHERE f.id BETWEEN 900001 AND 900040
GROUP BY g.name, g.round_number
ORDER BY g.round_number;

SELECT '=== PROFILES (expect 21) ===' AS section;
SELECT COUNT(*) AS profile_count
FROM public.profiles
WHERE id = '10000000-0000-0000-0000-000000000000'
   OR id::text LIKE '00000000-0000-0000-0000-0000000000%';

SELECT '=== LEAGUE MEMBERSHIP ===' AS section;
SELECT l.name, l.status AS league_status,
       COUNT(lm.id) AS members,
       COUNT(*) FILTER (WHERE lm.status = 'active') AS active,
       COUNT(*) FILTER (WHERE lm.status = 'eliminated') AS eliminated,
       COUNT(*) FILTER (WHERE lm.status = 'winner') AS winners
FROM public.leagues l
JOIN public.league_members lm ON lm.league_id = l.id
WHERE l.id IN (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'a0000000-0000-0000-0000-000000000002'::uuid,
  'a0000000-0000-0000-0000-000000000003'::uuid
)
GROUP BY l.name, l.status
ORDER BY l.name;

SELECT '=== PICKS PER LEAGUE PER GAMEWEEK ===' AS section;
SELECT l.name AS league, g.name AS gameweek,
       COUNT(*) AS total_picks,
       COUNT(*) FILTER (WHERE p.result = 'survived') AS survived,
       COUNT(*) FILTER (WHERE p.result = 'eliminated') AS eliminated,
       COUNT(*) FILTER (WHERE p.result = 'pending') AS pending
FROM public.picks p
JOIN public.leagues l ON l.id = p.league_id
JOIN public.gameweeks g ON g.id = p.gameweek_id
WHERE l.id IN (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'a0000000-0000-0000-0000-000000000002'::uuid,
  'a0000000-0000-0000-0000-000000000003'::uuid
)
GROUP BY l.name, g.name, g.round_number
ORDER BY l.name, g.round_number;

SELECT '=== TEST USER GW29 PICKS (expect 0) ===' AS section;
SELECT COUNT(*) AS test_user_gw29_picks
FROM public.picks p
JOIN public.gameweeks g ON g.id = p.gameweek_id
WHERE p.user_id = '10000000-0000-0000-0000-000000000000'
  AND g.season = 2025 AND g.round_number = 29;

SELECT '=== PICK RESULT CONSISTENCY (expect PASS) ===' AS section;
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS: All pick results match fixture outcomes'
    ELSE 'FAIL: ' || COUNT(*) || ' picks have inconsistent results'
  END AS consistency_check
FROM public.picks p
JOIN public.fixtures f ON f.id = p.fixture_id
WHERE p.league_id IN (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'a0000000-0000-0000-0000-000000000002'::uuid,
  'a0000000-0000-0000-0000-000000000003'::uuid
)
AND f.status = 'FT'
AND p.result IN ('survived', 'eliminated')
AND (
  (p.result = 'survived' AND (
    (p.team_id = f.home_team_id AND f.home_score < f.away_score) OR
    (p.team_id = f.away_team_id AND f.away_score < f.home_score)
  ))
  OR
  (p.result = 'eliminated' AND (
    (p.team_id = f.home_team_id AND f.home_score >= f.away_score) OR
    (p.team_id = f.away_team_id AND f.away_score >= f.home_score)
  ))
);

SELECT '=== NO-REPEAT TEAM CHECK (expect 0 violations) ===' AS section;
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN 'PASS: No team reuse within any league per user'
    ELSE 'FAIL: ' || COUNT(*) || ' team reuse violations'
  END AS no_repeat_check
FROM (
  SELECT p.league_id, p.user_id, p.team_id, COUNT(*) AS times_used
  FROM public.picks p
  WHERE p.league_id IN (
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000002'::uuid,
    'a0000000-0000-0000-0000-000000000003'::uuid
  )
  GROUP BY p.league_id, p.user_id, p.team_id
  HAVING COUNT(*) > 1
) dupes;

COMMIT;
