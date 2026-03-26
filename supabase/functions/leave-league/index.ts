// Edge Function: leave-league
// Removes the authenticated user from a league.
//
// POST /leave-league  → body: { league_id: string } → confirm leave
//
// Errors (JSON): { error: string, code: 'NOT_MEMBER' | 'UNAUTHORIZED' | ... }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface LeaveResponse {
  league_id: string;
  left: true;
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

  const log = createLogger("leave-league", req);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return errorResponse("Server misconfiguration", "SERVER_ERROR", 500, origin);
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const user = await getAuthUser(req, supabaseUrl, supabaseAnonKey);
  if (!user) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  let body: { league_id: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const leagueId = body.league_id?.trim();
  if (!leagueId) {
    return errorResponse("league_id is required", "INVALID_BODY", 400, origin);
  }

  const db = getServiceClient();

  // ── Look up the membership row ──────────────────────────────────────────
  const { data: member, error: memberError } = await db
    .from("league_members")
    .select("id, league_id")
    .eq("league_id", leagueId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (memberError) {
    log.error("Failed to look up membership", memberError);
    return errorResponse("Failed to check membership", "LOOKUP_FAILED", 500, origin);
  }

  // Idempotent: if the member row doesn't exist, return success
  if (!member) {
    const response: LeaveResponse = { league_id: leagueId, left: true };
    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
    });
  }

  // ── Look up the league to check status and type ─────────────────────────
  const { data: league, error: leagueError } = await db
    .from("leagues")
    .select("id, status, type")
    .eq("id", leagueId)
    .maybeSingle();

  if (leagueError || !league) {
    log.error("Failed to look up league", leagueError);
    return errorResponse("League not found", "NOT_FOUND", 404, origin);
  }

  // ── Handle paid league refund logic ─────────────────────────────────────
  if (league.type === "paid" && league.status === "pending") {
    // TODO: Call refund-stake function to return the user's stake
    // e.g. await db.functions.invoke("refund-stake", { body: { league_id: leagueId, user_id: user.id } })
    log.info("Paid league in pending status — refund-stake should be called here");
  }
  // If paid and NOT pending, user forfeits stake — just delete the row (no refund)

  // ── Delete the membership row ───────────────────────────────────────────
  const { error: deleteError } = await db
    .from("league_members")
    .delete()
    .eq("id", member.id);

  if (deleteError) {
    log.error("Failed to delete membership", deleteError);
    return errorResponse("Failed to leave league", "LEAVE_FAILED", 500, origin);
  }

  const response: LeaveResponse = { league_id: leagueId, left: true };
  return new Response(JSON.stringify(response), {
    status: 200,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
});
