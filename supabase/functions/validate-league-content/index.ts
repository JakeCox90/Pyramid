// Edge Function: validate-league-content
// Checks name/description against profanity word list.
//
// POST /validate-league-content
// Headers: Authorization: Bearer <user-jwt>
// Body: { name?: string, description?: string }
// Response 200: { valid: boolean, field?: string, reason?: string }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { responseHeaders } from "../_shared/supabase.ts";
import { validateLeagueContent } from "../_shared/profanity.ts";

function errorResponse(
  message: string,
  code: string,
  status: number,
  origin: string | null,
): Response {
  return new Response(
    JSON.stringify({ error: message, code }),
    {
      status,
      headers: responseHeaders(origin),
    },
  );
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: responseHeaders(origin) });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  // Authenticate user via JWT
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

  const { error: authError } = await userClient.auth.getUser();
  if (authError) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  let body: { name?: string; description?: string };
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const result = validateLeagueContent(body.name, body.description);

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
