-- Add round_number to the used_teams view by joining gameweeks.
-- This lets the iOS client show "Used GW3" on previously picked teams.

create or replace view public.used_teams as
  select
    p.league_id,
    p.user_id,
    p.team_id,
    p.team_name,
    p.gameweek_id,
    g.round_number,
    p.result
  from public.picks p
  join public.gameweeks g on g.id = p.gameweek_id
  where p.result != 'void';

comment on view public.used_teams is 'Teams already used by each player in each league. Voided picks excluded. Includes round_number from gameweeks.';
