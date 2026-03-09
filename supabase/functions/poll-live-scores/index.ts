// Edge Function: poll-live-scores
// Polls API-Football for live match scores and updates the fixtures table.
// Triggers settlement check for any match that just reached FT.
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
import { getServiceClient } from "../_shared/supabase.ts";
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
      headers: { "Content-Type": "application/json" },
    });
  }

  const log = createLogger("poll-live-scores", req);

  const apiKey = Deno.env.get("API_FOOTBALL_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "API_FOOTBALL_KEY not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
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
        { status: 200, headers: { "Content-Type": "application/json" } },
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
    if (!dbFixtures || dbFixtures.length === 0) {
      return new Response(
        JSON.stringify({ updated: 0, message: "No unsettled fixtures in current gameweek" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // 3. Fetch live data from API-Football
    const liveFixtures = await client.getLiveFixtures();

    // Also fetch by round to catch recently finished matches (live endpoint drops them)
    const roundFixtures = await client.getFixturesByRound(currentGw.round_number, CURRENT_SEASON);

    // Merge: live takes priority, round fills in the rest
    const apiFixtureMap = new Map<number, ApiFixture>();
    for (const f of roundFixtures) apiFixtureMap.set(f.fixture.id, f);
    for (const f of liveFixtures) apiFixtureMap.set(f.fixture.id, f); // overwrite with live

    // 4. Process each unsettled fixture
    const results = {
      updated: 0,
      settlementTriggered: 0,
      heldForReview: 0,
      skipped: 0,
    };

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

      // 5. If now FT (or AET/PEN), trigger settlement
      if (SETTLED_STATUSES.includes(newStatus as never)) {
        const settlementResult = await triggerSettlement(db, dbFix.id, currentGw.id, log);
        if (settlementResult) results.settlementTriggered++;
      }
    }

    log.complete("ok", results);

    return new Response(JSON.stringify(results), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    log.error("poll-live-scores failed", err, {});
    await alertSlack("poll-live-scores failed", { error: String(err) });
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
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
