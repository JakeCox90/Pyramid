-- Add venue column to fixtures table.
-- Venue name comes from API-Football (fixture.venue.name).

ALTER TABLE public.fixtures
  ADD COLUMN IF NOT EXISTS venue text;

COMMENT ON COLUMN public.fixtures.venue IS 'Stadium name from API-Football fixture.venue.name';

-- Backfill from raw_api_response where available
UPDATE public.fixtures
SET venue = raw_api_response->'fixture'->'venue'->>'name'
WHERE raw_api_response IS NOT NULL
  AND venue IS NULL;
