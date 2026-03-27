// Shared Supabase client and response utilities for Edge Functions.
// Uses the service role key — never expose this to the iOS client.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Supabase client ─────────────────────────────────────────────────────────

export function getServiceClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !key) {
    throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set");
  }

  return createClient(url, key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

// ─── CORS ────────────────────────────────────────────────────────────────────
// Only origins in the allowlist receive Access-Control-Allow-Origin.
// Native iOS calls (URLSession) do not send an Origin header, so CORS is
// irrelevant for the mobile client. CORS only matters for browser-based
// callers (Supabase dashboard, potential future web app).

const DEFAULT_ALLOWED_ORIGINS: string[] = [
  // Dev Supabase project
  "https://qvmzmeizluqcdkcjsqyd.supabase.co",
  // Prod Supabase project
  "https://cracvbokmvryhhclzxxw.supabase.co",
  // Supabase Studio
  "https://supabase.com",
  // Local dev
  "http://localhost:3000",
  "http://localhost:54321",
];

let _cachedOrigins: Set<string> | null = null;
function getAllowedOrigins(): Set<string> {
  if (_cachedOrigins) return _cachedOrigins;
  const extra = Deno.env.get("ALLOWED_ORIGINS");
  const origins = [...DEFAULT_ALLOWED_ORIGINS];
  if (extra) {
    origins.push(...extra.split(",").map((o) => o.trim()).filter(Boolean));
  }
  _cachedOrigins = new Set(origins);
  return _cachedOrigins;
}

export function corsHeaders(origin: string | null): Record<string, string> {
  // No origin (server-to-server, native app) → no CORS header needed.
  if (!origin) {
    return {
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    };
  }

  const allowed = getAllowedOrigins();
  if (allowed.has(origin)) {
    return {
      "Access-Control-Allow-Origin": origin,
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    };
  }

  // Origin not in allowlist — omit Access-Control-Allow-Origin.
  // The browser will block the response (CORS failure).
  return {
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  };
}

// ─── Security headers ────────────────────────────────────────────────────────
// Applied to every response (user-facing and service-role).

export function securityHeaders(): Record<string, string> {
  return {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
    "Referrer-Policy": "strict-origin-when-cross-origin",
  };
}

// ─── Combined response headers ───────────────────────────────────────────────
// Use responseHeaders() for user-facing functions (CORS + security + JSON).
// Use serviceHeaders() for service-role functions (security + JSON, no CORS).

export function responseHeaders(origin: string | null): Record<string, string> {
  return {
    "Content-Type": "application/json",
    ...corsHeaders(origin),
    ...securityHeaders(),
  };
}

export function serviceHeaders(): Record<string, string> {
  return {
    "Content-Type": "application/json",
    ...securityHeaders(),
  };
}

// ─── Service-role auth guard ─────────────────────────────────────────────────
// Reusable check for internal-only functions (settle-picks, cron, etc.).

export function requireServiceRole(req: Request): { authorized: boolean; errorResponse?: Response } {
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return {
      authorized: false,
      errorResponse: new Response(
        JSON.stringify({ error: "Unauthorized — service role required" }),
        { status: 401, headers: serviceHeaders() },
      ),
    };
  }
  return { authorized: true };
}
