// Edge Function: health
// Production health check endpoint for uptime monitoring.
//
// GET /health
// Headers: Authorization: Bearer <service-role-key>
// Response 200: { status: "healthy"|"degraded"|"unhealthy", checks: {...}, timestamp: string }
//
// Checks:
//   1. Database connectivity — simple SELECT 1
//   2. API-Football reachability — HEAD request to /status endpoint
//   3. Gameweek data freshness — is there a current gameweek with fixtures?
//   4. Settlement recency — has settle-picks run recently when expected?
//
// Auth: service-role only (internal monitoring, not user-facing).

import { getServiceClient } from "../_shared/supabase.ts";

const API_FOOTBALL_BASE = "https://v3.football.api-sports.io";

interface CheckResult {
  status: "pass" | "warn" | "fail";
  latency_ms: number;
  message?: string;
}

interface HealthResponse {
  status: "healthy" | "degraded" | "unhealthy";
  checks: Record<string, CheckResult>;
  timestamp: string;
  version: string;
}

function serviceHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "Cache-Control": "no-cache, no-store",
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: serviceHeaders() });
  }

  if (req.method !== "GET") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: serviceHeaders() },
    );
  }

  // Service-role auth
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();

  if (!serviceKey || token !== serviceKey) {
    return new Response(
      JSON.stringify({ error: "Unauthorized — service role required" }),
      { status: 401, headers: serviceHeaders() },
    );
  }

  const checks: Record<string, CheckResult> = {};

  // ── 1. Database connectivity ───────────────────────────────────────────────
  checks.database = await timedCheck(async () => {
    const db = getServiceClient();
    const { error } = await db.from("gameweeks").select("id").limit(1);
    if (error) throw new Error(`DB query failed: ${error.message}`);
    return { status: "pass" as const };
  });

  // ── 2. API-Football reachability ───────────────────────────────────────────
  const apiKey = Deno.env.get("API_FOOTBALL_KEY");
  if (apiKey) {
    checks.api_football = await timedCheck(async () => {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);
      try {
        const resp = await fetch(`${API_FOOTBALL_BASE}/status`, {
          headers: { "x-apisports-key": apiKey },
          signal: controller.signal,
        });
        clearTimeout(timeout);

        if (!resp.ok) {
          return { status: "fail" as const, message: `HTTP ${resp.status}` };
        }

        const data = await resp.json();
        const account = data?.response?.account;
        const requests = data?.response?.requests;

        // Check quota usage
        if (requests?.current && requests?.limit_day) {
          const usage = requests.current / requests.limit_day;
          if (usage > 0.9) {
            return {
              status: "warn" as const,
              message: `Quota ${Math.round(usage * 100)}% used (${requests.current}/${requests.limit_day})`,
            };
          }
          if (usage > 0.8) {
            return {
              status: "warn" as const,
              message: `Quota ${Math.round(usage * 100)}% used (${requests.current}/${requests.limit_day})`,
            };
          }
        }

        return {
          status: "pass" as const,
          message: account?.firstname
            ? `Account: ${account.firstname} — ${requests?.current ?? "?"}/${requests?.limit_day ?? "?"} requests today`
            : undefined,
        };
      } catch (err) {
        clearTimeout(timeout);
        if (err instanceof DOMException && err.name === "AbortError") {
          return { status: "fail" as const, message: "Timeout (5s)" };
        }
        throw err;
      }
    });
  } else {
    checks.api_football = {
      status: "warn",
      latency_ms: 0,
      message: "API_FOOTBALL_KEY not configured",
    };
  }

  // ── 3. Gameweek data freshness ─────────────────────────────────────────────
  checks.gameweek_data = await timedCheck(async () => {
    const db = getServiceClient();
    const { data: currentGw, error } = await db
      .from("gameweeks")
      .select("id, deadline_at")
      .eq("is_current", true)
      .maybeSingle();

    if (error) throw new Error(`Gameweek query failed: ${error.message}`);
    if (!currentGw) {
      return { status: "warn" as const, message: "No current gameweek set" };
    }

    // Check fixtures exist for this gameweek
    const { count, error: fixtureError } = await db
      .from("fixtures")
      .select("id", { count: "exact", head: true })
      .eq("gameweek_id", currentGw.id);

    if (fixtureError) throw new Error(`Fixture count failed: ${fixtureError.message}`);

    if (!count || count === 0) {
      return {
        status: "warn" as const,
        message: `GW ${currentGw.id} has 0 fixtures — sync may be needed`,
      };
    }

    return {
      status: "pass" as const,
      message: `GW ${currentGw.id}: ${count} fixtures, deadline ${currentGw.deadline_at}`,
    };
  });

  // ── 4. Settlement recency ──────────────────────────────────────────────────
  checks.settlement = await timedCheck(async () => {
    const db = getServiceClient();

    // Find most recent settlement log entry
    const { data: latestSettlement, error } = await db
      .from("settlement_log")
      .select("id, gameweek_id, settled_at")
      .order("settled_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw new Error(`Settlement query failed: ${error.message}`);

    if (!latestSettlement) {
      return { status: "pass" as const, message: "No settlements yet (new deployment)" };
    }

    // Check if there are FT fixtures that haven't been settled
    const { data: currentGw } = await db
      .from("gameweeks")
      .select("id")
      .eq("is_current", true)
      .maybeSingle();

    if (currentGw) {
      const { count: ftCount } = await db
        .from("fixtures")
        .select("id", { count: "exact", head: true })
        .eq("gameweek_id", currentGw.id)
        .eq("status", "FT");

      const { count: pendingPicks } = await db
        .from("picks")
        .select("id", { count: "exact", head: true })
        .eq("gameweek_id", currentGw.id)
        .eq("result", "pending")
        .eq("is_locked", true);

      if (ftCount && ftCount > 0 && pendingPicks && pendingPicks > 0) {
        // FT fixtures exist with unsettled picks — check how long ago
        const settledAt = new Date(latestSettlement.settled_at as string);
        const hoursSince = (Date.now() - settledAt.getTime()) / (1000 * 60 * 60);

        if (hoursSince > 6) {
          return {
            status: "warn" as const,
            message: `${pendingPicks} pending picks with FT results — last settlement ${Math.round(hoursSince)}h ago`,
          };
        }
      }
    }

    return {
      status: "pass" as const,
      message: `Last settlement: GW ${latestSettlement.gameweek_id} at ${latestSettlement.settled_at}`,
    };
  });

  // ── Aggregate status ───────────────────────────────────────────────────────
  const checkValues = Object.values(checks);
  const hasFail = checkValues.some((c) => c.status === "fail");
  const hasWarn = checkValues.some((c) => c.status === "warn");

  const overallStatus: HealthResponse["status"] = hasFail
    ? "unhealthy"
    : hasWarn
      ? "degraded"
      : "healthy";

  const response: HealthResponse = {
    status: overallStatus,
    checks,
    timestamp: new Date().toISOString(),
    version: Deno.env.get("DEPLOY_VERSION") ?? "dev",
  };

  const httpStatus = overallStatus === "unhealthy" ? 503 : 200;

  return new Response(JSON.stringify(response, null, 2), {
    status: httpStatus,
    headers: serviceHeaders(),
  });
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function timedCheck(
  fn: () => Promise<Omit<CheckResult, "latency_ms">>,
): Promise<CheckResult> {
  const start = performance.now();
  try {
    const result = await fn();
    return { ...result, latency_ms: Math.round(performance.now() - start) };
  } catch (err) {
    return {
      status: "fail",
      latency_ms: Math.round(performance.now() - start),
      message: err instanceof Error ? err.message : String(err),
    };
  }
}
