-- Add round_number to used_teams view by joining to gameweeks
CREATE OR REPLACE VIEW used_teams AS
SELECT
  p.league_id,
  p.user_id,
  p.team_id,
  p.team_name,
  p.gameweek_id,
  p.result,
  g.round_number
FROM picks p
JOIN gameweeks g ON g.id = p.gameweek_id
WHERE p.result <> 'void'::pick_result;
