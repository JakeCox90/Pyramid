// Edge Function: sync-fixtures
// Syncs fixture list for one or all rounds of a PL season from API-Football into the DB.
// Called manually or via cron at season start / after postponements.
//
// POST /sync-fixtures
// Body: { round?: number, season?: number }
//   - round: omit to sync all 38 rounds (full season sync)
//   - season: defaults to CURRENT_SEASON (2025)
//
// This function is idempotent — safe to run multiple times.

import { ApiFootballClient, CURRENT_SEASON, parseRoundNumber, teamShortCode } from "../_shared/api-football.ts";
import { getServiceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  // Only allow POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
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

  let body: { round?: number; season?: number } = {};
  try {
    body = await req.json();
  } catch {
    // empty body is fine — default to full sync
  }

  const season = body.season ?? CURRENT_SEASON;
  const client = new ApiFootballClient(apiKey);
  const db = getServiceClient();

  try {
    let fixtures;

    if (body.round != null) {
      console.log(`Syncing round ${body.round}, season ${season}`);
      fixtures = await client.getFixturesByRound(body.round, season);
    } else {
      console.log(`Full season sync for season ${season}`);
      fixtures = await client.getAllFixturesBySeason(season);
    }

    if (fixtures.length === 0) {
      return new Response(JSON.stringify({ synced: 0, message: "No fixtures returned from API" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Group fixtures by round to upsert gameweeks first
    const roundMap = new Map<number, typeof fixtures>();
    for (const f of fixtures) {
      const roundNum = parseRoundNumber(f.league.round);
      if (roundNum == null) continue;
      const existing = roundMap.get(roundNum) ?? [];
      existing.push(f);
      roundMap.set(roundNum, existing);
    }

    let gameweeksUpserted = 0;
    let fixturesUpserted = 0;

    for (const [roundNum, roundFixtures] of roundMap) {
      // Earliest kickoff in this round = deadline
      const sortedByKickoff = [...roundFixtures].sort(
        (a, b) => new Date(a.fixture.date).getTime() - new Date(b.fixture.date).getTime(),
      );
      const deadline = sortedByKickoff[0].fixture.date;
      const isFinished = roundFixtures.every(
        (f) => ["FT", "AET", "PEN", "PST", "CANC", "ABD"].includes(f.fixture.status.short),
      );

      // Upsert gameweek
      const { data: gwData, error: gwError } = await db
        .from("gameweeks")
        .upsert(
          {
            season,
            round_number: roundNum,
            name: `Gameweek ${roundNum}`,
            deadline_at: deadline,
            is_finished: isFinished,
          },
          { onConflict: "season,round_number", ignoreDuplicates: false },
        )
        .select("id")
        .single();

      if (gwError) {
        console.error(`Failed to upsert gameweek ${roundNum}:`, gwError);
        continue;
      }

      gameweeksUpserted++;
      const gameweekId = gwData.id;

      // Upsert fixtures for this round
      const fixtureRows = roundFixtures.map((f) => ({
        id: f.fixture.id,
        gameweek_id: gameweekId,
        home_team_id: f.teams.home.id,
        home_team_name: f.teams.home.name,
        home_team_short: teamShortCode(f.teams.home.name),
        away_team_id: f.teams.away.id,
        away_team_name: f.teams.away.name,
        away_team_short: teamShortCode(f.teams.away.name),
        kickoff_at: f.fixture.date,
        status: f.fixture.status.short,
        home_score: f.goals.home,
        away_score: f.goals.away,
        raw_api_response: f,
      }));

      const { error: fixError, count } = await db
        .from("fixtures")
        .upsert(fixtureRows, { onConflict: "id", ignoreDuplicates: false })
        .select("id", { count: "exact", head: true });

      if (fixError) {
        console.error(`Failed to upsert fixtures for round ${roundNum}:`, fixError);
        continue;
      }

      fixturesUpserted += count ?? fixtureRows.length;
    }

    return new Response(
      JSON.stringify({
        synced: fixturesUpserted,
        gameweeks: gameweeksUpserted,
        season,
        round: body.round ?? "all",
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("sync-fixtures error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
