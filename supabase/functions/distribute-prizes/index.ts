// Edge Function: distribute-prizes
// Distributes prize pot to winners of a completed paid league round.
// Internal only — called by settle-picks (or manually by ops) after the round ends.
//
// POST /distribute-prizes
// Headers: Authorization: Bearer <service_role_key>
// Body: { leagueId: string }
// Response 200: { leagueId, allocations: [{userId, position, amountPence}] }
//
// Idempotency key: 'distribute-prizes:{leagueId}' in settlement_log.
//
// Atomicity note:
//   Supabase JS SDK does not support multi-statement transactions across separate
//   .from() calls. True DB-level atomicity would require a Postgres function (rpc).
//   We use defensive eventual-consistency instead:
//     1. Write the idempotency key to settlement_log FIRST (unique constraint).
//        If this fails with 23505 (duplicate), we know a prior run completed — return cached result.
//     2. Write wallet_transactions for each winner.
//     3. Update league_members finishing positions and prize amounts.
//     4. Update leagues.paid_status = 'complete'.
//   If steps 2–4 fail after step 1 succeeds, the idempotency key prevents double-payment
//   on retry, but the league/member records may be in a partial state. An ops-level
//   retry tool can re-run steps 2–4 directly (idempotency key already present, so
//   the wallet_transactions idempotency_key on each row prevents double-credit).
//   This is an acceptable trade-off for Phase 1. A future migration can introduce a
//   Postgres function for full atomicity.
//
// Prize allocation rules (docs/game-rules/rules.md §5.2):
//   65% to 1st, 25% to 2nd, 10% to 3rd.
//   Proportional redistribution when fewer than 3 positions filled.
//   Joint positions split evenly; penny remainder goes to next-better position.

import { createLogger } from "../_shared/logger.ts";
import { alertSlack } from "../_shared/alert.ts";
import { getServiceClient, serviceHeaders } from "../_shared/supabase.ts";
import { isUUID } from "../_shared/validation.ts";
import {
  computePrizeAllocations,
  determineFinishingPositions,
} from "./prize-distribution.ts";
import type { DbLeagueMember, PrizeAllocation } from "./prize-distribution.ts";

// ─── Types ────────────────────────────────────────────────────────────────────

interface RequestBody {
  leagueId: string;
}

interface LeagueRow {
  id: string;
  paid_status: string | null;
  prize_pot_pence: number | null;
  platform_fee_pence: number | null;
}

interface LeagueMemberRow {
  id: string;
  user_id: string;
  status: string;
  eliminated_gameweek: number | null;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: serviceHeaders(),
  });
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("distribute-prizes", req);

  // Internal-only: require service role key
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Forbidden — service role required" }, 403);
  }

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
  const idempotencyKey = `distribute-prizes:${leagueId}`;

  // ── 1. Idempotency check ──────────────────────────────────────────────────
  // Check if this league has already been processed.
  const { data: existingLog } = await db
    .from("settlement_log")
    .select("payload")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();

  if (existingLog) {
    log.info("already processed — returning cached result", { leagueId });
    const cached = existingLog.payload ? JSON.parse(existingLog.payload as string) : [];
    return json({ leagueId, allocations: cached, cached: true }, 200);
  }

  // ── 2. Fetch league ───────────────────────────────────────────────────────
  const { data: league, error: leagueErr } = await db
    .from("leagues")
    .select("id, paid_status, prize_pot_pence, platform_fee_pence")
    .eq("id", leagueId)
    .maybeSingle();

  if (leagueErr || !league) {
    return json({ error: "League not found", leagueId }, 404);
  }

  const leagueRow = league as LeagueRow;

  if (leagueRow.paid_status !== "active") {
    return json(
      {
        error: "League is not in active paid status",
        leagueId,
        paid_status: leagueRow.paid_status,
      },
      409,
    );
  }

  const grossPot = leagueRow.prize_pot_pence ?? 0;
  const platformFee = leagueRow.platform_fee_pence ?? 0;
  const netPot = grossPot - platformFee;

  if (netPot <= 0) {
    return json({ error: "Net pot is zero — nothing to distribute", leagueId, netPot }, 409);
  }

  // ── 3. Fetch league members ────────────────────────────────────────────────
  const { data: members, error: membersErr } = await db
    .from("league_members")
    .select("id, user_id, status, eliminated_gameweek")
    .eq("league_id", leagueId);

  if (membersErr) {
    return json({ error: `Failed to fetch members: ${membersErr.message}` }, 500);
  }

  const memberRows = (members ?? []) as LeagueMemberRow[];
  if (memberRows.length === 0) {
    return json({ error: "No members found in league", leagueId }, 404);
  }

  // Coerce DB rows to our pure-function type
  const dbMembers: DbLeagueMember[] = memberRows.map((m) => ({
    id: m.id,
    user_id: m.user_id,
    status: (m.status === "eliminated" ? "eliminated" : "active") as "active" | "eliminated",
    eliminated_gameweek: m.eliminated_gameweek,
  }));

  // ── 4. Compute allocations ─────────────────────────────────────────────────
  const playerResults = determineFinishingPositions(dbMembers);
  const allocations: PrizeAllocation[] = computePrizeAllocations(playerResults, netPot);

  if (allocations.length === 0) {
    return json({ error: "No prize allocations computed", leagueId }, 500);
  }

  // ── 5. Write idempotency log FIRST ────────────────────────────────────────
  // Writing this row first is the key atomicity defence:
  //   - If a concurrent request races us here, one will get 23505 (unique violation)
  //     and return early — preventing any double-payment.
  //   - If the wallet writes below fail, the log row stays, and the next retry will
  //     return the cached allocations without re-writing wallet_transactions (each
  //     wallet_transaction also has its own idempotency_key preventing double-credit).
  const { error: logError } = await db.from("settlement_log").insert({
    // fixture_id and gameweek_id are nullable for non-fixture settlements
    // (migration 20260308_prize_distribution_schema.sql drops the NOT NULL constraints).
    fixture_id: null,
    gameweek_id: null,
    league_id: leagueId,
    picks_processed: 0,
    eliminations: 0,
    survivors: allocations.filter((a) => a.position === 1).length,
    voids: 0,
    is_mass_elimination: false,
    idempotency_key: idempotencyKey,
    payload: JSON.stringify(allocations),
    notes: `Prize distribution: ${allocations.length} allocations, net pot ${netPot}p`,
  });

  if (logError) {
    if (logError.code === "23505") {
      // Concurrent run already wrote the log — return safely
      log.info("concurrent idempotency conflict — returning early", { leagueId });
      return json({ leagueId, allocations, cached: true }, 200);
    }
    log.error("failed to write settlement_log", logError, { leagueId });
    await alertSlack("distribute-prizes: settlement log write failed", { leagueId });
    return json({ error: "Failed to write settlement log" }, 500);
  }

  // ── 6. Write wallet_transactions ──────────────────────────────────────────
  const disputeWindowExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const now = new Date().toISOString();
  const errors: string[] = [];

  for (const allocation of allocations) {
    const txIdempotencyKey = `winnings:${leagueId}:${allocation.userId}`;
    const positionLabel = allocation.position === 1 ? "1st" : allocation.position === 2 ? "2nd" : "3rd";

    // Fetch current balance for snapshot
    const { data: wallet } = await db
      .from("user_wallet_balances")
      .select("available_to_play_pence")
      .eq("user_id", allocation.userId)
      .maybeSingle();

    const currentBalance = (wallet as { available_to_play_pence: number } | null)
      ?.available_to_play_pence ?? 0;
    const balanceAfter = currentBalance + allocation.amountPence;

    const { error: txError } = await db.from("wallet_transactions").insert({
      user_id: allocation.userId,
      type: "winnings",
      amount_pence: allocation.amountPence,
      balance_after_pence: balanceAfter,
      dispute_window_expires_at: disputeWindowExpiresAt,
      reference_id: leagueId,
      idempotency_key: txIdempotencyKey,
      notes: `Prize: ${positionLabel} place in league ${leagueId}`,
    });

    if (txError && txError.code !== "23505") {
      // 23505 = already credited on a prior partial run — safe to continue
      log.error("wallet_transactions insert failed", txError, { leagueId, userId: allocation.userId });
      errors.push(`wallet write failed for user ${allocation.userId}: ${txError.message}`);
    }
  }

  if (errors.length > 0) {
    // Partial failure — log for ops investigation but do not fail the response.
    // The idempotency key is already written, so a retry will not double-pay.
    log.error("partial wallet write failures", null, { leagueId, errors });
    await alertSlack("distribute-prizes: partial wallet write failures", { leagueId, errors });
  }

  // ── 7. Update league_members (finishing positions and prize amounts) ────────
  for (const allocation of allocations) {
    const { error: memberErr } = await db
      .from("league_members")
      .update({
        finishing_position: allocation.position,
        prize_pence: allocation.amountPence,
      })
      .eq("league_id", leagueId)
      .eq("user_id", allocation.userId);

    if (memberErr) {
      log.error("failed to update league_member", memberErr, { leagueId, userId: allocation.userId });
    }
  }

  // ── 8. Update league status ───────────────────────────────────────────────
  const { error: leagueUpdateErr } = await db
    .from("leagues")
    .update({
      paid_status: "complete",
      round_ended_at: now,
      status: "completed",
    })
    .eq("id", leagueId);

  if (leagueUpdateErr) {
    log.error("failed to update league status", leagueUpdateErr, { leagueId });
  }

  await log.complete("ok", { leagueId, allocations: allocations.length, netPot });

  return json({ leagueId, allocations }, 200);
});
