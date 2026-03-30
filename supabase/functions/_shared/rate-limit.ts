// Shared rate limiting module for Edge Functions.
// Uses a Postgres-backed fixed-window counter (no Redis dependency).
// Each user-facing function calls checkRateLimit() after auth, before business logic.

import { responseHeaders } from "./supabase.ts";

// ─── Rate limit configuration per function ──────────────────────────────────────

interface RateLimitConfig {
  maxRequests: number;
  windowSeconds: number;
}

export const RATE_LIMITS: Record<string, RateLimitConfig> = {
  "submit-pick":             { maxRequests: 10, windowSeconds: 60 },
  "create-league":           { maxRequests:  5, windowSeconds: 3600 },
  "join-league":             { maxRequests: 10, windowSeconds: 60 },
  "join-paid-league":        { maxRequests:  5, windowSeconds: 60 },
  "top-up":                  { maxRequests:  5, windowSeconds: 60 },
  "request-withdrawal":      { maxRequests:  3, windowSeconds: 60 },
  "get-wallet":              { maxRequests: 30, windowSeconds: 60 },
  "update-profile":          { maxRequests:  5, windowSeconds: 60 },
  "leave-league":            { maxRequests:  5, windowSeconds: 60 },
  "update-league":           { maxRequests:  5, windowSeconds: 60 },
  "register-device-token":   { maxRequests: 10, windowSeconds: 60 },
  "get-head-to-head":        { maxRequests: 30, windowSeconds: 60 },
  "validate-league-content": { maxRequests: 10, windowSeconds: 60 },
};

// ─── Rate limit check ───────────────────────────────────────────────────────────

interface RateLimitResult {
  allowed: boolean;
  retryAfter?: number;
}

/**
 * Checks the per-user rate limit for a function.
 * Returns { allowed: true } if under the limit, or { allowed: false, retryAfter: N }
 * with seconds until the window resets.
 *
 * @param db - Supabase service client
 * @param userId - Authenticated user ID
 * @param functionName - Edge Function name (must be a key in RATE_LIMITS)
 */
// deno-lint-ignore no-explicit-any
export async function checkRateLimit(
  db: any,
  userId: string,
  functionName: string,
): Promise<RateLimitResult> {
  const config = RATE_LIMITS[functionName];
  if (!config) {
    // No rate limit configured for this function — allow
    return { allowed: true };
  }

  const { data, error } = await db.rpc("check_rate_limit", {
    p_user_id: userId,
    p_function_name: functionName,
    p_max_requests: config.maxRequests,
    p_window_seconds: config.windowSeconds,
  }).single();

  if (error) {
    // If the rate limit check itself fails, allow the request through
    // rather than blocking legitimate users. Log for monitoring.
    console.error("[rate-limit] check failed, allowing request:", error.message);
    return { allowed: true };
  }

  if (!data.allowed) {
    return {
      allowed: false,
      retryAfter: data.retry_after_s as number,
    };
  }

  return { allowed: true };
}

// ─── 429 response helper ────────────────────────────────────────────────────────

/**
 * Returns a 429 Too Many Requests response with Retry-After header.
 */
export function rateLimitResponse(
  retryAfter: number,
  origin: string | null,
): Response {
  return new Response(
    JSON.stringify({
      error: "Too many requests. Please slow down.",
      code: "RATE_LIMITED",
    }),
    {
      status: 429,
      headers: {
        ...responseHeaders(origin),
        "Retry-After": String(retryAfter),
      },
    },
  );
}
