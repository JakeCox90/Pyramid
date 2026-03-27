// Edge Function: top-up
// Credits a user's Available to Play balance from a Stripe payment intent.
//
// POST /top-up
// Headers: Authorization: Bearer <user-jwt>
// Body: { stripe_payment_intent_id: string, amount_pence: number }
// Response 200: { transaction_id: string, available_to_play_pence: number }
//
// Stripe validation is stubbed pending PYR-25 GATE resolution (no real Stripe account yet).
// The idempotency_key ensures replaying the same payment_intent_id is a no-op.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { responseHeaders, getServiceClient } from "../_shared/supabase.ts";
import { validateAmountPence, isValidStripePaymentIntentId } from "../_shared/validation.ts";
import { createLogger } from "../_shared/logger.ts";

interface TopUpBody {
  stripe_payment_intent_id: string;
  amount_pence: number;
}

interface TopUpResponse {
  transaction_id: string;
  available_to_play_pence: number;
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

  const log = createLogger("top-up", req);

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

  // Parse and validate body
  let body: TopUpBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", "INVALID_BODY", 400, origin);
  }

  const { stripe_payment_intent_id, amount_pence } = body;

  if (!stripe_payment_intent_id || typeof stripe_payment_intent_id !== "string") {
    return errorResponse(
      "stripe_payment_intent_id is required",
      "INVALID_BODY",
      400,
      origin,
    );
  }

  if (!isValidStripePaymentIntentId(stripe_payment_intent_id)) {
    return errorResponse("Invalid stripe_payment_intent_id format", "INVALID_BODY", 400, origin);
  }

  const amountCheck = validateAmountPence(amount_pence, 1, 100000);
  if (!amountCheck.valid) {
    return errorResponse(amountCheck.error, "INVALID_AMOUNT", 400, origin);
  }

  // Minimum top-up: £5 = 500 pence (one league entry)
  if (amount_pence < 500) {
    return errorResponse(
      "Minimum top-up is £5 (500 pence)",
      "AMOUNT_TOO_LOW",
      400,
      origin,
    );
  }

  // TODO: validate against Stripe API once PYR-25 GATE resolved.
  // For now: validate that stripe_payment_intent_id is present and amount_pence > 0 (done above).
  // When Stripe is live, this should:
  //   1. Retrieve the PaymentIntent from Stripe API using the secret key.
  //   2. Assert pi.status === 'succeeded'.
  //   3. Assert pi.amount === amount_pence.
  //   4. Assert pi.currency === 'gbp'.
  //   5. Assert pi.metadata.user_id === user.id (set by iOS at intent creation time).
  log.info(
    "TODO: validate against Stripe API once PYR-25 GATE resolved",
    { stripe_payment_intent_id, amount_pence },
  );

  const db = getServiceClient();

  // Idempotency key: top_up:<payment_intent_id> — safe to replay
  const idempotencyKey = `top_up:${stripe_payment_intent_id}`;

  // Check for duplicate (idempotent replay)
  const { data: existing } = await db
    .from("wallet_transactions")
    .select("id")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();

  if (existing) {
    // Already processed — fetch current balance and return success
    const { data: wallet } = await db
      .from("user_wallet_balances")
      .select("available_to_play_pence")
      .eq("user_id", user.id)
      .maybeSingle();

    return new Response(
      JSON.stringify({
        transaction_id: existing.id as string,
        available_to_play_pence: wallet?.available_to_play_pence ?? 0,
      } satisfies TopUpResponse),
      { status: 200, headers: responseHeaders(origin) },
    );
  }

  // Fetch current available_to_play balance for balance_after_pence snapshot
  const { data: wallet } = await db
    .from("user_wallet_balances")
    .select("available_to_play_pence")
    .eq("user_id", user.id)
    .maybeSingle();

  const currentBalance = wallet?.available_to_play_pence ?? 0;
  const balanceAfter = currentBalance + amount_pence;

  // Write wallet_transaction
  const { data: tx, error: txError } = await db
    .from("wallet_transactions")
    .insert({
      user_id: user.id,
      type: "top_up",
      amount_pence,
      balance_after_pence: balanceAfter,
      idempotency_key: idempotencyKey,
      notes: `Stripe top-up: ${stripe_payment_intent_id}`,
    })
    .select("id")
    .single();

  if (txError || !tx) {
    // Could be a concurrent insert racing on the unique idempotency_key (23505) — safe to ignore
    if (txError?.code === "23505") {
      const { data: wallet2 } = await db
        .from("user_wallet_balances")
        .select("available_to_play_pence")
        .eq("user_id", user.id)
        .maybeSingle();

      return new Response(
        JSON.stringify({
          transaction_id: "duplicate",
          available_to_play_pence: wallet2?.available_to_play_pence ?? 0,
        } satisfies TopUpResponse),
        { status: 200, headers: responseHeaders(origin) },
      );
    }
    log.error("Failed to write wallet_transaction", txError);
    return errorResponse("Failed to process top-up", "TOP_UP_FAILED", 500, origin);
  }

  const response: TopUpResponse = {
    transaction_id: tx.id as string,
    available_to_play_pence: balanceAfter,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});
