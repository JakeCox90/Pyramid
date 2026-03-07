// Unit tests for settle-picks settlement logic.
// Run with: deno test supabase/functions/settle-picks/settlement.test.ts

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { determinePickResult, findNoPickMemberIds, isMassElimination } from "./settlement.ts";
import type { DbFixture, DbPick } from "./settlement.ts";

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const HOME_TEAM_ID = 100;
const AWAY_TEAM_ID = 200;
const OTHER_TEAM_ID = 999;

function makeFixture(overrides: Partial<DbFixture> = {}): DbFixture {
  return {
    id: 1,
    status: "FT",
    home_team_id: HOME_TEAM_ID,
    away_team_id: AWAY_TEAM_ID,
    home_score: 2,
    away_score: 0,
    ...overrides,
  };
}

function makePick(teamId: number): DbPick {
  return { id: "pick-1", league_id: "league-1", user_id: "user-1", team_id: teamId };
}

// ─── determinePickResult ──────────────────────────────────────────────────────

Deno.test("survived: picked home team that won", () => {
  const fixture = makeFixture({ home_score: 3, away_score: 1 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "survived");
});

Deno.test("survived: picked away team that won", () => {
  const fixture = makeFixture({ home_score: 0, away_score: 2 });
  assertEquals(determinePickResult(makePick(AWAY_TEAM_ID), fixture), "survived");
});

Deno.test("eliminated: picked home team that lost", () => {
  const fixture = makeFixture({ home_score: 0, away_score: 1 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "eliminated");
});

Deno.test("eliminated: picked away team that lost", () => {
  const fixture = makeFixture({ home_score: 2, away_score: 0 });
  assertEquals(determinePickResult(makePick(AWAY_TEAM_ID), fixture), "eliminated");
});

Deno.test("survived: draw — home picker (draws do not eliminate, §4.1)", () => {
  const fixture = makeFixture({ home_score: 1, away_score: 1 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "survived");
});

Deno.test("survived: draw — away picker (draws do not eliminate, §4.1)", () => {
  const fixture = makeFixture({ home_score: 2, away_score: 2 });
  assertEquals(determinePickResult(makePick(AWAY_TEAM_ID), fixture), "survived");
});

Deno.test("void: postponed match (PST)", () => {
  const fixture = makeFixture({ status: "PST", home_score: null, away_score: null });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "void");
});

Deno.test("void: abandoned match (ABD)", () => {
  const fixture = makeFixture({ status: "ABD", home_score: null, away_score: null });
  assertEquals(determinePickResult(makePick(AWAY_TEAM_ID), fixture), "void");
});

Deno.test("void: FT with null home_score (data guard)", () => {
  const fixture = makeFixture({ status: "FT", home_score: null, away_score: 0 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "void");
});

Deno.test("void: FT with null away_score (data guard)", () => {
  const fixture = makeFixture({ status: "FT", home_score: 1, away_score: null });
  assertEquals(determinePickResult(makePick(AWAY_TEAM_ID), fixture), "void");
});

Deno.test("void: team not in fixture (data inconsistency guard)", () => {
  const fixture = makeFixture({ home_score: 2, away_score: 0 });
  assertEquals(determinePickResult(makePick(OTHER_TEAM_ID), fixture), "void");
});

Deno.test("survived: high-scoring home win", () => {
  const fixture = makeFixture({ home_score: 5, away_score: 0 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "survived");
});

Deno.test("survived: 0-0 draw (draws do not eliminate, §4.1)", () => {
  const fixture = makeFixture({ home_score: 0, away_score: 0 });
  assertEquals(determinePickResult(makePick(HOME_TEAM_ID), fixture), "survived");
});

// ─── isMassElimination ────────────────────────────────────────────────────────

Deno.test("mass elimination: 0 active members, 3 new eliminations", () => {
  assertEquals(isMassElimination(0, 3), true);
});

Deno.test("not mass elimination: 1 active member remains", () => {
  assertEquals(isMassElimination(1, 2), false);
});

Deno.test("not mass elimination: 0 active but 0 new eliminations", () => {
  assertEquals(isMassElimination(0, 0), false);
});

Deno.test("not mass elimination: all survived (no eliminations)", () => {
  assertEquals(isMassElimination(3, 0), false);
});

// ─── findNoPickMemberIds ──────────────────────────────────────────────────────

Deno.test("no-pick: member with no pick is returned", () => {
  assertEquals(findNoPickMemberIds(["u1", "u2"], ["u1"]), ["u2"]);
});

Deno.test("no-pick: all members have pending picks — none returned", () => {
  assertEquals(findNoPickMemberIds(["u1", "u2"], ["u1", "u2"]), []);
});

Deno.test("no-pick: no members have pending picks — all returned", () => {
  assertEquals(findNoPickMemberIds(["u1", "u2", "u3"], []), ["u1", "u2", "u3"]);
});

Deno.test("no-pick: empty active members — none returned", () => {
  assertEquals(findNoPickMemberIds([], ["u1"]), []);
});

Deno.test("no-pick: member with only a void PST pick (no pending pick) — returned", () => {
  // u2 has a void pick (PST) but no pending pick for another fixture.
  // They did not repick, so they should be auto-eliminated (§3.3).
  assertEquals(findNoPickMemberIds(["u1", "u2"], ["u1"]), ["u2"]);
});
