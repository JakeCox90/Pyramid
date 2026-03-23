// Edge Function: get-head-to-head
// Returns the last N head-to-head meetings between two teams using API-Football.
// Called by the iOS client via the Supabase client SDK.
//
// POST /get-head-to-head
// Headers: Authorization: Bearer <service_role_key>
// Body: { homeTeamId: number, awayTeamId: number, last?: number }
// Response 200: { meetings: H2HMeeting[] }
//
// Caching: responses are cached in-memory for 24 hours keyed by team pair.
// H2H history doesn't change during a gameweek, so this is safe.

import {
  ApiFootballClient,
  toH2HMeeting,
} from "../_shared/api-football.ts";
import type { H2HMeeting } from "../_shared/api-football.ts";
import { createLogger } from "../_shared/logger.ts";

// ─── Types ──────────────────────────────────────────────────────────────────

interface RequestBody {
  homeTeamId: number;
  awayTeamId: number;
  last?: number;
}

interface SuccessResponse {
  meetings: H2HMeeting[];
  cached: boolean;
}

// ─── In-memory cache ────────────────────────────────────────────────────────
// Keyed by "teamA-teamB" (smaller ID first for consistency).
// TTL: 24 hours — H2H data doesn't change during a gameweek.

interface CacheEntry {
  meetings: H2HMeeting[];
  expiresAt: number;
}

const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const cache = new Map<string, CacheEntry>();

function cacheKey(teamId1: number, teamId2: number, last: number): string {
  const [a, b] = teamId1 < teamId2 ? [teamId1, teamId2] : [teamId2, teamId1];
  return `${a}-${b}:${last}`;
}

function getCached(key: string): H2HMeeting[] | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    cache.delete(key);
    return null;
  }
  return entry.meetings;
}

function setCache(key: string, meetings: H2HMeeting[]): void {
  cache.set(key, { meetings, expiresAt: Date.now() + CACHE_TTL_MS });
}

// ─── Helper ─────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Main handler ───────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("get-head-to-head", req);

  // Service-role auth — this endpoint is internal-only
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized — service role required" }, 401);
  }

  // Parse body
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { homeTeamId, awayTeamId, last } = body;
  if (!homeTeamId || !awayTeamId) {
    return json({ error: "homeTeamId and awayTeamId are required" }, 400);
  }

  if (typeof homeTeamId !== "number" || typeof awayTeamId !== "number") {
    return json({ error: "homeTeamId and awayTeamId must be numbers" }, 400);
  }

  const count = last ?? 5;
  if (typeof count !== "number" || count < 1 || count > 20) {
    return json({ error: "last must be a number between 1 and 20" }, 400);
  }

  // Check cache
  const key = cacheKey(homeTeamId, awayTeamId, count);
  const cached = getCached(key);
  if (cached) {
    log.complete("cache-hit", { homeTeamId, awayTeamId, count, meetings: cached.length });
    const response: SuccessResponse = { meetings: cached, cached: true };
    return json(response, 200);
  }

  // Fetch from API-Football
  const apiKey = Deno.env.get("API_FOOTBALL_KEY");
  if (!apiKey) {
    return json({ error: "API_FOOTBALL_KEY not configured" }, 500);
  }

  const client = new ApiFootballClient(apiKey);

  try {
    const h2hFixtures = await client.getHeadToHead(homeTeamId, awayTeamId, count);
    const meetings = h2hFixtures.map(toH2HMeeting);

    // Cache the result
    setCache(key, meetings);

    log.complete("ok", { homeTeamId, awayTeamId, count, meetings: meetings.length });
    const response: SuccessResponse = { meetings, cached: false };
    return json(response, 200);
  } catch (err) {
    log.error("get-head-to-head failed", err, { homeTeamId, awayTeamId });
    return json({ error: String(err) }, 500);
  }
});
