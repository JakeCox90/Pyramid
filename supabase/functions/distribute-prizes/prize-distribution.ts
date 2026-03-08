// prize-distribution.ts — Pure business logic for prize allocation.
// Extracted from index.ts so it can be unit-tested without Deno.serve or DB calls.
//
// Rules reference: docs/game-rules/rules.md §5.2

// ─── Constants ────────────────────────────────────────────────────────────────

/** Prize share percentages per finishing position (rules §5.2). */
const PRIZE_SHARES = { first: 0.65, second: 0.25, third: 0.10 } as const;

/** Platform fee percentage taken from the gross pot (rules §5.2). */
const PLATFORM_FEE_RATE = 0.08;

// ─── Types ────────────────────────────────────────────────────────────────────

export type FinishingPosition = 1 | 2 | 3;

/** A row from the league_members table — only the fields we need. */
export interface DbLeagueMember {
  id: string;
  user_id: string;
  /** 'active' = still in the game; 'eliminated' = knocked out. */
  status: "active" | "eliminated";
  /** The gameweek_id on which this member was eliminated. null if still active. */
  eliminated_gameweek: number | null;
}

/** The finishing position determined for a single player. */
export interface PlayerResult {
  userId: string;
  position: FinishingPosition;
  /** The gameweek on which this player was eliminated. null for survivors (1st). */
  eliminatedGameweek: number | null;
}

/** The computed prize allocation for a single player. */
export interface PrizeAllocation {
  userId: string;
  position: FinishingPosition;
  amountPence: number;
}

// ─── Public functions ─────────────────────────────────────────────────────────

/**
 * Computes the platform fee (8% of gross pot, rounded to nearest pence).
 */
export function computePlatformFee(grossPotPence: number): number {
  return Math.round(grossPotPence * PLATFORM_FEE_RATE);
}

/**
 * Computes the net pot after deducting the platform fee.
 */
export function computeNetPot(grossPotPence: number): number {
  return grossPotPence - computePlatformFee(grossPotPence);
}

/**
 * Determines finishing positions for all league members.
 *
 * Rules §5.2:
 *   1st = last survivor(s): status='active', OR eliminated on the highest gameweek
 *         (mass-elimination reinstatement means they were set back to 'active', but
 *          if the round ended with everyone active we treat all as joint 1st).
 *   2nd = eliminated on the gameweek immediately before 1st was decided.
 *   3rd = gameweek before that.
 *   Players eliminated on the same gameweek share the same position.
 *
 * If there are fewer than 3 distinct elimination tiers, only 1st and/or 2nd
 * positions are assigned. computePrizeAllocations() handles redistribution.
 */
export function determineFinishingPositions(members: DbLeagueMember[]): PlayerResult[] {
  if (members.length === 0) return [];

  // Separate survivors (active) from eliminated members
  const survivors = members.filter((m) => m.status === "active");
  const eliminated = members.filter((m) => m.status === "eliminated");

  // All members survived (no eliminations ever, or mass-elimination at end)
  // → everyone is joint 1st.
  if (eliminated.length === 0) {
    return members.map((m) => ({
      userId: m.user_id,
      position: 1,
      eliminatedGameweek: null,
    }));
  }

  // Sort eliminated members by gameweek descending (most-recently-eliminated first)
  const sortedElim = [...eliminated].sort((a, b) => {
    const aGw = a.eliminated_gameweek ?? 0;
    const bGw = b.eliminated_gameweek ?? 0;
    return bGw - aGw; // descending
  });

  // Build distinct gameweek tiers (ordered most-recent → oldest)
  const gwOrder: number[] = [];
  for (const m of sortedElim) {
    const gw = m.eliminated_gameweek ?? 0;
    if (gwOrder.length === 0 || gwOrder[gwOrder.length - 1] !== gw) {
      gwOrder.push(gw);
    }
  }

  // Active survivors are 1st. If there are no active survivors, the most
  // recently-eliminated cohort is 1st (rules §5.2 — last to be eliminated wins).
  const results: PlayerResult[] = [];

  if (survivors.length > 0) {
    // Active survivors → 1st
    for (const m of survivors) {
      results.push({ userId: m.user_id, position: 1, eliminatedGameweek: null });
    }
    // Most recently eliminated → 2nd (if it exists)
    if (gwOrder.length >= 1) {
      const gw2 = gwOrder[0];
      const group2 = sortedElim.filter((m) => m.eliminated_gameweek === gw2);
      for (const m of group2) {
        results.push({ userId: m.user_id, position: 2, eliminatedGameweek: gw2 });
      }
    }
    // Second-most recently eliminated → 3rd (if it exists)
    if (gwOrder.length >= 2) {
      const gw3 = gwOrder[1];
      const group3 = sortedElim.filter((m) => m.eliminated_gameweek === gw3);
      for (const m of group3) {
        results.push({ userId: m.user_id, position: 3, eliminatedGameweek: gw3 });
      }
    }
  } else {
    // No active survivors — most-recently-eliminated cohort wins (§5.2 last-survivor rule
    // after mass elimination resolved or final GW elimination). They are joint 1st.
    const gw1 = gwOrder[0];
    const group1 = sortedElim.filter((m) => m.eliminated_gameweek === gw1);
    for (const m of group1) {
      results.push({ userId: m.user_id, position: 1, eliminatedGameweek: gw1 });
    }
    if (gwOrder.length >= 2) {
      const gw2 = gwOrder[1];
      const group2 = sortedElim.filter((m) => m.eliminated_gameweek === gw2);
      for (const m of group2) {
        results.push({ userId: m.user_id, position: 2, eliminatedGameweek: gw2 });
      }
    }
    if (gwOrder.length >= 3) {
      const gw3 = gwOrder[2];
      const group3 = sortedElim.filter((m) => m.eliminated_gameweek === gw3);
      for (const m of group3) {
        results.push({ userId: m.user_id, position: 3, eliminatedGameweek: gw3 });
      }
    }
  }

  return results;
}

/**
 * Computes prize allocations given finished positions and a net pot.
 *
 * Rules:
 *   - Fewer than 3 positions: redistribute proportionally using 65/25/10 weights
 *     among the filled positions only.
 *   - Joint position: split evenly; penny remainder goes to the NEXT position UP
 *     (lower position number = higher in standings), e.g. 1st gets the remainder
 *     when 2nd is split.
 *   - All amounts are rounded to integer pence.
 *   - Sum of all allocations === netPotPence always.
 */
export function computePrizeAllocations(
  results: PlayerResult[],
  netPotPence: number,
): PrizeAllocation[] {
  if (results.length === 0) return [];

  // Group results by position
  const byPosition = new Map<FinishingPosition, PlayerResult[]>();
  for (const r of results) {
    if (!byPosition.has(r.position)) byPosition.set(r.position, []);
    byPosition.get(r.position)!.push(r);
  }

  const positions = ([1, 2, 3] as FinishingPosition[]).filter((p) => byPosition.has(p));

  // Determine proportional weights for filled positions only
  const weightMap: Record<FinishingPosition, number> = {
    1: PRIZE_SHARES.first,
    2: PRIZE_SHARES.second,
    3: PRIZE_SHARES.third,
  };

  const totalWeight = positions.reduce((sum, p) => sum + weightMap[p], 0);

  // Calculate each position's share of the net pot
  // We need to ensure allocations sum exactly to netPotPence.
  // Strategy: compute floor for each position group, then distribute remainders
  // top-down (higher positions get remainders first).

  const positionAmounts = new Map<FinishingPosition, number>();
  let allocated = 0;

  for (let i = 0; i < positions.length; i++) {
    const pos = positions[i];
    if (i === positions.length - 1) {
      // Last position gets whatever is left to ensure exact sum
      positionAmounts.set(pos, netPotPence - allocated);
    } else {
      const share = Math.floor((weightMap[pos] / totalWeight) * netPotPence);
      positionAmounts.set(pos, share);
      allocated += share;
    }
  }

  // Now split each position's pool evenly among joint holders.
  // Penny remainder goes to the NEXT position UP (lower number = better position).
  // We process from worst position to best, carrying remainders upward.
  const allocations: PrizeAllocation[] = [];

  // Process positions from worst (3) to best (1) so we can push remainders UP.
  const reversedPositions = [...positions].reverse(); // e.g. [3, 2, 1]

  let carryUp = 0; // penny remainder carried from worse positions to better

  for (const pos of reversedPositions) {
    const group = byPosition.get(pos)!;
    const totalForPos = positionAmounts.get(pos)! + carryUp;
    carryUp = 0;

    if (group.length === 1) {
      allocations.push({
        userId: group[0].userId,
        position: pos,
        amountPence: totalForPos,
      });
    } else {
      // Split evenly; remainder carries UP (to next better position)
      const perPerson = Math.floor(totalForPos / group.length);
      const remainder = totalForPos - perPerson * group.length;
      carryUp = remainder; // will be added to the next-better position

      for (const r of group) {
        allocations.push({
          userId: r.userId,
          position: pos,
          amountPence: perPerson,
        });
      }
    }
  }

  // If there's still a carry (e.g. only one position and it had a remainder from
  // proportional rounding), add it to the best position's first member.
  if (carryUp > 0) {
    const bestPos = positions[0]; // lowest number = best
    const bestGroup = allocations.filter((a) => a.position === bestPos);
    if (bestGroup.length > 0) {
      bestGroup[0].amountPence += carryUp;
    }
  }

  return allocations;
}
