-- Fix infinite recursion in league_members and leagues RLS policies.
-- The old policies checked league_members to authorize reading league_members
-- and leagues, creating cross-table recursion.
-- Fix: use a SECURITY DEFINER function to bypass RLS when resolving membership.

-- Step 1: Create a security definer function that bypasses RLS
CREATE OR REPLACE FUNCTION public.user_league_ids(uid uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT league_id FROM public.league_members WHERE user_id = uid;
$$;

-- Step 2: Drop all existing SELECT policies on league_members and recreate
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'league_members' AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.league_members', pol.policyname);
  END LOOP;
END $$;

CREATE POLICY "Users can view own memberships"
  ON public.league_members FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can view co-members in their leagues"
  ON public.league_members FOR SELECT
  USING (league_id IN (SELECT public.user_league_ids(auth.uid())));

-- Step 3: Fix the leagues table policy that also caused cross-table recursion
DROP POLICY IF EXISTS "League members can view their leagues" ON public.leagues;

CREATE POLICY "League members can view their leagues"
  ON public.leagues FOR SELECT
  USING (id IN (SELECT public.user_league_ids(auth.uid())));
