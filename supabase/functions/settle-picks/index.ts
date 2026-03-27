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
//   Picks keep result "survived" so that team counts as used this round.

import { getServiceClient, serviceHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { alertSlack } from "../_shared/alert.ts";
import { determinePickResult, findNoPickMemberIds, isGameweekFullySettled, hasSingleSurvivor, isFinalGameweek } from "./settlement.ts";
import { sendNotification } from "../_shared/send-notification.ts";
import type { DbFixture, DbPick, GwFixtureSummary } from "./settlement.ts";

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
  log: ReturnType<typeof createLogger>,
): Promise<{ survivors: number; eliminations: number; voids: number; isMassElim: boolean }> {
  const counts = { survivors: 0, eliminations: 0, voids: 0 };
  const eliminatedUserIds: string[] = [];

  for (const pick of picks) {
    const result = determinePickResult(pick, fixture);
    log.info("Settling pick", { pickId: pick.id, fixtureId: fixture.id, outcome: result });

    const { error: pickErr } = await db
      .from("picks")
      .update({ result, settled_at: new Date().toISOString() })
      .eq("id", pick.id);

    if (pickErr) {
      log.error("Pick update failed", pickErr, { pickId: pick.id });
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
        log.info("Auto-eliminating member — no valid pick (§3.3)", { userId, leagueId, gameweekId });
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
      log.info("Mass elimination — reinstating all GW eliminations", { leagueId, gameweekId });
      isMassElim = true;

      // Reinstate all members eliminated this gameweek
      await db
        .from("league_members")
        .update({ status: "active", eliminated_at: null, eliminated_in_gameweek_id: null })
        .eq("league_id", leagueId)
        .eq("eliminated_in_gameweek_id", gameweekId);

      // Mark reinstated picks as "survived" so the team IS counted as used (rules §4.5).
      // Players cannot pick the same team again this round even after a mass elimination.
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
    log.error("settlement_log insert failed", logErr, { leagueId });
  }

  return { ...counts, isMassElim };
}

// ─── Winner detection ─────────────────────────────────────────────────────────
//
// Fires after all picks in a GW are settled for a given league.
// Conditions for winner declaration (rules §4.4, §5.1):
//   1. The league is still "active" (not already "completed") — idempotent guard.
//   2. ALL fixtures in the gameweek are settled (settled_at IS NOT NULL) or in a
//      terminal non-played status (PST, CANC, ABD). Never fire on partial GW.
//   3. Exactly 1 active league_member remains after this settlement round.
//   4. Mass elimination did NOT just occur (all reinstatement case — no winner yet).
//
// GW38 hard cutoff (rules §5.3):
//   If the gameweek is GW38 (final PL round) and 2+ active members remain after
//   full settlement, ALL remaining active members become joint winners. The league
//   is completed. Prize split: 65% divided equally among joint winners.
//
// Returns true if a winner (or joint winners) was declared, false otherwise.

async function detectAndDeclareWinner(
  // deno-lint-ignore no-explicit-any
  db: any,
  leagueId: string,
  gameweekId: number,
  roundNumber: number,
  isMassElim: boolean,
  log: ReturnType<typeof createLogger>,
): Promise<boolean> {
  // Guard 1: mass elimination — all players reinstated, no winner yet.
  if (isMassElim) {
    log.info("Winner detection skipped — mass elimination round", { leagueId, gameweekId });
    return false;
  }

  // Guard 2: league must still be active (idempotent — skip if already completed).
  const { data: league, error: leagueErr } = await db
    .from("leagues")
    .select("id, name, status, type")
    .eq("id", leagueId)
    .maybeSingle();

  if (leagueErr || !league) {
    log.error("Winner detection: failed to fetch league", leagueErr, { leagueId });
    return false;
  }

  if (league.status === "completed") {
    log.info("Winner detection skipped — league already completed", { leagueId });
    return false;
  }

  // Guard 3: ALL fixtures in this gameweek must be settled or terminal-non-played.
  const { data: gwFixtures, error: fixErr } = await db
    .from("fixtures")
    .select("id, status, settled_at")
    .eq("gameweek_id", gameweekId);

  if (fixErr || !gwFixtures) {
    log.error("Winner detection: failed to fetch GW fixtures", fixErr, { gameweekId });
    return false;
  }

  const gwFixtureSummaries = gwFixtures as GwFixtureSummary[];
  if (!isGameweekFullySettled(gwFixtureSummaries)) {
    const terminalNonPlayed = new Set(["PST", "CANC", "ABD"]);
    log.info("Winner detection skipped — GW has unsettled fixtures", {
      leagueId,
      gameweekId,
      totalFixtures: gwFixtureSummaries.length,
      unsettled: gwFixtureSummaries.filter(
        (f) => f.settled_at === null && !terminalNonPlayed.has(f.status),
      ).length,
    });
    return false;
  }

  // ── Generate gameweek story (non-blocking, fire-and-forget) ──────────────
  // Fires only when ALL GW fixtures are settled for this league
  try {
    const storyResponse = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/generate-gameweek-story`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        },
        body: JSON.stringify({ leagueId, gameweek: gameweekId }),
      },
    );
    log.info("Story generation triggered", {
      leagueId,
      gameweek: gameweekId,
      status: storyResponse.status,
    });
  } catch (storyErr) {
    // Non-blocking: log and continue, settlement is already complete
    log.warn("Story generation call failed", {
      leagueId,
      gameweek: gameweekId,
      error: storyErr instanceof Error ? storyErr.message : String(storyErr),
    });
  }

  // Guard 4: count active members.
  const { data: activeMembers, error: memberErr } = await db
    .from("league_members")
    .select("id, user_id")
    .eq("league_id", leagueId)
    .eq("status", "active");

  if (memberErr) {
    log.error("Winner detection: failed to fetch active members", memberErr, { leagueId });
    return false;
  }

  const active = (activeMembers ?? []) as { id: string; user_id: string }[];

  // ── Single survivor → sole winner ──────────────────────────────────────────
  if (hasSingleSurvivor(active.length)) {
    return await declareSoleWinner(db, leagueId, active[0], league, gameweekId, log);
  }

  // ── GW38 hard cutoff → joint winners (rules §5.3) ─────────────────────────
  if (isFinalGameweek(roundNumber) && active.length >= 2) {
    return await declareJointWinners(db, leagueId, active, league, gameweekId, log);
  }

  log.info("Winner detection: game continues", {
    leagueId,
    gameweekId,
    roundNumber,
    activeCount: active.length,
  });
  return false;
}

// ─── Declare a sole winner ────────────────────────────────────────────────────

async function declareSoleWinner(
  // deno-lint-ignore no-explicit-any
  db: any,
  leagueId: string,
  winner: { id: string; user_id: string },
  league: { name: string; type: string },
  gameweekId: number,
  log: ReturnType<typeof createLogger>,
): Promise<boolean> {
  log.info("Winner detected — declaring sole winner", {
    leagueId,
    winnerId: winner.user_id,
    gameweekId,
  });

  const { error: memberUpdateErr } = await db
    .from("league_members")
    .update({ status: "winner" })
    .eq("id", winner.id)
    .eq("status", "active");

  if (memberUpdateErr) {
    log.error("Winner detection: failed to update member status", memberUpdateErr, {
      leagueId,
      memberId: winner.id,
    });
    await alertSlack("settle-picks: winner member update failed", {
      leagueId,
      memberId: winner.id,
      error: memberUpdateErr.message,
    });
    return false;
  }

  const { error: leagueUpdateErr } = await db
    .from("leagues")
    .update({ status: "completed" })
    .eq("id", leagueId)
    .eq("status", "active");

  if (leagueUpdateErr) {
    log.error("Winner detection: failed to update league status", leagueUpdateErr, { leagueId });
    await alertSlack("settle-picks: league completion update failed", {
      leagueId,
      error: leagueUpdateErr.message,
    });
    await db
      .from("league_members")
      .update({ status: "active" })
      .eq("id", winner.id)
      .eq("status", "winner");
    return false;
  }

  log.info("League marked completed", { leagueId, winnerId: winner.user_id });

  try {
    await sendNotification({
      userId: winner.user_id,
      template: "round_complete_winner",
      data: {
        leagueName: league.name,
        amount: league.type === "free" ? "0" : "",
      },
    });
  } catch (notifErr) {
    log.error("Winner notification failed (non-fatal)", notifErr, {
      leagueId,
      userId: winner.user_id,
    });
  }

  return true;
}

// ─── Declare joint winners (GW38 hard cutoff, rules §5.3) ────────────────────

async function declareJointWinners(
  // deno-lint-ignore no-explicit-any
  db: any,
  leagueId: string,
  winners: { id: string; user_id: string }[],
  league: { name: string; type: string },
  gameweekId: number,
  log: ReturnType<typeof createLogger>,
): Promise<boolean> {
  log.info("GW38 hard cutoff — declaring joint winners", {
    leagueId,
    gameweekId,
    jointWinnerCount: winners.length,
    winnerIds: winners.map((w) => w.user_id),
  });

  // Set all active members to winner status.
  const winnerMemberIds = winners.map((w) => w.id);
  const { error: memberUpdateErr } = await db
    .from("league_members")
    .update({ status: "winner" })
    .in("id", winnerMemberIds)
    .eq("status", "active");

  if (memberUpdateErr) {
    log.error("GW38 cutoff: failed to update member statuses", memberUpdateErr, {
      leagueId,
      count: winners.length,
    });
    await alertSlack("settle-picks: GW38 joint winner update failed", {
      leagueId,
      count: winners.length,
      error: memberUpdateErr.message,
    });
    return false;
  }

  // Set league to completed.
  const { error: leagueUpdateErr } = await db
    .from("leagues")
    .update({ status: "completed" })
    .eq("id", leagueId)
    .eq("status", "active");

  if (leagueUpdateErr) {
    log.error("GW38 cutoff: failed to update league status", leagueUpdateErr, { leagueId });
    await alertSlack("settle-picks: GW38 league completion failed", {
      leagueId,
      error: leagueUpdateErr.message,
    });
    // Rollback: revert all winners back to active.
    await db
      .from("league_members")
      .update({ status: "active" })
      .in("id", winnerMemberIds)
      .eq("status", "winner");
    return false;
  }

  log.info("League marked completed — GW38 joint winners", {
    leagueId,
    jointWinnerCount: winners.length,
  });

  // Notify all joint winners — fire-and-forget.
  for (const winner of winners) {
    try {
      await sendNotification({
        userId: winner.user_id,
        template: "round_complete_winner",
        data: {
          leagueName: league.name,
          amount: league.type === "free" ? "0" : "",
        },
      });
    } catch (notifErr) {
      log.error("Joint winner notification failed (non-fatal)", notifErr, {
        leagueId,
        userId: winner.user_id,
      });
    }
  }

  return true;
}

// ─── Match events fetch ───────────────────────────────────────────────────────

async function fetchMatchEvents(fixtureId: number, apiKey: string): Promise<any[] | null> {
  try {
    const resp = await fetch(
      `https://v3.football.api-sports.io/fixtures/events?fixture=${fixtureId}`,
      { headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": "v3.football.api-sports.io" } },
    );
    if (!resp.ok) return null;
    const data = await resp.json();
    return data?.response ?? null;
  } catch {
    return null;
  }
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("settle-picks", req);

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

  // ── 0. Fetch gameweek round_number for GW38 cutoff detection ───────────────
  const { data: gameweek, error: gwErr } = await db
    .from("gameweeks")
    .select("round_number")
    .eq("id", gameweekId)
    .maybeSingle();

  if (gwErr || !gameweek) {
    log.error("Failed to fetch gameweek", gwErr, { gameweekId });
    return json({ error: "Gameweek not found", gameweekId }, 404);
  }

  const roundNumber = (gameweek as { round_number: number }).round_number;

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
    log.error("Failed to fetch picks", picksErr, { fixtureId });
    await alertSlack("settle-picks failed", { fixtureId, error: picksErr.message });
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
    winnersDetected: 0,
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
      log.info("League already settled — skipping", { leagueId, fixtureId });
      summary.leaguesSkipped++;
      continue;
    }

    const result = await settleLeague(db, leagueId, picks, fixture as DbFixture, gameweekId, idempotencyKey, log);
    summary.survived += result.survivors;
    summary.eliminated += result.eliminations;
    summary.void += result.voids;
    if (result.isMassElim) summary.massEliminationLeagues++;
    summary.leaguesSettled++;

    // ── Winner detection (runs after each league is settled) ────────────────
    // Checks whether all GW fixtures are now settled and exactly 1 active
    // member remains. Also handles GW38 joint winners (§5.3).
    // Gated on isMassElim to prevent false positives (§4.5).
    const winnerDeclared = await detectAndDeclareWinner(
      db,
      leagueId,
      gameweekId,
      roundNumber,
      result.isMassElim,
      log,
    );
    if (winnerDeclared) summary.winnersDetected++;

    // ── Refresh user stats (fire-and-forget) ────────────────────────────────
    // Collect unique user IDs from settled picks and refresh their stats.
    // Stats refresh is non-critical — failure must NOT block settlement.
    const settledUserIds = [...new Set(picks.map((p) => p.user_id))];
    for (const userId of settledUserIds) {
      db.rpc("refresh_user_stats", { target_user_id: userId }).then(
        ({ error: statsErr }: { error: unknown }) => {
          if (statsErr) {
            log.error("refresh_user_stats failed (non-fatal)", statsErr, { userId, leagueId });
          }
        },
      ).catch((err: unknown) => {
        log.error("refresh_user_stats threw (non-fatal)", err, { userId, leagueId });
      });
    }

    // ── Achievement evaluation (fire-and-forget, non-critical) ──
    const apiKey = Deno.env.get("API_FOOTBALL_KEY") ?? "";
    const matchEvents = apiKey
      ? await fetchMatchEvents(fixture.id, apiKey).catch(() => null)
      : null;

    const matchEventsJson = matchEvents
      ? JSON.stringify(
          matchEvents
            .filter((e: any) => e.type === "Goal")
            .map((e: any) => ({
              minute: e.time?.elapsed ?? 0,
              team_id: e.team?.id ?? 0,
              type: "Goal",
            })),
        )
      : null;

    for (const userId of settledUserIds) {
      db.rpc("check_and_insert_achievements", {
        target_user_id: userId,
        target_league_id: leagueId,
        target_gameweek_id: gameweekId,
        match_events_json: matchEventsJson,
      })
        .then(({ error: achErr }: { error: unknown }) => {
          if (achErr) {
            log.error("check_and_insert_achievements failed (non-fatal)", achErr, { userId, leagueId });
          }
        })
        .catch((err: unknown) => {
          log.error("check_and_insert_achievements threw (non-fatal)", err, { userId, leagueId });
        });
    }
  }

  // ── 5. Mark fixture settled ───────────────────────────────────────────────
  // Include skipped leagues (idempotency) — if every league was already settled
  // on a prior run, we still need to mark settled_at or poll-live-scores retries
  // forever (§4.4).
  if (summary.leaguesSettled + summary.leaguesSkipped > 0) {
    await db.from("fixtures").update({ settled_at: new Date().toISOString() }).eq("id", fixtureId);
  }

  await log.complete("ok", summary);
  return json(summary, 200);
});

// ─── Helper ───────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: serviceHeaders(),
  });
}
