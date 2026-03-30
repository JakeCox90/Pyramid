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
import { checkRateLimit, rateLimitResponse } from "../_shared/rate-limit.ts";
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

  const amountCheck = validateAmountPence(amount_pence, 1, 50000);
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

  // Rate limit check
  const rateCheck = await checkRateLimit(db, user.id, "request-withdrawal");
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!, origin);

  // Idempotency key: one withdrawal per user per calendar day (UTC).
  // This deduplicates retries and enforces the 1-per-day rule at the DB level.
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const idempotencyKey = `withdrawal:${user.id}:${today}`;

  // TODO: initiate Stripe payout once PYR-25 GATE resolved.
  // When Stripe is live, this should:
  //   1. Look up the user's Stripe connected account / bank account ID.
  //   2. Create a Stripe Transfer or Payout via the Stripe API.
  //   3. Store the Stripe payout_id in reference_id and notes.
  //   4. Withdrawal fee is passed through at cost — shown to user before confirmation.
  log.info(
    "TODO: initiate Stripe payout once PYR-25 GATE resolved",
    { userId: user.id, amount_pence },
  );

  // Atomic withdrawal: balance check + cooldown + insert all inside a Postgres function
  // with pg_advisory_xact_lock to prevent concurrent race conditions.
  const { data: result, error: rpcError } = await db.rpc("atomic_withdrawal", {
    p_user_id: user.id,
    p_amount_pence: amount_pence,
    p_idempotency_key: idempotencyKey,
  }).single();

  if (rpcError) {
    const msg = rpcError.message ?? "";

    // Idempotency: duplicate key means same-day retry — return the existing transaction
    if (rpcError.code === "23505") {
      log.info("Duplicate withdrawal (idempotency hit)", { userId: user.id, idempotencyKey });
      const { data: existing } = await db
        .from("wallet_transactions")
        .select("id")
        .eq("idempotency_key", idempotencyKey)
        .single();
      const { data: wallet } = await db
        .from("user_wallet_balances")
        .select("withdrawable_pence")
        .eq("user_id", user.id)
        .maybeSingle();
      const response: WithdrawalResponse = {
        transaction_id: existing?.id as string ?? "unknown",
        withdrawable_pence: wallet?.withdrawable_pence ?? 0,
      };
      return new Response(JSON.stringify(response), {
        status: 200,
        headers: responseHeaders(origin),
      });
    }

    if (msg.includes("INSUFFICIENT_BALANCE")) {
      return errorResponse(
        "Insufficient withdrawable balance",
        "INSUFFICIENT_BALANCE",
        402,
        origin,
      );
    }

    if (msg.includes("WITHDRAWAL_RATE_LIMITED")) {
      return errorResponse(
        "Only one withdrawal per day is allowed (rules §8). Please try again tomorrow.",
        "WITHDRAWAL_RATE_LIMITED",
        429,
        origin,
      );
    }

    log.error("Withdrawal failed", rpcError, { userId: user.id, amount_pence });
    return errorResponse("Failed to process withdrawal", "WITHDRAWAL_FAILED", 500, origin);
  }

  const response: WithdrawalResponse = {
    transaction_id: result.transaction_id as string,
    withdrawable_pence: result.withdrawable_after_pence as number,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
