-- Dev seed data — do NOT run on staging or prod
-- Populates gameweeks and sample fixtures for local development and testing

-- Sample 2025/26 season gameweeks (GW1-3 for dev)
insert into public.gameweeks (season, round_number, name, deadline_at, is_current, is_finished) values
  (2025, 1,  'Gameweek 1',  '2025-08-16 11:30:00+00', false, true),
  (2025, 2,  'Gameweek 2',  '2025-08-23 11:30:00+00', false, true),
  (2025, 3,  'Gameweek 3',  '2025-08-30 11:30:00+00', false, false),
  (2025, 4,  'Gameweek 4',  '2025-09-13 11:30:00+00', true,  false)
on conflict (season, round_number) do nothing;

-- Note: real fixture data is loaded by the sync-fixtures Edge Function
-- This seed only provides enough structure for local testing
