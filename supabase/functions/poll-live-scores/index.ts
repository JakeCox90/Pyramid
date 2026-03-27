// Edge Function: poll-live-scores
// Polls API-Football for live match scores and updates the fixtures table.
// Triggers settlement check for any match that just reached FT.
// After all fixtures are settled/voided, automatically advances to the next gameweek.
//
// Called by a Supabase cron job every 2 minutes during match windows.
// Called every 60 minutes outside of match windows (cron config handles scheduling).
//
// Safety rules (from ADR-003):
// 1. Never settle on non-FT status
// 2. If two consecutive FT polls return different scores, hold and alert — never settle on ambiguous data
// 3. All settlement ops are idempotent

import {
  ApiFootballClient,
  ApiFixture,
  CURRENT_SEASON,
  SETTLED_STATUSES,
  VOID_STATUSES,
} from "../_shared/api-football.ts";
import { getServiceClient, serviceHeaders, requireServiceRole } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { alertSlack } from "../_shared/alert.ts";

interface DbFixture {
  id: number;
  gameweek_id: number;
  status: string;
  home_score: number | null;
  away_score: number | null;
  settled_at: string | null;
}

Deno.serve(async (req) => {
  // Allow GET (from cron) or POST (manual trigger)
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: serviceHeaders(),
    });
  }

  const auth = requireServiceRole(req);
  if (!auth.authorized) return auth.errorResponse!;

  const log = createLogger("poll-live-scores", req);

  const apiKey = Deno.env.get("API_FOOTBALL_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "API_FOOTBALL_KEY not configured" }), {
      status: 500,
      headers: serviceHeaders(),
    });
  }

  const client = new ApiFootballClient(apiKey);
  const db = getServiceClient();

  try {
    // 1. Find the current gameweek
    const { data: currentGw, error: gwError } = await db
      .from("gameweeks")
      .select("id, round_number")
      .eq("season", CURRENT_SEASON)
      .eq("is_current", true)
      .single();

    if (gwError || !currentGw) {
      return new Response(
        JSON.stringify({ error: "No current gameweek found", detail: gwError?.message }),
        { status: 200, headers: serviceHeaders() },
      );
    }

    // 2. Fetch unsettled fixtures in the current gameweek
    const { data: dbFixtures, error: fixError } = await db
      .from("fixtures")
      .select("id, gameweek_id, status, home_score, away_score, settled_at")
      .eq("gameweek_id", currentGw.id)
      .is("settled_at", null) // only unsettled
      .not("status", "in", `(${VOID_STATUSES.join(",")})`); // skip voided

    if (fixError) throw new Error(`DB fetch error: ${fixError.message}`);

    // Process each unsettled fixture
    const results = {
      updated: 0,
      settlementTriggered: 0,
      heldForReview: 0,
      skipped: 0,
      gameweekAdvanced: false,
    };

    if (dbFixtures && dbFixtures.length > 0) {
      // 3. Fetch live data from API-Football
      const liveFixtures = await client.getLiveFixtures();

      // Also fetch by round to catch recently finished matches (live endpoint drops them)
      const roundFixtures = await client.getFixturesByRound(currentGw.round_number, CURRENT_SEASON);

      // Merge: live takes priority, round fills in the rest
      const apiFixtureMap = new Map<number, ApiFixture>();
      for (const f of roundFixtures) apiFixtureMap.set(f.fixture.id, f);
      for (const f of liveFixtures) apiFixtureMap.set(f.fixture.id, f); // overwrite with live

      for (const dbFix of dbFixtures as DbFixture[]) {
        const apiFix = apiFixtureMap.get(dbFix.id);
        if (!apiFix) {
          results.skipped++;
          continue;
        }

        const newStatus = apiFix.fixture.status.short;
        const newHomeScore = apiFix.goals.home;
        const newAwayScore = apiFix.goals.away;

        // Check if anything changed
        const statusChanged = newStatus !== dbFix.status;
        const scoreChanged = newHomeScore !== dbFix.home_score || newAwayScore !== dbFix.away_score;

        if (!statusChanged && !scoreChanged) {
          results.skipped++;
          continue;
        }

        // Safety check: if newly FT but previous poll had different FT score, hold
        if (
          SETTLED_STATUSES.includes(newStatus as never) &&
          dbFix.status === newStatus &&
          scoreChanged
        ) {
          // Score changed but status is already FT — data discrepancy, hold settlement
          log.warn("Score discrepancy — holding settlement", {
            fixtureId: dbFix.id,
            dbScore: `${dbFix.home_score}-${dbFix.away_score}`,
            apiScore: `${newHomeScore}-${newAwayScore}`,
          });
          await alertSlack("Score discrepancy detected", {
            fixtureId: dbFix.id,
            dbScore: `${dbFix.home_score}-${dbFix.away_score}`,
            apiScore: `${newHomeScore}-${newAwayScore}`,
          });
          // Update score but flag for review — do not trigger settlement
          await db.from("fixtures").update({
            home_score: newHomeScore,
            away_score: newAwayScore,
            status: newStatus,
            raw_api_response: apiFix,
            // settled_at deliberately not set — settlement will not fire
          }).eq("id", dbFix.id);

          results.heldForReview++;
          // TODO: send alert to Orchestrator (Slack / notification)
          continue;
        }

        // Update fixture in DB
        const { error: updateError } = await db.from("fixtures").update({
          status: newStatus,
          home_score: newHomeScore,
          away_score: newAwayScore,
          raw_api_response: apiFix,
        }).eq("id", dbFix.id);

        if (updateError) {
          log.error("Failed to update fixture", updateError, { fixtureId: dbFix.id });
          continue;
        }

        results.updated++;

        // 4. If now FT (or AET/PEN), trigger settlement
        if (SETTLED_STATUSES.includes(newStatus as never)) {
          const settlementResult = await triggerSettlement(db, dbFix.id, currentGw.id, log);
          if (settlementResult) results.settlementTriggered++;
        }
      }
    }

    // 5. Check if gameweek is complete and advance if so.
    // This runs on every poll so it catches the case where all fixtures were already
    // settled before this invocation (e.g. after a restart or manual re-run).
    const advanced = await maybeAdvanceGameweek(db, currentGw.id, currentGw.round_number, log);
    results.gameweekAdvanced = advanced;

    log.complete("ok", results);

    return new Response(JSON.stringify(results), {
      status: 200,
      headers: serviceHeaders(),
    });
  } catch (err) {
    console.error(err);
    log.error("poll-live-scores failed", err, {});
    await alertSlack("poll-live-scores failed", { error: String(err) });
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: serviceHeaders(),
    });
  }
});

/**
 * Trigger the settle-picks Edge Function for a fixture that just reached FT.
 * Returns true if the invocation succeeded.
 */
async function triggerSettlement(
  // deno-lint-ignore no-explicit-any
  db: any,
  fixtureId: number,
  gameweekId: number,
  // deno-lint-ignore no-explicit-any
  log: any,
): Promise<boolean> {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceKey) {
      log.error("Cannot trigger settlement: missing env vars", null, { fixtureId });
      return false;
    }

    const res = await fetch(`${supabaseUrl}/functions/v1/settle-picks`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({ fixtureId, gameweekId }),
    });

    if (!res.ok) {
      log.error("settle-picks returned error status", null, { fixtureId, status: res.status });
      return false;
    }

    log.info("Settlement triggered", { fixtureId });
    return true;
  } catch (err) {
    log.error("Failed to trigger settlement", err, { fixtureId });
    return false;
  }
}

/**
 * Check whether all fixtures in the current gameweek are done (settled or void),
 * and if so atomically advance to the next gameweek.
 * Exported for unit testing.
 *
 * A fixture is "done" when:
 *   - settled_at IS NOT NULL  (settlement has run), OR
 *   - status IN ('PST', 'CANC', 'ABD')  (void — no result to settle)
 *
 * Race condition safety: the UPDATE on the current GW uses
 *   WHERE is_finished = false
 * so concurrent poll invocations are no-ops after the first one succeeds.
 *
 * Off-season handling: if no next GW exists we mark the current one finished
 * and log — the season is over and no advancement is needed.
 *
 * Returns true if advancement actually happened (i.e. this invocation was the
 * one that flipped is_current), false otherwise (already done or not ready).
 */
export async function maybeAdvanceGameweek(
  // deno-lint-ignore no-explicit-any
  db: any,
  currentGwId: number,
  currentRoundNumber: number,
  // deno-lint-ignore no-explicit-any
  log: any,
): Promise<boolean> {
  // Count fixtures that are NOT yet done:
  //   - not settled (settled_at IS NULL)  AND
  //   - not void (status NOT IN VOID_STATUSES)
  const { count: pendingCount, error: pendingError } = await db
    .from("fixtures")
    .select("id", { count: "exact", head: true })
    .eq("gameweek_id", currentGwId)
    .is("settled_at", null)
    .not("status", "in", `(${VOID_STATUSES.join(",")})`);

  if (pendingError) {
    log.error("Failed to count pending fixtures", pendingError, { gameweekId: currentGwId });
    return false;
  }

  // If any fixtures are still pending, do not advance
  if (pendingCount !== 0) {
    return false;
  }

  // All fixtures are settled or void. Atomically mark this GW as finished.
  // The WHERE guard (is_finished = false) ensures only one concurrent poll wins.
  const { data: finishedRows, error: finishError } = await db
    .from("gameweeks")
    .update({ is_finished: true, is_current: false })
    .eq("id", currentGwId)
    .eq("is_finished", false) // WHERE guard — only the first caller flips this
    .select("id");

  if (finishError) {
    log.error("Failed to mark gameweek finished", finishError, { gameweekId: currentGwId });
    return false;
  }

  // If no rows were updated, another concurrent invocation already advanced — no-op
  if (!finishedRows || finishedRows.length === 0) {
    log.info("Gameweek already marked finished by concurrent invocation", { gameweekId: currentGwId });
    return false;
  }

  log.info("Gameweek marked finished", { gameweekId: currentGwId, round: currentRoundNumber });

  // Find the next gameweek (next round_number in the same season)
  const { data: nextGw, error: nextGwError } = await db
    .from("gameweeks")
    .select("id, round_number")
    .eq("season", CURRENT_SEASON)
    .eq("round_number", currentRoundNumber + 1)
    .single();

  if (nextGwError || !nextGw) {
    // Off-season or final gameweek — no next GW exists, season is over
    log.info("No next gameweek found — season may be complete", {
      currentRound: currentRoundNumber,
    });
    await alertSlack("Season complete — no next gameweek found", {
      finishedGameweekId: currentGwId,
      round: currentRoundNumber,
    });
    // Not an error — current GW is already marked finished above
    return true;
  }

  // Promote next GW to current
  const { error: promoteError } = await db
    .from("gameweeks")
    .update({ is_current: true })
    .eq("id", nextGw.id);

  if (promoteError) {
    log.error("Failed to promote next gameweek", promoteError, { nextGameweekId: nextGw.id });
    // Current GW is already marked finished — the next promotion failed.
    // Alert so a human can manually set is_current on the next GW.
    await alertSlack("Failed to promote next gameweek — manual intervention required", {
      finishedGameweekId: currentGwId,
      nextGameweekId: nextGw.id,
      error: promoteError.message,
    });
    return false;
  }

  log.info("Gameweek advanced", {
    from: { id: currentGwId, round: currentRoundNumber },
    to: { id: nextGw.id, round: nextGw.round_number },
  });

  return true;
}
