// Edge Function: update-profile
// Updates the authenticated user's display_name and/or avatar_url.
//
// PATCH /update-profile
// Headers: Authorization: Bearer <user-jwt>
// Body: { display_name?: string, avatar_url?: string }
// Response 200: { id, display_name, avatar_url, updated_at }
//
// Safety: display_name is visible in free league member lists always,
// but paid leagues use pseudonyms pre-deadline (§2.3). This function
// only writes to profiles — visibility is enforced by read-path functions.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { sanitizeString } from "../_shared/validation.ts";

const DISPLAY_NAME_MIN = 2;
const DISPLAY_NAME_MAX = 30;
const AVATAR_URL_MAX = 2048;

interface UpdateProfileBody {
  display_name?: string;
  avatar_url?: string;
}

interface ProfileResponse {
  id: string;
  display_name: string | null;
  avatar_url: string | null;
  updated_at: string;
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

function isValidUrl(str: string): boolean {
  try {
    const url = new URL(str);
    return url.protocol === "https:";
  } catch {
    return false;
  }
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: responseHeaders(origin) });
  }

  if (req.method !== "PATCH") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const log = createLogger("update-profile", req);

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

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return errorResponse("Unauthorized", "UNAUTHORIZED", 401, origin);
  }

  // Parse body
  let body: UpdateProfileBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  // Must provide at least one field
  const hasDisplayName = body.display_name !== undefined;
  const hasAvatarUrl = body.avatar_url !== undefined;

  if (!hasDisplayName && !hasAvatarUrl) {
    return errorResponse(
      "At least one of display_name or avatar_url is required",
      "NO_FIELDS",
      400,
      origin,
    );
  }

  // Validate display_name
  const updates: Record<string, unknown> = {};

  if (hasDisplayName) {
    if (body.display_name === null) {
      updates.display_name = null;
    } else {
      const trimmed = sanitizeString(body.display_name!, 30);
      if (trimmed.length < DISPLAY_NAME_MIN || trimmed.length > DISPLAY_NAME_MAX) {
        return errorResponse(
          `Display name must be between ${DISPLAY_NAME_MIN} and ${DISPLAY_NAME_MAX} characters`,
          "INVALID_DISPLAY_NAME",
          400,
          origin,
        );
      }
      updates.display_name = trimmed;
    }
  }

  // Validate avatar_url
  if (hasAvatarUrl) {
    if (body.avatar_url === null) {
      updates.avatar_url = null;
    } else {
      const url = body.avatar_url!.trim();
      if (url.length > AVATAR_URL_MAX) {
        return errorResponse(
          `Avatar URL must be at most ${AVATAR_URL_MAX} characters`,
          "INVALID_AVATAR_URL",
          400,
          origin,
        );
      }
      if (!isValidUrl(url)) {
        return errorResponse(
          "Avatar URL must be a valid HTTPS URL",
          "INVALID_AVATAR_URL",
          400,
          origin,
        );
      }
      updates.avatar_url = url;
    }
  }

  // Update profile via service client (RLS on profiles already restricts to own row,
  // but we use service client + explicit where clause for consistency with other functions)
  const db = getServiceClient();

  const { data: profile, error: updateError } = await db
    .from("profiles")
    .update(updates)
    .eq("id", user.id)
    .select("id, display_name, avatar_url, updated_at")
    .single();

  if (updateError) {
    log.error("Failed to update profile", updateError);
    return errorResponse("Failed to update profile", "UPDATE_FAILED", 500, origin);
  }

  const response: ProfileResponse = {
    id: profile.id,
    display_name: profile.display_name,
    avatar_url: profile.avatar_url,
    updated_at: profile.updated_at,
  };

  log.complete("ok", { userId: user.id });

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
