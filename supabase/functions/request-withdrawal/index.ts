// Edge Function: request-withdrawal
// Initiates a withdrawal from the user's Withdrawable balance.
//
// POST /request-withdrawal
// Headers: Authorization: Bearer <user-jwt>
// Body: { amount_pence: number }
// Response 200: { transaction_id: string, withdrawable_pence: number }
//
// Validation:
//   - Minimum withdrawal: £20 = 2000 pence (rules §8)
//   - Withdrawable balance must be sufficient
//   - Last withdrawal must be > 24 hours ago (rules §8: max 1 per day)
//
// Stripe payout is stubbed pending PYR-25 GATE resolution (no real Stripe account yet).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { responseHeaders, getServiceClient } from "../_shared/supabase.ts";
import { validateAmountPence } from "../_shared/validation.ts";
import { createLogger } from "../_shared/logger.ts";

const MIN_WITHDRAWAL_PENCE = 2000; // £20

interface WithdrawalBody {
  amount_pence: number;
}

interface WithdrawalResponse {
  transaction_id: string;
  withdrawable_pence: number;
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

  const log = createLogger("request-withdrawal", req);

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
  let body: WithdrawalBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { amount_pence } = body;

  const amountCheck = validateAmountPence(amount_pence, 1, 500000);
  if (!amountCheck.valid) {
    return errorResponse(amountCheck.error, "INVALID_AMOUNT", 400, origin);
  }

  // Minimum withdrawal: £20 (rules §8)
  if (amount_pence < MIN_WITHDRAWAL_PENCE) {
    return errorResponse(
      `Minimum withdrawal is £20 (${MIN_WITHDRAWAL_PENCE} pence)`,
      "AMOUNT_TOO_LOW",
      400,
      origin,
    );
  }

  const db = getServiceClient();

  // Check withdrawable balance
  const { data: wallet, error: walletError } = await db
    .from("user_wallet_balances")
    .select("withdrawable_pence")
    .eq("user_id", user.id)
    .maybeSingle();

  if (walletError) {
    log.error("Failed to fetch wallet balance", walletError);
    return errorResponse("Failed to fetch wallet balance", "FETCH_FAILED", 500, origin);
  }

  const withdrawable = wallet?.withdrawable_pence ?? 0;

  if (withdrawable < amount_pence) {
    return errorResponse(
      `Insufficient withdrawable balance. Available: ${withdrawable}p, requested: ${amount_pence}p`,
      "INSUFFICIENT_BALANCE",
      402,
      origin,
    );
  }

  // Check last withdrawal — max 1 per day (rules §8)
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { data: recentWithdrawal } = await db
    .from("wallet_transactions")
    .select("id, created_at")
    .eq("user_id", user.id)
    .eq("type", "withdrawal")
    .gte("created_at", oneDayAgo)
    .limit(1)
    .maybeSingle();

  if (recentWithdrawal) {
    return errorResponse(
      "Only one withdrawal per day is allowed (rules §8). Please try again tomorrow.",
      "WITHDRAWAL_RATE_LIMITED",
      429,
      origin,
    );
  }

  // TODO: initiate Stripe payout once PYR-25 GATE resolved.
  // When Stripe is live, this should:
  //   1. Look up the user's Stripe connected account / bank account ID (stored in profiles or a payment_methods table).
  //   2. Create a Stripe Transfer or Payout via the Stripe API.
  //   3. Store the Stripe payout_id in reference_id and notes.
  //   4. Withdrawal fee is passed through at cost — shown to user before confirmation.
  log.info(
    "TODO: initiate Stripe payout once PYR-25 GATE resolved",
    { userId: user.id, amount_pence },
  );

  // Write withdrawal transaction
  const balanceAfter = withdrawable - amount_pence;

  const { data: tx, error: txError } = await db
    .from("wallet_transactions")
    .insert({
      user_id: user.id,
      type: "withdrawal",
      amount_pence,
      balance_after_pence: balanceAfter,
      notes: "Withdrawal request — Stripe payout pending (stub: PYR-25 GATE not yet resolved)",
    })
    .select("id")
    .single();

  if (txError || !tx) {
    log.error("Failed to write withdrawal transaction", txError);
    return errorResponse("Failed to process withdrawal", "WITHDRAWAL_FAILED", 500, origin);
  }

  const response: WithdrawalResponse = {
    transaction_id: tx.id as string,
    withdrawable_pence: balanceAfter,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
