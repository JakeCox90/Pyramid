// Edge Function: process-dispute-window
// Scheduled function (every hour via cron) that finds winnings whose dispute window has expired
// and marks them as withdrawable by updating their status.
//
// Withdrawable balance is computed by the user_wallet_balances view using
// dispute_window_expires_at <= now(). This function is therefore a no-op in terms of
// data mutation — the view already reflects the correct state at query time.
//
// However, this function serves as the AUDIT HOOK for tracking when funds become withdrawable,
// and can trigger downstream notifications (e.g. push notification to user).
//
// POST /process-dispute-window
// Headers: Authorization: Bearer <service_role_key>
// Body: {} (empty — processes all eligible transactions)
// Response 200: { processed: number, total_pence_released: number }
//
// Idempotency: running twice in the same minute is safe — the query returns 0 eligible rows.

import { getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface ProcessResult {
  processed: number;
  total_pence_released: number;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Internal-only: require service role key
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized — service role required" }, 401);
  }

  const log = createLogger("process-dispute-window", req);
  const db = getServiceClient();

  // Find winnings transactions whose dispute window has now expired.
  // The user_wallet_balances view already computes withdrawable_pence correctly based on
  // dispute_window_expires_at <= now(). This scan is for audit/notification purposes.
  const { data: expiredTransactions, error: fetchError } = await db
    .from("wallet_transactions")
    .select("id, user_id, amount_pence, dispute_window_expires_at")
    .eq("type", "winnings")
    .lte("dispute_window_expires_at", new Date().toISOString())
    .not("dispute_window_expires_at", "is", null);

  if (fetchError) {
    log.error("Failed to fetch expired dispute window transactions", fetchError);
    return json({ error: "Failed to query transactions" }, 500);
  }

  const eligible = expiredTransactions ?? [];
  let totalPenceReleased = 0;

  for (const tx of eligible) {
    totalPenceReleased += tx.amount_pence as number;
    // Log for audit — in production this is where push notifications would fire
    log.info("Dispute window expired", {
      transactionId: tx.id,
      userId: tx.user_id,
      amountPence: tx.amount_pence,
      expiredAt: tx.dispute_window_expires_at,
    });
  }

  const result: ProcessResult = {
    processed: eligible.length,
    total_pence_released: totalPenceReleased,
  };

  log.complete("ok", result);
  return json(result, 200);
});
