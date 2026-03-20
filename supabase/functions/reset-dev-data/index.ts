// Edge Function: reset-dev-data
// Resets the dev environment seed data by calling the dev_reset_data Postgres function.
// Protected by environment check and service role key validation.
//
// POST /reset-dev-data
// Headers: Authorization: Bearer <service-role-key>
// Body: { "mode": "game" | "full", "userId": "<uuid>" }
// Response 200: { success: true, mode: string, clearOnboarding: boolean }
// Response 403: { error: "Reset is only available in dev environment" }

import { corsHeaders, getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface ResetBody {
  mode: "game" | "full";
  userId: string;
}

interface ErrorResponse {
  error: string;
  code: string;
}

function errorResponse(
  message: string,
  code: string,
  status: number,
  origin: string | null,
): Response {
  const body: ErrorResponse = { error: message, code };
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const log = createLogger("reset-dev-data", req);

  // ── Environment guard ─────────────────────────────────────────────────────
  const environment = Deno.env.get("ENVIRONMENT");
  if (environment !== "dev") {
    log.warn("Reset attempted in non-dev environment", { environment });
    return errorResponse(
      "Reset is only available in dev environment",
      "FORBIDDEN",
      403,
      origin,
    );
  }

  // ── Service role key validation ───────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!authHeader || !serviceRoleKey) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  const token = authHeader.replace("Bearer ", "");
  if (token !== serviceRoleKey) {
    log.warn("Invalid service role key");
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  // ── Parse and validate body ───────────────────────────────────────────────
  let body: ResetBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { mode, userId } = body;

  if (mode !== "game" && mode !== "full") {
    return errorResponse(
      'mode must be "game" or "full"',
      "INVALID_BODY",
      400,
      origin,
    );
  }

  if (!userId || typeof userId !== "string") {
    return errorResponse("userId is required", "INVALID_BODY", 400, origin);
  }

  log.info("Starting dev reset", { mode, userId });

  // ── Call the Postgres function ────────────────────────────────────────────
  try {
    const supabase = getServiceClient();

    const { data, error } = await supabase.rpc("dev_reset_data", {
      p_mode: mode,
      p_caller_id: userId,
    });

    if (error) {
      log.error("RPC dev_reset_data failed", error);
      return errorResponse(
        error.message || "Reset failed",
        "RESET_FAILED",
        500,
        origin,
      );
    }

    log.complete("ok", { mode, userId });

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
    });
  } catch (err) {
    log.error("Unexpected error during reset", err);
    return errorResponse("Internal server error", "SERVER_ERROR", 500, origin);
  }
});
