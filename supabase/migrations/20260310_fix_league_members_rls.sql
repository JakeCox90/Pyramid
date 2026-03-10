-- Fix infinite recursion in league_members RLS policy.
-- The old policy checked league_members to authorize reading league_members.
-- New policy: users can see all members of leagues they belong to,
-- using a direct user_id check to break the recursion.

drop policy if exists "League members can view membership for their leagues" on public.league_members;

-- Step 1: Allow users to see their OWN membership rows (no recursion)
create policy "Users can view own memberships"
  on public.league_members for select
  using (user_id = auth.uid());

-- Step 2: Allow users to see OTHER members in leagues they belong to
-- Uses a security definer function to bypass RLS and avoid recursion.
create or replace function public.user_league_ids(uid uuid)
returns setof uuid
language sql
security definer
set search_path = ''
stable
as $$
  select league_id from public.league_members where user_id = uid;
$$;

create policy "Users can view co-members in their leagues"
  on public.league_members for select
  using (league_id in (select public.user_league_ids(auth.uid())));
