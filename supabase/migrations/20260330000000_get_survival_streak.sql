-- Computes the survival streak for a user in a league.
-- Returns the count of consecutive 'survived' picks walking backwards
-- from the most recent settled gameweek. Used by get-league-stats edge function.
-- ROLLBACK: DROP FUNCTION IF EXISTS public.get_survival_streak;

create or replace function public.get_survival_streak(
  p_user_id uuid,
  p_league_id uuid
)
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_streak integer := 0;
  v_result text;
begin
  for v_result in
    select result from picks
    where user_id = p_user_id
      and league_id = p_league_id
      and result != 'pending'
    order by gameweek_id desc
  loop
    if v_result = 'survived' then
      v_streak := v_streak + 1;
    else
      exit;
    end if;
  end loop;
  return v_streak;
end;
$$;

comment on function public.get_survival_streak is
  'Counts consecutive survived picks for a user in a league, walking backwards from the most recent settled GW.';
