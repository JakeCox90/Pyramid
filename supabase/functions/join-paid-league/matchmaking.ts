// matchmaking.ts — Pure business logic for paid league matchmaking.
// Extracted so it can be unit-tested without Deno.serve or DB dependencies.

export const STAKE_PENCE = 5000;                  // £5 fixed stake (rules §2.2)
export const MIN_PLAYERS = 5;                     // minimum to start a round (rules §2.2)
export const MAX_PLAYERS = 30;                    // maximum per paid league (rules §2.2)
export const MAX_ACTIVE_PAID_LEAGUES = 5;         // cap per user (rules §2.2)
export const PLATFORM_FEE_RATE = 0.08;            // 8% (rules §5.4)

// ─── Types ─────────────────────────────────────────────────────────────────────

export type PaidLeagueStatus = "waiting" | "active" | "complete";

export interface LeagueInfo {
  id: string;
  paid_status: PaidLeagueStatus;
  player_count: number;
}

// ─── Cap enforcement ───────────────────────────────────────────────────────────

/**
 * Returns true if the user has reached the 5-active-paid-leagues cap (rules §2.2).
 */
export function isAtLeagueCap(activePaidLeagueCount: number): boolean {
  return activePaidLeagueCount >= MAX_ACTIVE_PAID_LEAGUES;
}

// ─── Pseudonym generation ──────────────────────────────────────────────────────

/**
 * Generates a stable pseudonym for a player given their join-order position (1-based).
 * "Player 1", "Player 2", ..., "Player 30".
 */
export function generatePseudonym(joinPosition: number): string {
  return `Player ${joinPosition}`;
}

// ─── League selection ──────────────────────────────────────────────────────────

/**
 * Selects the best league to join from a list of available (waiting) leagues.
 * Strategy: fill the least-full league first (fill existing before creating new).
 * Returns null if no suitable league is found (a new one should be created).
 */
export function selectLeagueToJoin(
  availableLeagues: LeagueInfo[],
): LeagueInfo | null {
  const eligible = availableLeagues.filter(
    (l) => l.paid_status === "waiting" && l.player_count < MAX_PLAYERS,
  );
  if (eligible.length === 0) return null;

  // Fill the most-full league first (least room remaining)
  eligible.sort((a, b) => b.player_count - a.player_count);
  return eligible[0];
}

// ─── League status transition ─────────────────────────────────────────────────

/**
 * Determines the new league status after a player joins.
 * Returns 'active' when the minimum player count has been reached,
 * 'waiting' otherwise.
 */
export function computeLeagueStatusAfterJoin(newPlayerCount: number): PaidLeagueStatus {
  return newPlayerCount >= MIN_PLAYERS ? "active" : "waiting";
}

/**
 * Returns true if the new player count has hit the maximum — the league is full
 * and should be closed to new joiners.
 */
export function isLeagueFull(playerCount: number): boolean {
  return playerCount >= MAX_PLAYERS;
}

// ─── Prize pot calculation ────────────────────────────────────────────────────

/**
 * Computes the gross prize pot for a paid league at round start.
 * gross = player_count × stake_pence
 */
export function computeGrossPot(playerCount: number): number {
  return playerCount * STAKE_PENCE;
}

/**
 * Computes the platform fee (8% of gross).
 */
export function computePlatformFee(grossPotPence: number): number {
  return Math.round(grossPotPence * PLATFORM_FEE_RATE);
}

/**
 * Computes the net prize pot (gross minus platform fee).
 */
export function computeNetPot(grossPotPence: number): number {
  return grossPotPence - computePlatformFee(grossPotPence);
}

// ─── Wallet cap check ─────────────────────────────────────────────────────────

/**
 * Returns true if the user's available_to_play balance is sufficient to cover the stake.
 */
export function hasSufficientBalance(availableToPlayPence: number): boolean {
  return availableToPlayPence >= STAKE_PENCE;
}
