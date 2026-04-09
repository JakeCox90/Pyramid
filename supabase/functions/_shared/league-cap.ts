// Shared league cap enforcement.
// Game rules §2.2: 5 active leagues max per user at any time.
// "Active" = member_status is 'alive'/'active' AND league status is 'pending' or 'active'.

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export const MAX_ACTIVE_LEAGUES = 5;

/**
 * Counts the user's active league memberships (alive in pending/active leagues).
 * Returns the count, or throws on query error.
 */
export async function getActiveLeagueCount(
  db: SupabaseClient,
  userId: string,
): Promise<number> {
  const { data, error } = await db
    .from("league_members")
    .select("league_id, leagues!inner(status)")
    .eq("user_id", userId)
    .in("status", ["active", "alive"])
    .in("leagues.status", ["pending", "active"]);

  if (error) throw error;
  return (data ?? []).length;
}

/**
 * Returns true if the user has reached the active league cap.
 */
export function isAtLeagueCap(activeCount: number): boolean {
  return activeCount >= MAX_ACTIVE_LEAGUES;
}
