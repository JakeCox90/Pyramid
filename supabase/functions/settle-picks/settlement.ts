// settlement.ts — Pure business logic for pick settlement.
// Extracted from index.ts so it can be unit-tested without Deno.serve.

export interface DbFixture {
  id: number;
  status: string;
  home_team_id: number;
  away_team_id: number;
  home_score: number | null;
  away_score: number | null;
}

export interface DbPick {
  id: string;
  league_id: string;
  user_id: string;
  team_id: number;
}

export type PickResult = "survived" | "eliminated" | "void";

/**
 * Determines the settlement result for a single pick given the fixture result.
 *
 * Rules (docs/game-rules/rules.md §4):
 *   - PST / ABD → void (player survives, team not marked used)
 *   - FT + null scores → void (data guard)
 *   - FT + team not in fixture → void (data guard)
 *   - FT + picked team won → survived
 *   - FT + draw → survived (draw does not eliminate — §4.1)
 *   - FT + picked team lost → eliminated
 */
export function determinePickResult(pick: DbPick, fixture: DbFixture): PickResult {
  const { status, home_team_id, away_team_id, home_score, away_score } = fixture;

  if (status === "PST" || status === "ABD") return "void";

  if (home_score === null || away_score === null) return "void"; // data guard

  const pickedHome = pick.team_id === home_team_id;
  const pickedAway = pick.team_id === away_team_id;

  if (!pickedHome && !pickedAway) return "void"; // team not in fixture — data guard

  if (home_score === away_score) return "survived"; // draw — player survives (§4.1)

  const homeWon = home_score > away_score;
  const pickedTeamWon = (pickedHome && homeWon) || (pickedAway && !homeWon);
  return pickedTeamWon ? "survived" : "eliminated";
}

/**
 * Returns true if all remaining active members in a league are 0
 * (i.e., mass elimination has occurred), given the current active member count.
 */
export function isMassElimination(
  activeMemberCount: number,
  newEliminationCount: number,
): boolean {
  return activeMemberCount === 0 && newEliminationCount > 0;
}

/**
 * Returns the user IDs of active members who have no pending pick for the
 * current gameweek and should be auto-eliminated (rules §3.3).
 *
 * @param activeMemberIds  IDs of members currently active in the league
 * @param memberIdsWithPendingPick  IDs of members who have a pending pick for the GW
 */
export function findNoPickMemberIds(
  activeMemberIds: string[],
  memberIdsWithPendingPick: string[],
): string[] {
  const safeSet = new Set(memberIdsWithPendingPick);
  return activeMemberIds.filter((id) => !safeSet.has(id));
}
