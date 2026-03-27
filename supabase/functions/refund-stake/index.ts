// Edge Function: refund-stake
// Refunds the £5 stake to all members of a paid league that never started
// (never reached the minimum 5 players within the sign-up window).
// Internal only — called by matchmaking or ops tooling.
//
// POST /refund-stake
// Headers: Authorization: Bearer <service_role_key>
// Body: { leagueId: string }
// Response 200: { leagueId, refundedCount: number }
//
// Idempotency key: 'refund-stake:{leagueId}' in settlement_log.
// Per-user idempotency: wallet_transactions.idempotency_key = 'stake_refund:{leagueId}:{userId}'
//
// Atomicity note:
//   Same eventual-consistency model as distribute-prizes.
//   Idempotency key is written to settlement_log first. Each wallet_transaction has its own
//   idempotency_key, so partial failures on retry do not produce double-refunds.
//   The league status is updated last; if that update fails, the league remains in 'waiting'
//   state and the function can be safely re-run.

import { getServiceClient, serviceHeaders, requireServiceRole } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { isUUID } from "../_shared/validation.ts";

// ─── Types ────────────────────────────────────────────────────────────────────

interface RequestBody {
  leagueId: string;
}

interface LeagueRow {
  id: string;
  paid_status: string | null;
  stake_pence: number | null;
}

interface LeagueMemberRow {
  id: string;
  user_id: string;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: serviceHeaders(),
  });
}

/** Fixed stake per player in pence (£5). Used as fallback if leagues.stake_pence is null. */
const DEFAULT_STAKE_PENCE = 5000;

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("refund-stake", req);

  // Internal-only: require service role key
  const auth = requireServiceRole(req);
  if (!auth.authorized) return auth.errorResponse!;

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { leagueId } = body;
  if (!leagueId || typeof leagueId !== "string") {
    return json({ error: "leagueId is required" }, 400);
  }
  if (!isUUID(leagueId)) {
    return json({ error: "leagueId must be a valid UUID" }, 400);
  }

  const db = getServiceClient();
  const idempotencyKey = `refund-stake:${leagueId}`;

  // ── 1. Idempotency check ──────────────────────────────────────────────────
  const { data: existingLog } = await db
    .from("settlement_log")
    .select("payload")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();

  if (existingLog) {
    const cached = existingLog.payload ? JSON.parse(existingLog.payload as string) : {};
    log.info("Already processed — returning cached result", { leagueId });
    return json({ leagueId, ...cached, cached: true }, 200);
  }

  // ── 2. Fetch league ───────────────────────────────────────────────────────
  const { data: league, error: leagueErr } = await db
    .from("leagues")
    .select("id, paid_status, stake_pence")
    .eq("id", leagueId)
    .maybeSingle();

  if (leagueErr || !league) {
    return json({ error: "League not found", leagueId }, 404);
  }

  const leagueRow = league as LeagueRow;

  if (leagueRow.paid_status !== "waiting") {
    return json(
      {
        error: "League is not in waiting status — cannot refund (may already be active or complete)",
        leagueId,
        paid_status: leagueRow.paid_status,
      },
      409,
    );
  }

  const stakePence = leagueRow.stake_pence ?? DEFAULT_STAKE_PENCE;

  // ── 3. Fetch all members ──────────────────────────────────────────────────
  const { data: members, error: membersErr } = await db
    .from("league_members")
    .select("id, user_id")
    .eq("league_id", leagueId);

  if (membersErr) {
    return json({ error: `Failed to fetch members: ${membersErr.message}` }, 500);
  }

  const memberRows = (members ?? []) as LeagueMemberRow[];
  const refundedCount = memberRows.length;

  // Leagues with 0 members can still be closed — just mark complete.
  // No wallet writes needed.

  // ── 4. Write idempotency log FIRST ────────────────────────────────────────
  // Prevents concurrent calls from double-refunding. See atomicity note in header.
  const payload = JSON.stringify({ refundedCount, stakePence });
  const { error: logError } = await db.from("settlement_log").insert({
    fixture_id: null,
    gameweek_id: null,
    league_id: leagueId,
    picks_processed: 0,
    eliminations: 0,
    survivors: 0,
    voids: 0,
    is_mass_elimination: false,
    idempotency_key: idempotencyKey,
    payload,
    notes: `Stake refund: ${refundedCount} members × ${stakePence}p — league never started`,
  });

  if (logError) {
    if (logError.code === "23505") {
      // Concurrent run already wrote the log
      log.info("Concurrent idempotency conflict — returning early", { leagueId });
      return json({ leagueId, refundedCount, cached: true }, 200);
    }
    log.error("Failed to write settlement_log", logError);
    return json({ error: "Failed to write settlement log" }, 500);
  }

  // ── 5. Write wallet_transactions (stake_refund) for each member ───────────
  const errors: string[] = [];

  for (const member of memberRows) {
    const txIdempotencyKey = `stake_refund:${leagueId}:${member.user_id}`;

    // Fetch current balance for audit snapshot
    const { data: wallet } = await db
      .from("user_wallet_balances")
      .select("available_to_play_pence")
      .eq("user_id", member.user_id)
      .maybeSingle();

    const currentBalance =
      (wallet as { available_to_play_pence: number } | null)?.available_to_play_pence ?? 0;
    const balanceAfter = currentBalance + stakePence;

    const { error: txError } = await db.from("wallet_transactions").insert({
      user_id: member.user_id,
      type: "stake_refund",
      amount_pence: stakePence,
      balance_after_pence: balanceAfter,
      dispute_window_expires_at: null, // refunds have no dispute window
      reference_id: leagueId,
      idempotency_key: txIdempotencyKey,
      notes: `Stake refund for league ${leagueId} — league cancelled (never started)`,
    });

    if (txError && txError.code !== "23505") {
      log.error("wallet_transactions insert failed", txError, { userId: member.user_id });
      errors.push(`wallet write failed for user ${member.user_id}: ${txError.message}`);
    }
  }

  if (errors.length > 0) {
    log.error("Partial wallet write failures", errors);
  }

  // ── 6. Update league status ───────────────────────────────────────────────
  // Use 'complete' to keep the paid_league_status enum simple (no separate 'cancelled' value).
  // The settlement_log notes field documents that this was a refund, not a prize distribution.
  // The leagues.status is set to 'cancelled' (existing league_status enum supports this).
  const { error: leagueUpdateErr } = await db
    .from("leagues")
    .update({
      paid_status: "complete",
      status: "cancelled",
      round_ended_at: new Date().toISOString(),
    })
    .eq("id", leagueId);

  if (leagueUpdateErr) {
    log.error("Failed to update league status", leagueUpdateErr);
  }

  log.info("Refund complete", { leagueId, refundedCount, stakePence });

  return json({ leagueId, refundedCount }, 200);
});
