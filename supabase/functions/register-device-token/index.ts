// Edge Function: register-device-token
// Called by the iOS app after APNs permission is granted.
// Upserts the device token for the authenticated user and creates a default
// notification_preferences row if one does not yet exist.
//
// POST /register-device-token
// Headers: Authorization: Bearer <user-jwt>
// Body: { token: string, platform: "ios" }
// Response 200: { registered: true }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate-limit.ts";
import { createLogger } from "../_shared/logger.ts";
import { isValidAPNsToken } from "../_shared/validation.ts";

interface RequestBody {
  token: string;
  platform?: string;
}

function json(body: unknown, status: number, origin: string | null): Response {
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
    return json({ error: "Method not allowed" }, 405, origin);
  }

  const log = createLogger("register-device-token", req);

  // Authenticate user via JWT
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Unauthorized" }, 401, origin);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return json({ error: "Server misconfiguration" }, 500, origin);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return json({ error: "Unauthorized" }, 401, origin);
  }

  // Parse and validate body
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400, origin);
  }

  const token = body.token?.trim();
  if (!token) {
    return json({ error: "token is required and must be non-empty" }, 400, origin);
  }

  if (!isValidAPNsToken(token)) {
    return json({ error: "Invalid APNs token format — expected 64 hex characters" }, 400, origin);
  }

  const platform = body.platform ?? "ios";

  if (platform !== "ios") {
    return json({ error: "Only 'ios' platform is supported" }, 400, origin);
  }

  const db = getServiceClient();

  // Rate limit check
  const rateCheck = await checkRateLimit(db, user.id, "register-device-token");
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!, origin);

  // Upsert device token — on conflict (user_id, token) update last_seen_at
  const { error: upsertErr } = await db.from("device_tokens").upsert(
    {
      user_id: user.id,
      token,
      platform,
      last_seen_at: new Date().toISOString(),
    },
    { onConflict: "user_id,token" },
  );

  if (upsertErr) {
    log.error("Upsert failed", upsertErr);
    return json({ error: "Failed to register device token" }, 500, origin);
  }

  // Upsert default notification_preferences if not exists
  // insert with ignoreDuplicates so an existing row is never overwritten
  const { error: prefErr } = await db.from("notification_preferences").upsert(
    {
      user_id: user.id,
      deadline_reminders: true,
      pick_locked: true,
      result_alerts: true,
      winnings_alerts: true,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id", ignoreDuplicates: true },
  );

  if (prefErr) {
    // Non-fatal: log and continue — token registration succeeded
    log.warn("notification_preferences upsert failed", { error: String(prefErr) });
  }

  return json({ registered: true }, 200, origin);
});
