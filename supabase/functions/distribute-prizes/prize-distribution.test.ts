// Unit tests for prize-distribution business logic.
// Run with: deno test supabase/functions/distribute-prizes/prize-distribution.test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeNetPot,
  computePlatformFee,
  computePrizeAllocations,
  determineFinishingPositions,
} from "./prize-distribution.ts";
import type { DbLeagueMember, PrizeAllocation } from "./prize-distribution.ts";

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeMember(
  userId: string,
  status: "active" | "eliminated",
  eliminatedGameweek: number | null = null,
): DbLeagueMember {
  return { id: `id-${userId}`, user_id: userId, status, eliminated_gameweek: eliminatedGameweek };
}

function totalAllocated(allocations: PrizeAllocation[]): number {
  return allocations.reduce((sum, a) => sum + a.amountPence, 0);
}

function positionOf(items: { userId: string; position: number }[], userId: string): number | undefined {
  return items.find((a) => a.userId === userId)?.position;
}

function amountOf(allocations: PrizeAllocation[], userId: string): number | undefined {
  return allocations.find((a) => a.userId === userId)?.amountPence;
}

// ─── computePlatformFee ───────────────────────────────────────────────────────

Deno.test("platform fee: 8% of 10000 = 800", () => {
  assertEquals(computePlatformFee(10000), 800);
});

Deno.test("platform fee: 8% of 5000 = 400", () => {
  assertEquals(computePlatformFee(5000), 400);
});

Deno.test("platform fee: rounding — 8% of 101 = 8 (Math.round(8.08))", () => {
  assertEquals(computePlatformFee(101), 8); // 101 * 0.08 = 8.08 → rounds to 8
});

Deno.test("platform fee: rounding — 8% of 106 = 8 (Math.round(8.48))", () => {
  assertEquals(computePlatformFee(106), 8); // 8.48 → 8
});

Deno.test("platform fee: rounding — 8% of 107 = 9 (Math.round(8.56))", () => {
  assertEquals(computePlatformFee(107), 9); // 8.56 → 9
});

// ─── computeNetPot ────────────────────────────────────────────────────────────

Deno.test("net pot: 10000 gross → 9200 net (8% fee)", () => {
  assertEquals(computeNetPot(10000), 9200);
});

Deno.test("net pot: 5000 gross → 4600 net (8% fee)", () => {
  assertEquals(computeNetPot(5000), 4600);
});

// ─── determineFinishingPositions — solo winner ────────────────────────────────

Deno.test("positions: solo winner — 1 survivor, rest eliminated on different GWs", () => {
  const members: DbLeagueMember[] = [
    makeMember("u1", "active"),           // survivor → 1st
    makeMember("u2", "eliminated", 5),    // eliminated GW5 → 2nd
    makeMember("u3", "eliminated", 3),    // eliminated GW3 → 3rd
    makeMember("u4", "eliminated", 1),    // eliminated GW1 → no position (beyond 3rd)
  ];
  const results = determineFinishingPositions(members);
  assertEquals(positionOf(results, "u1"), 1);
  assertEquals(positionOf(results, "u2"), 2);
  assertEquals(positionOf(results, "u3"), 3);
  // u4 eliminated GW1 — not in top 3 positions (no assignment)
  assertEquals(results.find((r) => r.userId === "u4"), undefined);
});

Deno.test("positions: solo winner — only 1st and 2nd positions when only 2 tiers", () => {
  const members: DbLeagueMember[] = [
    makeMember("u1", "active"),          // 1st
    makeMember("u2", "eliminated", 4),   // 2nd
  ];
  const results = determineFinishingPositions(members);
  assertEquals(positionOf(results, "u1"), 1);
  assertEquals(positionOf(results, "u2"), 2);
  assertEquals(results.length, 2);
});

// ─── determineFinishingPositions — joint positions ────────────────────────────

Deno.test("positions: joint 1st — 2 active survivors", () => {
  const members: DbLeagueMember[] = [
    makeMember("u1", "active"),
    makeMember("u2", "active"),
    makeMember("u3", "eliminated", 3),
  ];
  const results = determineFinishingPositions(members);
  assertEquals(positionOf(results, "u1"), 1);
  assertEquals(positionOf(results, "u2"), 1);
  assertEquals(positionOf(results, "u3"), 2);
});

Deno.test("positions: joint 2nd — 3 players eliminated on the same GW", () => {
  const members: DbLeagueMember[] = [
    makeMember("u1", "active"),
    makeMember("u2", "eliminated", 5),
    makeMember("u3", "eliminated", 5),
    makeMember("u4", "eliminated", 5),
  ];
  const results = determineFinishingPositions(members);
  assertEquals(positionOf(results, "u1"), 1);
  assertEquals(positionOf(results, "u2"), 2);
  assertEquals(positionOf(results, "u3"), 2);
  assertEquals(positionOf(results, "u4"), 2);
});

// ─── determineFinishingPositions — mass elimination (all joint 1st) ───────────

Deno.test("positions: mass elimination — all members active, everyone joint 1st", () => {
  const members: DbLeagueMember[] = [
    makeMember("u1", "active"),
    makeMember("u2", "active"),
    makeMember("u3", "active"),
  ];
  const results = determineFinishingPositions(members);
  assertEquals(results.length, 3);
  for (const r of results) {
    assertEquals(r.position, 1);
    assertEquals(r.eliminatedGameweek, null);
  }
});

Deno.test("positions: no survivors — most recently eliminated are joint 1st", () => {
  // Round ended with everyone eliminated on the same final GW (mass elim corner case)
  const members: DbLeagueMember[] = [
    makeMember("u1", "eliminated", 7),
    makeMember("u2", "eliminated", 7),
    makeMember("u3", "eliminated", 4),
  ];
  const results = determineFinishingPositions(members);
  assertEquals(positionOf(results, "u1"), 1);
  assertEquals(positionOf(results, "u2"), 1);
  assertEquals(positionOf(results, "u3"), 2);
});

// ─── computePrizeAllocations — 3 distinct positions (65/25/10) ───────────────

Deno.test("allocations: 3 distinct positions — standard 65/25/10 split of 10000", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 5 },
    { userId: "u3", position: 3 as const, eliminatedGameweek: 3 },
  ];
  const allocations = computePrizeAllocations(results, 10000);
  assertEquals(amountOf(allocations, "u1"), 6500);
  assertEquals(amountOf(allocations, "u2"), 2500);
  assertEquals(amountOf(allocations, "u3"), 1000);
  assertEquals(totalAllocated(allocations), 10000);
});

Deno.test("allocations: 3 distinct positions — sum always equals netPot (odd pence: 9999)", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 5 },
    { userId: "u3", position: 3 as const, eliminatedGameweek: 3 },
  ];
  const allocations = computePrizeAllocations(results, 9999);
  assertEquals(totalAllocated(allocations), 9999);
});

// ─── computePrizeAllocations — 2 distinct positions (proportional) ────────────

Deno.test("allocations: 2 positions — 65/(65+25) ≈ 72.2% to 1st, 27.8% to 2nd", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 5 },
  ];
  // Net pot: 9000 pence
  // Weights: 1st = 0.65, 2nd = 0.25; totalWeight = 0.90
  // 1st share: floor(0.65/0.90 * 9000) = floor(6500) = 6500
  // 2nd share: 9000 - 6500 = 2500
  const allocations = computePrizeAllocations(results, 9000);
  assertEquals(totalAllocated(allocations), 9000);
  // 1st should get more than 2nd
  const u1 = amountOf(allocations, "u1")!;
  const u2 = amountOf(allocations, "u2")!;
  assertEquals(u1 > u2, true);
  // Exact values
  assertEquals(u1, 6500); // floor(0.65/0.90 * 9000)
  assertEquals(u2, 2500); // remainder
});

Deno.test("allocations: 2 positions — sum equals netPot (7777 odd)", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 3 },
  ];
  const allocations = computePrizeAllocations(results, 7777);
  assertEquals(totalAllocated(allocations), 7777);
});

// ─── computePrizeAllocations — 1 position only (solo) ────────────────────────

Deno.test("allocations: solo winner — all to 1st", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
  ];
  const allocations = computePrizeAllocations(results, 9200);
  assertEquals(allocations.length, 1);
  assertEquals(amountOf(allocations, "u1"), 9200);
  assertEquals(totalAllocated(allocations), 9200);
});

// ─── computePrizeAllocations — joint 1st split ────────────────────────────────

Deno.test("allocations: joint 1st (2 survivors) — split 65% equally; penny goes to 1st", () => {
  // 2 joint 1st players, no 2nd or 3rd
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 1 as const, eliminatedGameweek: null },
  ];
  // Net pot: 10001 pence
  // Only position 1 filled (100% of pot = 10001)
  // Split: 5000 each → remainder 1 → goes to 1st (already is 1st, first member gets it)
  const allocations = computePrizeAllocations(results, 10001);
  assertEquals(totalAllocated(allocations), 10001);
  const u1 = amountOf(allocations, "u1")!;
  const u2 = amountOf(allocations, "u2")!;
  // One gets 5001, one gets 5000 (remainder goes upward, which is 1st — both are 1st, so first member)
  assertEquals(u1 + u2, 10001);
  // The difference should be exactly 1 penny
  assertEquals(Math.abs(u1 - u2), 1);
});

Deno.test("allocations: joint 1st (2) with 2nd present — 65% split, remainder to 1st", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 1 as const, eliminatedGameweek: null },
    { userId: "u3", position: 2 as const, eliminatedGameweek: 5 },
  ];
  // Net pot: 10000
  // Positions: 1st (weight 0.65) and 2nd (weight 0.25), totalWeight = 0.90
  // 1st pool: floor(0.65/0.90 * 10000) = floor(7222.22) = 7222
  // 2nd pool: 10000 - 7222 = 2778
  // 1st split: floor(7222/2) = 3611 each → remainder 0
  const allocations = computePrizeAllocations(results, 10000);
  assertEquals(totalAllocated(allocations), 10000);
  const u3 = amountOf(allocations, "u3")!;
  const u1 = amountOf(allocations, "u1")!;
  const u2 = amountOf(allocations, "u2")!;
  // 2nd gets 2778 (remainder goes to 1st, but remainder from 2nd split is 0 here)
  assertEquals(u1 + u2 + u3, 10000);
  assertEquals(positionOf(allocations, "u3"), 2);
});

Deno.test("allocations: joint 2nd (3 players same GW) — split 25% equally", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 5 },
    { userId: "u3", position: 2 as const, eliminatedGameweek: 5 },
    { userId: "u4", position: 2 as const, eliminatedGameweek: 5 },
  ];
  // Net pot: 9000
  // Positions: 1st (0.65) and 2nd (0.25), totalWeight = 0.90
  // 1st pool: floor(0.65/0.90 * 9000) = floor(6500) = 6500
  // 2nd pool: 9000 - 6500 = 2500
  // 2nd split: floor(2500/3) = 833 each → remainder 1 → goes UP to 1st
  const allocations = computePrizeAllocations(results, 9000);
  assertEquals(totalAllocated(allocations), 9000);
  const u1 = amountOf(allocations, "u1")!;
  const u2 = amountOf(allocations, "u2")!;
  const u3 = amountOf(allocations, "u3")!;
  const u4 = amountOf(allocations, "u4")!;
  // u2, u3, u4 each get 833; remainder 1 goes to u1
  assertEquals(u2, 833);
  assertEquals(u3, 833);
  assertEquals(u4, 833);
  assertEquals(u1, 6501); // 6500 + 1 remainder from 2nd split
  assertEquals(u1 + u2 + u3 + u4, 9000);
});

// ─── computePrizeAllocations — all joint 1st (mass elimination) ───────────────

Deno.test("allocations: all-joint-1st (mass elimination) — split 100% equally", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 1 as const, eliminatedGameweek: null },
    { userId: "u3", position: 1 as const, eliminatedGameweek: null },
  ];
  // Net pot: 9000 → 3000 each
  const allocations = computePrizeAllocations(results, 9000);
  assertEquals(totalAllocated(allocations), 9000);
  assertEquals(amountOf(allocations, "u1"), 3000);
  assertEquals(amountOf(allocations, "u2"), 3000);
  assertEquals(amountOf(allocations, "u3"), 3000);
});

Deno.test("allocations: all-joint-1st (4 players) — even split with remainder", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 1 as const, eliminatedGameweek: null },
    { userId: "u3", position: 1 as const, eliminatedGameweek: null },
    { userId: "u4", position: 1 as const, eliminatedGameweek: null },
  ];
  // Net pot: 9001 → 2250 each, remainder 1 → first member gets it
  const allocations = computePrizeAllocations(results, 9001);
  assertEquals(totalAllocated(allocations), 9001);
  const amounts = allocations.map((a) => a.amountPence);
  // All but one get 2250; one gets 2251
  assertEquals(amounts.filter((a) => a === 2250).length, 3);
  assertEquals(amounts.filter((a) => a === 2251).length, 1);
});

// ─── Penny rounding invariant ─────────────────────────────────────────────────

Deno.test("rounding invariant: sum of allocations always equals netPotPence (1p pot)", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 2 as const, eliminatedGameweek: 3 },
    { userId: "u3", position: 3 as const, eliminatedGameweek: 1 },
  ];
  const allocations = computePrizeAllocations(results, 1);
  assertEquals(totalAllocated(allocations), 1);
});

Deno.test("rounding invariant: sum equals netPot across various pot sizes", () => {
  const results = [
    { userId: "u1", position: 1 as const, eliminatedGameweek: null },
    { userId: "u2", position: 1 as const, eliminatedGameweek: null },
    { userId: "u3", position: 2 as const, eliminatedGameweek: 5 },
    { userId: "u4", position: 3 as const, eliminatedGameweek: 3 },
  ];
  for (const netPot of [100, 999, 4600, 9200, 100000, 1]) {
    const allocations = computePrizeAllocations(results, netPot);
    assertEquals(
      totalAllocated(allocations),
      netPot,
      `Sum mismatch for netPot=${netPot}`,
    );
  }
});
