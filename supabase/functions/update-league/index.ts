// Edge Function: update-league
// Admin-only league update (name, description, color_palette, emoji).
//
// POST /update-league
// Headers: Authorization: Bearer <user-jwt>
// Body: { league_id: string, name?: string, description?: string,
//         color_palette?: string, emoji?: string }
// Response 200: { id, name, description, color_palette, emoji }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { isUUID, sanitizeString } from "../_shared/validation.ts";
import { createLogger } from "../_shared/logger.ts";
import { validateLeagueContent } from "../_shared/profanity.ts";

const VALID_PALETTES = ["primary"];
// Expand this array when Figma gradient palettes are designed

const VALID_EMOJIS = [
  "⚽", "🏆", "⚡", "🔥", "💀", "👑", "🎯", "🦁",
  "⭐", "💎", "🛡️", "🎪", "🍺", "🤝", "🏴", "🎲",
];

interface UpdateLeagueBody {
  league_id: string;
  name?: string;
  description?: string;
  color_palette?: string;
  emoji?: string;
}

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

  const log = createLogger("update-league", req);

  // Authenticate user
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

  let body: UpdateLeagueBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  if (!isUUID(body.league_id)) {
    return errorResponse("league_id is required", "MISSING_LEAGUE_ID", 400, origin);
  }

  const db = getServiceClient();

  // Verify caller is the league admin (created_by)
  const { data: league, error: fetchError } = await db
    .from("leagues")
    .select("id, created_by")
    .eq("id", body.league_id)
    .single();

  if (fetchError || !league) {
    return errorResponse("League not found", "NOT_FOUND", 404, origin);
  }

  if (league.created_by !== user.id) {
    return errorResponse("Only the league admin can edit", "FORBIDDEN", 403, origin);
  }

  // Validate fields
  const updates: Record<string, string | null> = {};

  if (body.name !== undefined) {
    const name = sanitizeString(body.name, 40);
    if (name.length < 3 || name.length > 40) {
      return errorResponse(
        "Name must be 3-40 characters",
        "INVALID_NAME",
        400,
        origin,
      );
    }
    updates.name = name;
  }

  if (body.description !== undefined) {
    const desc = sanitizeString(body.description, 80);
    if (desc.length > 80) {
      return errorResponse(
        "Description must be 80 characters or fewer",
        "INVALID_DESCRIPTION",
        400,
        origin,
      );
    }
    updates.description = desc || null;
  }

  // Content moderation (defense in depth)
  const modResult = validateLeagueContent(
    updates.name as string | undefined,
    (updates.description as string | undefined) ?? undefined,
  );
  if (!modResult.valid) {
    return new Response(JSON.stringify(modResult), {
      status: 400,
      headers: responseHeaders(origin),
    });
  }

  if (body.color_palette !== undefined) {
    if (!VALID_PALETTES.includes(body.color_palette)) {
      return errorResponse("Invalid color palette", "INVALID_PALETTE", 400, origin);
    }
    updates.color_palette = body.color_palette;
  }

  if (body.emoji !== undefined) {
    if (!VALID_EMOJIS.includes(body.emoji)) {
      return errorResponse("Invalid emoji", "INVALID_EMOJI", 400, origin);
    }
    updates.emoji = body.emoji;
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update", "NO_UPDATES", 400, origin);
  }

  // Update
  const { data: updated, error: updateError } = await db
    .from("leagues")
    .update(updates)
    .eq("id", body.league_id)
    .select("id, name, description, color_palette, emoji")
    .single();

  if (updateError) {
    log.error("Failed to update league", updateError);
    return errorResponse("Failed to update league", "UPDATE_FAILED", 500, origin);
  }

  return new Response(JSON.stringify(updated), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
