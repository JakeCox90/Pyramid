// Edge Function: create-league
// Creates a free league and adds the creator as the first member.
//
// POST /create-league
// Headers: Authorization: Bearer <user-jwt>
// Body: { name: string }
// Response 201: { league_id: string, join_code: string, name: string }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, getServiceClient } from "../_shared/supabase.ts";

const CURRENT_SEASON = 2025;
const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
const JOIN_CODE_LENGTH = 6;
const MAX_CODE_RETRIES = 5;

interface CreateLeagueBody {
  name: string;
}

interface CreateLeagueResponse {
  league_id: string;
  join_code: string;
  name: string;
}

interface ErrorResponse {
  error: string;
  code: string;
}

function generateJoinCode(): string {
  return Array.from({ length: JOIN_CODE_LENGTH }, () =>
    ALPHABET[Math.floor(Math.random() * ALPHABET.length)]
  ).join("");
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
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  // Authenticate user via JWT
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
  let body: CreateLeagueBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  // Validate name
  const name = body.name?.trim();
  if (!name || name.length < 3 || name.length > 40) {
    return errorResponse(
      "League name must be between 3 and 40 characters",
      "INVALID_NAME",
      400,
      origin
    );
  }

  const db = getServiceClient();

  // Resolve start gameweek (GW1 of current season)
  let { data: gameweek } = await db
    .from("gameweeks")
    .select("id")
    .eq("season", CURRENT_SEASON)
    .eq("round_number", 1)
    .maybeSingle();

  // Auto-create GW1 if it doesn't exist (dev convenience)
  if (!gameweek) {
    const { data: created } = await db
      .from("gameweeks")
      .upsert(
        { season: CURRENT_SEASON, round_number: 1, name: "Gameweek 1", is_current: true, is_finished: false },
        { onConflict: "season,round_number" }
      )
      .select("id")
      .single();
    gameweek = created;
  }

  const startGameweekId: number = gameweek?.id ?? 1;

  // Generate a unique join code (retry on collision)
  let joinCode = "";
  let leagueId = "";

  for (let attempt = 0; attempt < MAX_CODE_RETRIES; attempt++) {
    joinCode = generateJoinCode();

    const { data: league, error: insertError } = await db
      .from("leagues")
      .insert({
        name,
        join_code: joinCode,
        type: "free",
        status: "pending",
        created_by: user.id,
        season: CURRENT_SEASON,
        start_gameweek_id: startGameweekId,
      })
      .select("id")
      .single();

    if (insertError) {
      // Unique constraint violation on join_code → retry
      if (
        insertError.code === "23505" &&
        insertError.message.includes("join_code")
      ) {
        continue;
      }
      console.error("Failed to insert league:", insertError);
      return errorResponse("Failed to create league", "CREATE_FAILED", 500, origin);
    }

    leagueId = league.id as string;
    break;
  }

  if (!leagueId) {
    return errorResponse(
      "Failed to generate a unique join code",
      "JOIN_CODE_EXHAUSTED",
      500,
      origin
    );
  }

  // Add creator as first member
  const { error: memberError } = await db.from("league_members").insert({
    league_id: leagueId,
    user_id: user.id,
    status: "active",
  });

  if (memberError) {
    // Log but don't fail — league was created; member insert can be retried
    console.error("Failed to add creator as member:", memberError);
  }

  const response: CreateLeagueResponse = { league_id: leagueId, join_code: joinCode, name };

  return new Response(JSON.stringify(response), {
    status: 201,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
});
