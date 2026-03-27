// Edge Function: submit-pick
// Submits or updates a player's pick for the current gameweek in a league.
// Idempotent: submitting the same pick twice returns success with no DB change.
//
// POST /submit-pick
// Headers: Authorization: Bearer <user-jwt>
// Body: { league_id: string, fixture_id: number, team_id: number, team_name: string }
// Response 200: { pick_id: string, team_name: string, fixture_id: number, is_locked: boolean }
//
// Error codes: UNAUTHORIZED | INVALID_BODY | NOT_MEMBER | ALREADY_ELIMINATED
//              MATCH_STARTED | PICK_LOCKED | TEAM_USED | GAMEWEEK_CLOSED

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { responseHeaders, getServiceClient } from "../_shared/supabase.ts";
import { isUUID, isPositiveInteger, sanitizeString } from "../_shared/validation.ts";
import { createLogger } from "../_shared/logger.ts";

interface SubmitPickBody {
  league_id: string;
  fixture_id: number;
  team_id: number;
  team_name: string;
}

interface SubmitPickResponse {
  pick_id: string;
  team_name: string;
  fixture_id: number;
  is_locked: boolean;
}

interface ErrorResponse {
  error: string;
  code: string;
}

function errorResponse(
  message: string,
  code: string,
  status: number,
  origin: string | null
): Response {
  const body: ErrorResponse = { error: message, code };
  return new Response(JSON.stringify(body), {
    status,
    headers: responseHeaders(origin),
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: responseHeaders(origin) });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const log = createLogger("submit-pick", req);

  // Authenticate user
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return errorResponse("Server misconfiguration", "SERVER_ERROR", 500, origin);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  // Parse body
  let body: SubmitPickBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { league_id, fixture_id, team_id, team_name } = body;
  if (!league_id || !fixture_id || !team_id || !team_name) {
    return errorResponse("Missing required fields", "INVALID_BODY", 400, origin);
  }

  if (!isUUID(league_id)) {
    return errorResponse("league_id must be a valid UUID", "INVALID_BODY", 400, origin);
  }
  if (!isPositiveInteger(fixture_id)) {
    return errorResponse("fixture_id must be a positive integer", "INVALID_BODY", 400, origin);
  }
  if (!isPositiveInteger(team_id)) {
    return errorResponse("team_id must be a positive integer", "INVALID_BODY", 400, origin);
  }

  const sanitizedTeamName = sanitizeString(team_name, 100);

  const db = getServiceClient();

  // 1. Verify user is an active member of the league
  const { data: member, error: memberError } = await db
    .from("league_members")
    .select("status")
    .eq("league_id", league_id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (memberError || !member) {
    return errorResponse("You are not a member of this league", "NOT_MEMBER", 403, origin);
  }

  if (member.status === "eliminated") {
    return errorResponse("You have been eliminated from this league", "ALREADY_ELIMINATED", 409, origin);
  }

  // 2. Look up fixture to get gameweek_id and kickoff time
  const { data: fixture, error: fixtureError } = await db
    .from("fixtures")
    .select("id, gameweek_id, kickoff_at, status, home_team_id, away_team_id")
    .eq("id", fixture_id)
    .maybeSingle();

  if (fixtureError || !fixture) {
    return errorResponse("Fixture not found", "FIXTURE_NOT_FOUND", 404, origin);
  }

  // 3a. Validate gameweek deadline (rules §3.3): no picks after the
  //     first fixture of the GW has kicked off.
  const gameweekIdForCheck = fixture.gameweek_id as number;
  const { data: gwDeadline } = await db
    .from("gameweeks")
    .select("deadline_at")
    .eq("id", gameweekIdForCheck)
    .maybeSingle();

  if (gwDeadline?.deadline_at) {
    const deadlineAt = new Date(gwDeadline.deadline_at as string);
    if (deadlineAt <= new Date()) {
      return errorResponse(
        "Gameweek is locked — the first match has kicked off",
        "GAMEWEEK_LOCKED",
        409,
        origin
      );
    }
  }

  // 3b. Validate individual fixture hasn't started
  const kickoffAt = new Date(fixture.kickoff_at as string);
  if (kickoffAt <= new Date()) {
    return errorResponse(
      "This match has already kicked off — pick deadline has passed",
      "MATCH_STARTED",
      409,
      origin
    );
  }

  // 4. Validate team belongs to this fixture
  if (team_id !== fixture.home_team_id && team_id !== fixture.away_team_id) {
    return errorResponse("Team is not part of this fixture", "INVALID_TEAM", 400, origin);
  }

  const gameweekId = fixture.gameweek_id as number;

  // 5. Check for existing pick this gameweek
  const { data: existingPick } = await db
    .from("picks")
    .select("id, team_id, fixture_id, is_locked")
    .eq("league_id", league_id)
    .eq("user_id", user.id)
    .eq("gameweek_id", gameweekId)
    .maybeSingle();

  if (existingPick) {
    // If locked, reject
    if (existingPick.is_locked) {
      return errorResponse("Your pick for this gameweek is locked", "PICK_LOCKED", 409, origin);
    }
    // If identical pick (idempotent), return success
    if (existingPick.team_id === team_id && existingPick.fixture_id === fixture_id) {
      const response: SubmitPickResponse = {
        pick_id: existingPick.id as string,
        team_name: sanitizedTeamName,
        fixture_id,
        is_locked: false,
      };
      return new Response(JSON.stringify(response), {
        status: 200,
        headers: responseHeaders(origin),
      });
    }
  }

  // 6. Check team not already used in a different gameweek this season
  const { data: usedTeams } = await db
    .from("used_teams")
    .select("team_id")
    .eq("league_id", league_id)
    .eq("user_id", user.id)
    .eq("team_id", team_id)
    .neq("gameweek_id", gameweekId);

  if (usedTeams && usedTeams.length > 0) {
    return errorResponse(
      `You already used ${team_name} this season`,
      "TEAM_USED",
      409,
      origin
    );
  }

  // 7. Upsert pick (insert or update the existing row for this GW)
  const { data: upsertedPick, error: upsertError } = await db
    .from("picks")
    .upsert(
      {
        league_id,
        user_id: user.id,
        gameweek_id: gameweekId,
        fixture_id,
        team_id,
        team_name: sanitizedTeamName,
        is_locked: false,
        result: "pending",
        submitted_at: new Date().toISOString(),
      },
      { onConflict: "league_id,user_id,gameweek_id" }
    )
    .select("id, is_locked")
    .single();

  if (upsertError || !upsertedPick) {
    log.error("Failed to upsert pick", upsertError);
    return errorResponse("Failed to submit pick", "SUBMIT_FAILED", 500, origin);
  }

  const response: SubmitPickResponse = {
    pick_id: upsertedPick.id as string,
    team_name: sanitizedTeamName,
    fixture_id,
    is_locked: upsertedPick.is_locked as boolean,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
