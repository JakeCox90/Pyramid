// Edge Function: get-league-stats
// Returns player counts, member summaries, and elimination stats for multiple
// leagues in a single call. Replaces 5N individual queries on the iOS client.
//
// POST /get-league-stats
// Headers: Authorization: Bearer <user-jwt>
// Body: { league_ids: string[], current_gameweek_id: number | null }
// Response 200: { leagues: Record<string, LeagueStats> }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate-limit.ts";
import { isUUID } from "../_shared/validation.ts";

// ─── Types ──────────────────────────────────────────────────────────────────

interface RequestBody {
  league_ids: string[];
  current_gameweek_id: number | null;
}

interface MemberSummary {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  status: string;
}

interface EliminationStats {
  eliminated_this_week: number;
  survival_streak: number;
  eliminated_gameweek_id: number | null;
}

interface PlayerCounts {
  active: number;
  total: number;
}

interface LeagueStats {
  player_counts: PlayerCounts;
  member_summaries: MemberSummary[];
  elimination_stats: EliminationStats;
}

interface SuccessResponse {
  leagues: Record<string, LeagueStats>;
}

interface ErrorResponse {
  error: string;
  code: string;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function errorResponse(
  message: string,
  code: string,
  status: number,
  origin: string | null,
): Response {
  const body: ErrorResponse = { error: message, code };
  return new Response(JSON.stringify(body), {
    status,
    headers: responseHeaders(origin),
  });
}

// ─── Main handler ───────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: responseHeaders(origin) });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const log = createLogger("get-league-stats", req);

  // ── Auth: user JWT
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

  const db = getServiceClient();

  // ── Rate limit
  const rateCheck = await checkRateLimit(db, user.id, "get-league-stats");
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!, origin);

  // ── Parse & validate body
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { league_ids, current_gameweek_id } = body;

  if (!Array.isArray(league_ids) || league_ids.length === 0) {
    return errorResponse("league_ids must be a non-empty array", "INVALID_BODY", 400, origin);
  }

  if (league_ids.length > 20) {
    return errorResponse("league_ids must have at most 20 entries", "INVALID_BODY", 400, origin);
  }

  for (const id of league_ids) {
    if (!isUUID(id)) {
      return errorResponse(`Invalid league_id: ${id}`, "INVALID_BODY", 400, origin);
    }
  }

  if (current_gameweek_id !== null && typeof current_gameweek_id !== "number") {
    return errorResponse("current_gameweek_id must be a number or null", "INVALID_BODY", 400, origin);
  }

  // ── Fetch all league members + profiles in one query
  const { data: members, error: membersError } = await db
    .from("league_members")
    .select(`
      league_id, user_id, status, eliminated_in_gameweek_id,
      profiles(username, display_name, avatar_url)
    `)
    .in("league_id", league_ids);

  if (membersError) {
    log.error("Failed to fetch league members", membersError);
    return errorResponse("Failed to fetch league data", "FETCH_FAILED", 500, origin);
  }

  // ── Build per-league data from the single query result
  const leagueMap: Record<string, {
    summaries: MemberSummary[];
    active: number;
    total: number;
    eliminatedThisWeek: number;
    userElimGwId: number | null;
    userIsEliminated: boolean;
  }> = {};

  // Initialise all requested leagues (even if they have no members)
  for (const lid of league_ids) {
    leagueMap[lid] = {
      summaries: [],
      active: 0,
      total: 0,
      eliminatedThisWeek: 0,
      userElimGwId: null,
      userIsEliminated: false,
    };
  }

  // deno-lint-ignore no-explicit-any
  for (const row of (members ?? []) as any[]) {
    const lid: string = row.league_id;
    const entry = leagueMap[lid];
    if (!entry) continue;

    const profile = row.profiles ?? {};
    const displayName: string = profile.display_name ?? profile.username ?? "Unknown";
    const avatarUrl: string | null = profile.avatar_url ?? null;
    const status: string = row.status;

    entry.summaries.push({
      user_id: row.user_id,
      display_name: displayName,
      avatar_url: avatarUrl,
      status,
    });

    entry.total += 1;

    if (status === "active" || status === "winner") {
      entry.active += 1;
    }

    // Count eliminated this week
    if (
      status === "eliminated" &&
      current_gameweek_id !== null &&
      row.eliminated_in_gameweek_id === current_gameweek_id
    ) {
      entry.eliminatedThisWeek += 1;
    }

    // Track user's own elimination info
    if (row.user_id === user.id && status === "eliminated") {
      entry.userElimGwId = row.eliminated_in_gameweek_id;
      entry.userIsEliminated = true;
    }
  }

  // ── Fetch survival streaks server-side (one RPC per league, in parallel)
  const streakPromises = league_ids.map(async (lid) => {
    const { data, error } = await db.rpc("get_survival_streak", {
      p_user_id: user.id,
      p_league_id: lid,
    });
    if (error) {
      log.warn(`Streak fetch failed for league ${lid}`, { error: error.message });
      return { lid, streak: 0 };
    }
    return { lid, streak: (data as number) ?? 0 };
  });

  const streakResults = await Promise.all(streakPromises);
  const streakMap: Record<string, number> = {};
  for (const { lid, streak } of streakResults) {
    streakMap[lid] = streak;
  }

  // ── Assemble response
  const leagues: Record<string, LeagueStats> = {};

  for (const lid of league_ids) {
    const entry = leagueMap[lid];
    leagues[lid] = {
      player_counts: {
        active: entry.active,
        total: entry.total,
      },
      member_summaries: entry.summaries,
      elimination_stats: {
        eliminated_this_week: entry.eliminatedThisWeek,
        survival_streak: streakMap[lid] ?? 0,
        eliminated_gameweek_id: entry.userElimGwId,
      },
    };
  }

  const response: SuccessResponse = { leagues };

  await log.complete("ok", {
    leagueCount: league_ids.length,
    totalMembers: members?.length ?? 0,
  });

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
