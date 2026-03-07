// Edge Function: settle-picks
// Settles all picks for a fixture that has reached FT (or PST/ABD) status.
// Called internally by poll-live-scores after each fixture reaches FT.
// NOT callable directly from the iOS client.
//
// POST /settle-picks
// Headers: Authorization: Bearer <service_role_key>
// Body: { fixtureId: number, gameweekId: number }
//
// Idempotency: per-league idempotency key (fixture:{id}:league:{id}) in
// settlement_log prevents double-processing even if called multiple times.
//
// Settlement rules (docs/game-rules/rules.md §4):
//   FT:  win → survived | draw/loss → eliminated
//   PST or ABD: pick voided → player survives, team not marked as used
//   No pick submitted (§3.3): player auto-eliminated when any GW match reaches FT.
//     Safety net — kick-off auto-elimination should fire in poll-live-scores first.
//     Members with a voided PST pick who did not repick are also caught here.
//   Mass elimination (§4.5): if all remaining active members in a league are
//   eliminated in the same GW → reinstate all, continue to next GW.
//   Picks keep result "survived" so that team counts as used this season.

import { getServiceClient } from "../_shared/supabase.ts";
import { determinePickResult, findNoPickMemberIds } from "./settlement.ts";
import type { DbFixture, DbPick } from "./settlement.ts";

// ─── Types ────────────────────────────────────────────────────────────────────

interface RequestBody {
  fixtureId: number;
  gameweekId: number;
}

// ─── Settle a single league ───────────────────────────────────────────────────

async function settleLeague(
  // deno-lint-ignore no-explicit-any
  db: any,
  leagueId: string,
  picks: DbPick[],
  fixture: DbFixture,
  gameweekId: number,
  idempotencyKey: string,
): Promise<{ survivors: number; eliminations: number; voids: number; isMassElim: boolean }> {
  const counts = { survivors: 0, eliminations: 0, voids: 0 };
  const eliminatedUserIds: string[] = [];

  for (const pick of picks) {
    const result = determinePickResult(pick, fixture);

    const { error: pickErr } = await db
      .from("picks")
      .update({ result, settled_at: new Date().toISOString() })
      .eq("id", pick.id);

    if (pickErr) {
      console.error(`pick ${pick.id} update failed:`, pickErr);
      continue;
    }

    if (result === "survived") {
      counts.survivors++;
    } else if (result === "eliminated") {
      counts.eliminations++;
      eliminatedUserIds.push(pick.user_id);

      await db
        .from("league_members")
        .update({
          status: "eliminated",
          eliminated_at: new Date().toISOString(),
          eliminated_in_gameweek_id: gameweekId,
        })
        .eq("league_id", leagueId)
        .eq("user_id", pick.user_id)
        .neq("status", "eliminated"); // idempotent guard
    } else {
      counts.voids++;
    }
  }

  // ── Auto-eliminate members with no valid GW pick (rules §3.3) ───────────────
  // Members who never submitted a pick, or who had a PST pick voided and did
  // not repick, have no pending pick for any GW fixture. They are eliminated.
  // This is a safety net — poll-live-scores should fire this at kick-off time.
  {
    const { data: stillActive } = await db
      .from("league_members")
      .select("user_id")
      .eq("league_id", leagueId)
      .eq("status", "active");

    if (stillActive && stillActive.length > 0) {
      const activeIds = (stillActive as { user_id: string }[]).map((m) => m.user_id);

      // A pending pick for any GW fixture means the member is not yet overdue.
      const { data: gwPendingPicks } = await db
        .from("picks")
        .select("user_id")
        .eq("league_id", leagueId)
        .eq("gameweek_id", gameweekId)
        .eq("result", "pending")
        .in("user_id", activeIds);

      const pendingIds = (gwPendingPicks ?? []).map((p: { user_id: string }) => p.user_id);
      const noPickIds = findNoPickMemberIds(activeIds, pendingIds);

      for (const userId of noPickIds) {
        console.log(
          `Auto-eliminating ${userId} in league ${leagueId} — no valid pick for GW${gameweekId} (§3.3)`,
        );
        await db
          .from("league_members")
          .update({
            status: "eliminated",
            eliminated_at: new Date().toISOString(),
            eliminated_in_gameweek_id: gameweekId,
          })
          .eq("league_id", leagueId)
          .eq("user_id", userId)
          .neq("status", "eliminated");
        counts.eliminations++;
        eliminatedUserIds.push(userId);
      }
    }
  }

  // ── Mass elimination check (rules §4.5) ───────────────────────────────────
  let isMassElim = false;
  if (eliminatedUserIds.length > 0) {
    const { data: active } = await db
      .from("league_members")
      .select("id")
      .eq("league_id", leagueId)
      .eq("status", "active");

    if ((active ?? []).length === 0) {
      console.log(`Mass elimination in league ${leagueId} — reinstating all GW${gameweekId} eliminations`);
      isMassElim = true;

      // Reinstate all members eliminated this gameweek
      await db
        .from("league_members")
        .update({ status: "active", eliminated_at: null, eliminated_in_gameweek_id: null })
        .eq("league_id", leagueId)
        .eq("eliminated_in_gameweek_id", gameweekId);

      // Mark reinstated picks as "survived" so the team IS counted as used (rules §4.5).
      // Players cannot pick the same team again this season even after a mass elimination.
      await db
        .from("picks")
        .update({ result: "survived" })
        .eq("league_id", leagueId)
        .eq("gameweek_id", gameweekId)
        .eq("result", "eliminated");
    }
  }

  // ── Write settlement_log ──────────────────────────────────────────────────
  const { error: logErr } = await db.from("settlement_log").insert({
    fixture_id: fixture.id,
    gameweek_id: gameweekId,
    league_id: leagueId,
    picks_processed: picks.length,
    eliminations: counts.eliminations,
    survivors: counts.survivors,
    voids: counts.voids,
    is_mass_elimination: isMassElim,
    idempotency_key: idempotencyKey,
    notes: isMassElim ? `Mass elimination — all GW${gameweekId} eliminations reinstated` : null,
  });

  if (logErr && logErr.code !== "23505") {
    // 23505 = unique_violation (concurrent run) — safe to ignore
    console.error(`settlement_log insert failed for league ${leagueId}:`, logErr);
  }

  return { ...counts, isMassElim };
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Internal-only: require service role key
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized — service role required" }, 401);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { fixtureId, gameweekId } = body;
  if (!fixtureId || !gameweekId) {
    return json({ error: "fixtureId and gameweekId are required" }, 400);
  }

  const db = getServiceClient();

  // ── 1. Fetch fixture ──────────────────────────────────────────────────────
  const { data: fixture, error: fixErr } = await db
    .from("fixtures")
    .select("id, status, home_team_id, away_team_id, home_score, away_score")
    .eq("id", fixtureId)
    .maybeSingle();

  if (fixErr || !fixture) {
    return json({ error: "Fixture not found", fixtureId }, 404);
  }

  const isSettleable = fixture.status === "FT" || fixture.status === "PST" || fixture.status === "ABD";
  if (!isSettleable) {
    return json({ error: "Fixture not in a settleable status", status: fixture.status }, 409);
  }

  // ── 2. Fetch all pending picks for this fixture ───────────────────────────
  const { data: allPicks, error: picksErr } = await db
    .from("picks")
    .select("id, league_id, user_id, team_id")
    .eq("fixture_id", fixtureId)
    .eq("result", "pending");

  if (picksErr) {
    return json({ error: `Failed to fetch picks: ${picksErr.message}` }, 500);
  }

  const pendingPicks = (allPicks ?? []) as DbPick[];
  if (pendingPicks.length === 0) {
    // No pending picks — still mark fixture settled to prevent re-checks
    await db.from("fixtures").update({ settled_at: new Date().toISOString() }).eq("id", fixtureId);
    return json({ message: "No pending picks for this fixture", fixtureId, picksProcessed: 0 }, 200);
  }

  // ── 3. Group picks by league ──────────────────────────────────────────────
  const picksByLeague = new Map<string, DbPick[]>();
  for (const pick of pendingPicks) {
    if (!picksByLeague.has(pick.league_id)) picksByLeague.set(pick.league_id, []);
    picksByLeague.get(pick.league_id)!.push(pick);
  }

  // ── 4. Settle each league ─────────────────────────────────────────────────
  const summary = {
    fixtureId,
    gameweekId,
    picksProcessed: pendingPicks.length,
    survived: 0,
    eliminated: 0,
    void: 0,
    massEliminationLeagues: 0,
    leaguesSettled: 0,
    leaguesSkipped: 0,
  };

  for (const [leagueId, picks] of picksByLeague) {
    const idempotencyKey = `fixture:${fixtureId}:league:${leagueId}`;

    // Per-league idempotency check
    const { data: existing } = await db
      .from("settlement_log")
      .select("id")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();

    if (existing) {
      console.log(`League ${leagueId} already settled for fixture ${fixtureId} — skipping`);
      summary.leaguesSkipped++;
      continue;
    }

    const result = await settleLeague(db, leagueId, picks, fixture as DbFixture, gameweekId, idempotencyKey);
    summary.survived += result.survivors;
    summary.eliminated += result.eliminations;
    summary.void += result.voids;
    if (result.isMassElim) summary.massEliminationLeagues++;
    summary.leaguesSettled++;
  }

  // ── 5. Mark fixture settled ───────────────────────────────────────────────
  // Include skipped leagues (idempotency) — if every league was already settled
  // on a prior run, we still need to mark settled_at or poll-live-scores retries
  // forever (§4.4).
  if (summary.leaguesSettled + summary.leaguesSkipped > 0) {
    await db.from("fixtures").update({ settled_at: new Date().toISOString() }).eq("id", fixtureId);
  }

  console.log("Settlement summary:", summary);
  return json(summary, 200);
});

// ─── Helper ───────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
