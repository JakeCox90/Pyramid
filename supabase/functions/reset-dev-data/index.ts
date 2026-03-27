// Edge Function: reset-dev-data
// Resets the dev environment seed data by calling the dev_reset_data Postgres function.
// Protected by service-role auth and environment check.
//
// POST /reset-dev-data
// Headers: Authorization: Bearer <service-role-key>
// Body: { "mode": "game" | "full", "caller_id"?: "<uuid>" }
// Response 200: { success: true, mode: string, clearOnboarding: boolean }
// Response 403: { error: "Reset is only available in dev environment" }

import { getServiceClient, requireServiceRole, responseHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface ResetBody {
  mode: "game" | "full";
  caller_id?: string;
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

  // ── Service-role auth — only internal/admin callers can reset data ──────
  const auth = requireServiceRole(req);
  if (!auth.authorized) return auth.errorResponse!;

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

  // ── Parse and validate body ───────────────────────────────────────────────
  let body: ResetBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { mode } = body;

  if (mode !== "game" && mode !== "full") {
    return errorResponse(
      'mode must be "game" or "full"',
      "INVALID_BODY",
      400,
      origin,
    );
  }

  const callerId = body.caller_id ?? "00000000-0000-0000-0000-000000000000";
  log.info("Starting dev reset", { mode, callerId });

  // ── Call the Postgres function (via service role to bypass RLS) ──────────
  try {
    const supabase = getServiceClient();

    const { data, error } = await supabase.rpc("dev_reset_data", {
      p_mode: mode,
      p_caller_id: callerId,
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

    log.complete("ok", { mode, callerId });

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: responseHeaders(origin),
    });
  } catch (err) {
    log.error("Unexpected error during reset", err);
    return errorResponse("Internal server error", "SERVER_ERROR", 500, origin);
  }
});
