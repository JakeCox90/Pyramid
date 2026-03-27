// Edge Function: get-wallet
// Returns the authenticated user's current wallet balances.
//
// GET /get-wallet
// Headers: Authorization: Bearer <user-jwt>
// Response 200: { available_to_play_pence: number, withdrawable_pence: number, pending_pence: number }
//
// Balances are computed from the user_wallet_balances view which aggregates wallet_transactions.
// pending_pence = winnings within the 24-hour dispute window (cannot be withdrawn, can be re-staked).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface WalletBalanceResponse {
  available_to_play_pence: number;
  withdrawable_pence: number;
  pending_pence: number;
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

  if (req.method !== "GET") {
    return errorResponse("Method not allowed", "METHOD_NOT_ALLOWED", 405, origin);
  }

  const log = createLogger("get-wallet", req);

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

  const db = getServiceClient();

  // Read from user_wallet_balances view
  const { data: wallet, error: walletError } = await db
    .from("user_wallet_balances")
    .select("available_to_play_pence, withdrawable_pence, pending_pence")
    .eq("user_id", user.id)
    .maybeSingle();

  if (walletError) {
    log.error("Failed to fetch wallet balances", walletError);
    return errorResponse("Failed to fetch wallet", "FETCH_FAILED", 500, origin);
  }

  // No transactions yet → all balances are zero
  const response: WalletBalanceResponse = {
    available_to_play_pence: wallet?.available_to_play_pence ?? 0,
    withdrawable_pence: wallet?.withdrawable_pence ?? 0,
    pending_pence: wallet?.pending_pence ?? 0,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
