// Edge Function: credit-winnings
// Credits a user's Available to Play balance with winnings from a completed league round.
// Internal only — called by distribute-prizes after round settlement.
//
// POST /credit-winnings
// Headers: Authorization: Bearer <service_role_key>
// Body: { user_id: string, amount_pence: number, league_id: string, round_id: string }
// Response 200: { transaction_id: string, available_to_play_pence: number, dispute_window_expires_at: string }
//
// Idempotency key: 'winnings:<league_id>:<round_id>:<user_id>'
// dispute_window_expires_at = now() + 24 hours (rules §6.2)

import { getServiceClient, serviceHeaders, requireServiceRole } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { isUUID } from "../_shared/validation.ts";

interface CreditWinningsBody {
  user_id: string;
  amount_pence: number;
  league_id: string;
  round_id: string;
}

interface CreditWinningsResponse {
  transaction_id: string;
  available_to_play_pence: number;
  dispute_window_expires_at: string;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: serviceHeaders(),
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("credit-winnings", req);

  // Internal-only: require service role key
  const auth = requireServiceRole(req);
  if (!auth.authorized) return auth.errorResponse!;

  let body: CreditWinningsBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { user_id, amount_pence, league_id, round_id } = body;

  if (!user_id || typeof user_id !== "string") {
    return json({ error: "user_id is required" }, 400);
  }
  if (!isUUID(user_id)) {
    return json({ error: "user_id must be a valid UUID" }, 400);
  }
  if (!amount_pence || typeof amount_pence !== "number" || amount_pence <= 0) {
    return json({ error: "amount_pence must be a positive integer" }, 400);
  }
  if (!league_id || typeof league_id !== "string") {
    return json({ error: "league_id is required" }, 400);
  }
  if (!isUUID(league_id)) {
    return json({ error: "league_id must be a valid UUID" }, 400);
  }
  if (!round_id || typeof round_id !== "string") {
    return json({ error: "round_id is required" }, 400);
  }
  if (!isUUID(round_id)) {
    return json({ error: "round_id must be a valid UUID" }, 400);
  }

  const db = getServiceClient();

  // Idempotency key: winnings:<league_id>:<round_id>:<user_id>
  const idempotencyKey = `winnings:${league_id}:${round_id}:${user_id}`;

  // Check for duplicate (idempotent replay)
  const { data: existing } = await db
    .from("wallet_transactions")
    .select("id, dispute_window_expires_at")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();

  if (existing) {
    const { data: wallet } = await db
      .from("user_wallet_balances")
      .select("available_to_play_pence")
      .eq("user_id", user_id)
      .maybeSingle();

    return json({
      transaction_id: existing.id as string,
      available_to_play_pence: wallet?.available_to_play_pence ?? 0,
      dispute_window_expires_at: existing.dispute_window_expires_at as string,
    } satisfies CreditWinningsResponse, 200);
  }

  // Dispute window: 24 hours from now (rules §6.2)
  const disputeWindowExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  // Fetch current balance for snapshot
  const { data: wallet } = await db
    .from("user_wallet_balances")
    .select("available_to_play_pence")
    .eq("user_id", user_id)
    .maybeSingle();

  const currentBalance = wallet?.available_to_play_pence ?? 0;
  const balanceAfter = currentBalance + amount_pence;

  // Write wallet_transaction
  const { data: tx, error: txError } = await db
    .from("wallet_transactions")
    .insert({
      user_id,
      type: "winnings",
      amount_pence,
      balance_after_pence: balanceAfter,
      dispute_window_expires_at: disputeWindowExpiresAt,
      reference_id: league_id,
      idempotency_key: idempotencyKey,
      notes: `Winnings for league ${league_id} round ${round_id}`,
    })
    .select("id")
    .single();

  if (txError || !tx) {
    // Concurrent insert on idempotency_key — treat as no-op
    if (txError?.code === "23505") {
      const { data: wallet2 } = await db
        .from("user_wallet_balances")
        .select("available_to_play_pence")
        .eq("user_id", user_id)
        .maybeSingle();

      return json({
        transaction_id: "duplicate",
        available_to_play_pence: wallet2?.available_to_play_pence ?? 0,
        dispute_window_expires_at: disputeWindowExpiresAt,
      } satisfies CreditWinningsResponse, 200);
    }
    log.error("Failed to write winnings transaction", txError);
    return json({ error: "Failed to credit winnings" }, 500);
  }

  return json({
    transaction_id: tx.id as string,
    available_to_play_pence: balanceAfter,
    dispute_window_expires_at: disputeWindowExpiresAt,
  } satisfies CreditWinningsResponse, 200);
});
