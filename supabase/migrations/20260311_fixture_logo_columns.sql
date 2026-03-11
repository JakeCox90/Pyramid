-- Add team logo URL columns to fixtures table.
-- Logo URLs come from API-Football (e.g. https://media.api-sports.io/football/teams/42.png).

ALTER TABLE public.fixtures
  ADD COLUMN IF NOT EXISTS home_team_logo text,
  ADD COLUMN IF NOT EXISTS away_team_logo text;

COMMENT ON COLUMN public.fixtures.home_team_logo IS 'URL to home team badge from API-Football';
COMMENT ON COLUMN public.fixtures.away_team_logo IS 'URL to away team badge from API-Football';

-- Backfill from raw_api_response where available
UPDATE public.fixtures
SET
  home_team_logo = raw_api_response->'teams'->'home'->>'logo',
  away_team_logo = raw_api_response->'teams'->'away'->>'logo'
WHERE raw_api_response IS NOT NULL
  AND home_team_logo IS NULL;
