// Edge Function: join-league
// Validates a join code and adds the authenticated user to the league.
//
// GET  /join-league?code=ABC123  → preview (league info, member count)
// POST /join-league              → body: { code: string } → confirm join
//
// Errors (JSON): { error: string, code: 'NOT_FOUND' | 'ALREADY_MEMBER' | 'STARTED' | 'FULL' | ... }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface LeaguePreview {
  league_id: string;
  name: string;
  member_count: number;
  status: string;
  season: number;
}

interface JoinResponse {
  league_id: string;
  name: string;
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
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

async function getAuthUser(req: Request, supabaseUrl: string, supabaseAnonKey: string) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) return null;
  return user;
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  const log = createLogger("join-league", req);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return errorResponse("Server misconfiguration", "SERVER_ERROR", 500, origin);
  }

  const user = await getAuthUser(req, supabaseUrl, supabaseAnonKey);
  if (!user) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  const db = getServiceClient();

  // ── GET: league preview ───────────────────────────────────────────────────
  if (req.method === "GET") {
    const url = new URL(req.url);
    const code = url.searchParams.get("code")?.trim().toUpperCase();

    if (!code || code.length !== 6) {
      return errorResponse("Invalid join code format", "INVALID_CODE", 400, origin);
    }

    const { data: league, error: leagueError } = await db
      .from("leagues")
      .select("id, name, status, season")
      .eq("join_code", code)
      .maybeSingle();

    if (leagueError || !league) {
      return errorResponse("League not found", "NOT_FOUND", 404, origin);
    }

    // Count members
    const { count, error: countError } = await db
      .from("league_members")
      .select("id", { count: "exact", head: true })
      .eq("league_id", league.id);

    if (countError) {
      log.error("Failed to count members", countError);
    }

    const preview: LeaguePreview = {
      league_id: league.id as string,
      name: league.name as string,
      member_count: count ?? 0,
      status: league.status as string,
      season: league.season as number,
    };

    return new Response(JSON.stringify(preview), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
    });
  }

  // ── POST: confirm join ────────────────────────────────────────────────────
  if (req.method === "POST") {
    let body: { code: string };
    try {
      body = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
    }

    const code = body.code?.trim().toUpperCase();
    if (!code || code.length !== 6) {
      return errorResponse("Invalid join code format", "INVALID_CODE", 400, origin);
    }

    // Look up league
    const { data: league, error: leagueError } = await db
      .from("leagues")
      .select("id, name, status, max_players")
      .eq("join_code", code)
      .maybeSingle();

    if (leagueError || !league) {
      return errorResponse("League not found", "NOT_FOUND", 404, origin);
    }

    if (league.status !== "pending") {
      return errorResponse(
        "This league has already started",
        "STARTED",
        409,
        origin
      );
    }

    // Check capacity
    if (league.max_players != null) {
      const { count } = await db
        .from("league_members")
        .select("id", { count: "exact", head: true })
        .eq("league_id", league.id);

      if ((count ?? 0) >= (league.max_players as number)) {
        return errorResponse("This league is full", "FULL", 409, origin);
      }
    }

    // Insert member (unique constraint catches duplicate joins)
    const { error: insertError } = await db.from("league_members").insert({
      league_id: league.id,
      user_id: user.id,
      status: "active",
    });

    if (insertError) {
      if (
        insertError.code === "23505" &&
        insertError.message.includes("league_id")
      ) {
        return errorResponse(
          "You are already a member of this league",
          "ALREADY_MEMBER",
          409,
          origin
        );
      }
      log.error("Failed to insert member", insertError);
      return errorResponse("Failed to join league", "JOIN_FAILED", 500, origin);
    }

    const response: JoinResponse = {
      league_id: league.id as string,
      name: league.name as string,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
    });
  }

  return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
});
