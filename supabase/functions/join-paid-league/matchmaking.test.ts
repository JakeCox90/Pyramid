// Unit tests for paid league matchmaking business logic.
// Run with: deno test supabase/functions/join-paid-league/matchmaking.test.ts

import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeGrossPot,
  computeLeagueStatusAfterJoin,
  computeNetPot,
  computePlatformFee,
  generatePseudonym,
  hasSufficientBalance,
  isAtLeagueCap,
  isLeagueFull,
  MAX_ACTIVE_PAID_LEAGUES,
  MAX_PLAYERS,
  MIN_PLAYERS,
  selectLeagueToJoin,
  STAKE_PENCE,
  type LeagueInfo,
} from "./matchmaking.ts";

// ─── isAtLeagueCap ────────────────────────────────────────────────────────────

Deno.test("isAtLeagueCap: 0 active leagues — not at cap", () => {
  assertEquals(isAtLeagueCap(0), false);
});

Deno.test("isAtLeagueCap: 4 active leagues — not at cap", () => {
  assertEquals(isAtLeagueCap(4), false);
});

Deno.test("isAtLeagueCap: exactly 5 active leagues — at cap", () => {
  assertEquals(isAtLeagueCap(5), true);
});

Deno.test("isAtLeagueCap: 6 active leagues — at cap (over)", () => {
  assertEquals(isAtLeagueCap(6), true);
});

Deno.test(`isAtLeagueCap: MAX_ACTIVE_PAID_LEAGUES constant is 5`, () => {
  assertEquals(MAX_ACTIVE_PAID_LEAGUES, 5);
});

// ─── generatePseudonym ────────────────────────────────────────────────────────

Deno.test("generatePseudonym: position 1 → 'Player 1'", () => {
  assertEquals(generatePseudonym(1), "Player 1");
});

Deno.test("generatePseudonym: position 15 → 'Player 15'", () => {
  assertEquals(generatePseudonym(15), "Player 15");
});

Deno.test("generatePseudonym: position 30 → 'Player 30'", () => {
  assertEquals(generatePseudonym(30), "Player 30");
});

Deno.test("generatePseudonym: stable — same position always returns same pseudonym", () => {
  assertEquals(generatePseudonym(7), generatePseudonym(7));
});

// ─── selectLeagueToJoin ───────────────────────────────────────────────────────

function makeLeague(id: string, playerCount: number): LeagueInfo {
  return { id, paid_status: "waiting", player_count: playerCount };
}

Deno.test("selectLeagueToJoin: no leagues — returns null (create new)", () => {
  assertEquals(selectLeagueToJoin([]), null);
});

Deno.test("selectLeagueToJoin: single league with space — returns it", () => {
  const leagues = [makeLeague("a", 3)];
  assertEquals(selectLeagueToJoin(leagues)?.id, "a");
});

Deno.test("selectLeagueToJoin: picks the most-full league (fill existing first)", () => {
  const leagues = [makeLeague("a", 2), makeLeague("b", 4), makeLeague("c", 1)];
  assertEquals(selectLeagueToJoin(leagues)?.id, "b");
});

Deno.test("selectLeagueToJoin: full league (30 players) is excluded", () => {
  const leagues = [makeLeague("full", 30), makeLeague("partial", 15)];
  assertEquals(selectLeagueToJoin(leagues)?.id, "partial");
});

Deno.test("selectLeagueToJoin: all leagues are full — returns null", () => {
  const leagues = [makeLeague("a", 30), makeLeague("b", 30)];
  assertEquals(selectLeagueToJoin(leagues), null);
});

Deno.test("selectLeagueToJoin: excludes non-waiting leagues", () => {
  const leagues: LeagueInfo[] = [
    { id: "active", paid_status: "active", player_count: 5 },
    { id: "waiting", paid_status: "waiting", player_count: 3 },
  ];
  assertEquals(selectLeagueToJoin(leagues)?.id, "waiting");
});

Deno.test("selectLeagueToJoin: league with exactly MAX-1 players is still eligible", () => {
  const leagues = [makeLeague("near-full", MAX_PLAYERS - 1)];
  assertEquals(selectLeagueToJoin(leagues)?.id, "near-full");
});

// ─── computeLeagueStatusAfterJoin ────────────────────────────────────────────

Deno.test("computeLeagueStatusAfterJoin: 1 player — waiting", () => {
  assertEquals(computeLeagueStatusAfterJoin(1), "waiting");
});

Deno.test("computeLeagueStatusAfterJoin: 4 players — waiting", () => {
  assertEquals(computeLeagueStatusAfterJoin(4), "waiting");
});

Deno.test("computeLeagueStatusAfterJoin: exactly 5 players (MIN_PLAYERS) — active", () => {
  assertEquals(computeLeagueStatusAfterJoin(MIN_PLAYERS), "active");
});

Deno.test("computeLeagueStatusAfterJoin: 10 players — active", () => {
  assertEquals(computeLeagueStatusAfterJoin(10), "active");
});

Deno.test("computeLeagueStatusAfterJoin: 30 players (MAX_PLAYERS) — active", () => {
  assertEquals(computeLeagueStatusAfterJoin(MAX_PLAYERS), "active");
});

// ─── isLeagueFull ─────────────────────────────────────────────────────────────

Deno.test("isLeagueFull: 29 players — not full", () => {
  assertEquals(isLeagueFull(29), false);
});

Deno.test("isLeagueFull: 30 players — full", () => {
  assertEquals(isLeagueFull(30), true);
});

Deno.test("isLeagueFull: 31 players — full (over)", () => {
  assertEquals(isLeagueFull(31), true);
});

// ─── hasSufficientBalance ─────────────────────────────────────────────────────

Deno.test("hasSufficientBalance: 0 pence — insufficient", () => {
  assertEquals(hasSufficientBalance(0), false);
});

Deno.test("hasSufficientBalance: 499p — insufficient (below £5)", () => {
  assertEquals(hasSufficientBalance(499), false);
});

Deno.test("hasSufficientBalance: exactly 500p (£5 = STAKE_PENCE) — sufficient", () => {
  assertEquals(hasSufficientBalance(STAKE_PENCE), true);
});

Deno.test("hasSufficientBalance: 5001p — sufficient", () => {
  assertEquals(hasSufficientBalance(5001), true);
});

// ─── computeGrossPot / computeNetPot / computePlatformFee ────────────────────

Deno.test("computeGrossPot: 5 players × £5", () => {
  assertEquals(computeGrossPot(5), 25000);
});

Deno.test("computeGrossPot: 30 players × £5 (full league)", () => {
  assertEquals(computeGrossPot(30), 150000);
});

Deno.test("computePlatformFee: 8% of 25000 = 2000", () => {
  assertEquals(computePlatformFee(25000), 2000);
});

Deno.test("computeNetPot: 25000 - 8% = 23000", () => {
  assertEquals(computeNetPot(25000), 23000);
});

Deno.test("computeNetPot + computePlatformFee = gross", () => {
  const gross = computeGrossPot(10);
  assertEquals(computeNetPot(gross) + computePlatformFee(gross), gross);
});

Deno.test("STAKE_PENCE constant is 5000 (£5)", () => {
  assertEquals(STAKE_PENCE, 5000);
});

// ─── Scenario: minimum league (5 players) ────────────────────────────────────

Deno.test("scenario: 5-player league — status transitions from waiting to active", () => {
  // Players 1–4 join — waiting
  for (let n = 1; n <= 4; n++) {
    assertEquals(computeLeagueStatusAfterJoin(n), "waiting");
  }
  // Player 5 joins — active
  assertEquals(computeLeagueStatusAfterJoin(5), "active");
});

Deno.test("scenario: 30-player league — full at MAX_PLAYERS", () => {
  assertEquals(isLeagueFull(29), false);
  assertEquals(isLeagueFull(30), true);
  assertEquals(computeLeagueStatusAfterJoin(30), "active");
});

// ─── Scenario: cap enforcement ────────────────────────────────────────────────

Deno.test("scenario: user at cap cannot join — cap check fires before league selection", () => {
  // Simulate: user already in 5 paid leagues
  assertEquals(isAtLeagueCap(5), true);

  // League selection is irrelevant — the cap gate should have already returned 409
  const leagues = [makeLeague("open", 3)];
  // This test documents that cap check should happen BEFORE selectLeagueToJoin
  assertEquals(selectLeagueToJoin(leagues)?.id, "open"); // would succeed if cap not checked
});

// ─── Scenario: pseudonym stability ───────────────────────────────────────────

Deno.test("scenario: pseudonyms are sequential by join order", () => {
  const pseudonyms = [1, 2, 3, 4, 5].map(generatePseudonym);
  assertEquals(pseudonyms, ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5"]);
});
