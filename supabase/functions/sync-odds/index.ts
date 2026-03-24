// Edge Function: sync-odds
// Fetches pre-match win probabilities from API-Football's /odds endpoint
// and stores them on the fixtures table.
//
// POST /sync-odds
// Body: { gameweek_id?: string }
//   - gameweek_id: sync odds for a specific gameweek's fixtures
//   - omit: sync odds for all upcoming NS (Not Started) fixtures
//
// This function is idempotent — safe to run multiple times.
// Designed to be called via cron ~24h before each gameweek deadline.

import { ApiFootballClient } from "../_shared/api-football.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

/**
 * Convert decimal odds to normalized implied probabilities.
 * Removes bookmaker overround so probabilities sum to 100%.
 */
function oddsToProb(
  homeOdds: number,
  drawOdds: number,
  awayOdds: number,
): { home_win_prob: number; draw_prob: number; away_win_prob: number } {
  const rawHome = 1 / homeOdds;
  const rawDraw = 1 / drawOdds;
  const rawAway = 1 / awayOdds;
  const total = rawHome + rawDraw + rawAway;

  return {
    home_win_prob: Math.round((rawHome / total) * 10000) / 100,
    draw_prob: Math.round((rawDraw / total) * 10000) / 100,
    away_win_prob: Math.round((rawAway / total) * 10000) / 100,
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const log = createLogger("sync-odds", req);

  // Service-role only
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const apiKey = Deno.env.get("API_FOOTBALL_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "API_FOOTBALL_KEY not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: { gameweek_id?: string } = {};
  try {
    body = await req.json();
  } catch {
    // empty body is fine — sync all upcoming
  }

  const client = new ApiFootballClient(apiKey);
  const db = getServiceClient();

  try {
    // Fetch fixtures that need odds
    let query = db
      .from("fixtures")
      .select("id")
      .eq("status", "NS")
      .is("home_win_prob", null);

    if (body.gameweek_id) {
      query = query.eq("gameweek_id", body.gameweek_id);
    }

    const { data: fixtures, error: fetchError } = await query;

    if (fetchError) {
      log.error("Failed to fetch fixtures", fetchError);
      return new Response(JSON.stringify({ error: "Failed to fetch fixtures" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!fixtures || fixtures.length === 0) {
      return new Response(
        JSON.stringify({ synced: 0, message: "No fixtures need odds" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    log.info("Fetching odds", { fixtureCount: fixtures.length });

    let synced = 0;
    let skipped = 0;

    for (const fixture of fixtures) {
      const oddsData = await client.getOdds(fixture.id);

      if (!oddsData || oddsData.bookmakers.length === 0) {
        log.info("No odds available", { fixtureId: fixture.id });
        skipped++;
        continue;
      }

      // Use first bookmaker's Match Winner bet
      const matchWinner = oddsData.bookmakers[0].bets
        .find((b) => b.id === 1 || b.name === "Match Winner");

      if (!matchWinner?.values) {
        log.info("No Match Winner bet found", { fixtureId: fixture.id });
        skipped++;
        continue;
      }

      const homeOdds = parseFloat(
        matchWinner.values.find((v) => v.value === "Home")?.odd ?? "0",
      );
      const drawOdds = parseFloat(
        matchWinner.values.find((v) => v.value === "Draw")?.odd ?? "0",
      );
      const awayOdds = parseFloat(
        matchWinner.values.find((v) => v.value === "Away")?.odd ?? "0",
      );

      if (homeOdds <= 0 || drawOdds <= 0 || awayOdds <= 0) {
        log.info("Invalid odds values", { fixtureId: fixture.id, homeOdds, drawOdds, awayOdds });
        skipped++;
        continue;
      }

      const probs = oddsToProb(homeOdds, drawOdds, awayOdds);

      const { error: updateError } = await db
        .from("fixtures")
        .update({
          home_win_prob: probs.home_win_prob,
          draw_prob: probs.draw_prob,
          away_win_prob: probs.away_win_prob,
        })
        .eq("id", fixture.id);

      if (updateError) {
        log.error("Failed to update fixture odds", updateError, { fixtureId: fixture.id });
        continue;
      }

      synced++;
    }

    return new Response(
      JSON.stringify({ synced, skipped, total: fixtures.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    log.error("sync-odds error", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
