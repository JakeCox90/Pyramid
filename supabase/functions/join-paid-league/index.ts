// Edge Function: join-paid-league
// Authenticated user joins a paid public matchmaking league.
//
// POST /join-paid-league
// Headers: Authorization: Bearer <user-jwt>
// Body: {} (no required body fields — stake tier is always £5)
// Response 200: { league_id: string, pseudonym: string, status: "waiting"|"active", player_count: number }
//
// Logic:
//   1. Verify user has Available to Play >= £5 (500p). If not → 402.
//   2. Verify user is not already in 5 active paid leagues. If so → 409.
//   3. Find the least-full paid league with paid_status = 'waiting' and player_count < 30.
//      If none exists, create a new one.
//   4. Add user as a league member with pseudonym = "Player {n}" (join order).
//   5. Deduct £5 from Available to Play (wallet_transaction type = 'stake').
//   6. If player_count reaches 5 → set paid_status = 'active', round_started_at = now(),
//      compute prize_pot_pence and platform_fee_pence.
//   7. If player_count reaches 30 → league is full (still set to 'active').
//   8. Return { league_id, pseudonym, status, player_count }.
//
// Idempotency: duplicate join (same user, same league) → return existing membership.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getServiceClient, responseHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import {
  computeGrossPot,
  computeLeagueStatusAfterJoin,
  computePlatformFee,
  generatePseudonym,
  hasSufficientBalance,
  isAtLeagueCap,
  isLeagueFull,
  MAX_PLAYERS,
  MIN_PLAYERS,
  selectLeagueToJoin,
  STAKE_PENCE,
  type LeagueInfo,
  type PaidLeagueStatus,
} from "./matchmaking.ts";

const CURRENT_SEASON = 2025;

interface JoinPaidLeagueResponse {
  league_id: string;
  pseudonym: string;
  status: PaidLeagueStatus;
  player_count: number;
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

  const log = createLogger("join-paid-league", req);

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

  // ── 1. Check Available to Play balance ────────────────────────────────────
  const { data: wallet, error: walletError } = await db
    .from("user_wallet_balances")
    .select("available_to_play_pence")
    .eq("user_id", user.id)
    .maybeSingle();

  if (walletError) {
    log.error("Failed to fetch wallet balance", walletError);
    return errorResponse("Failed to fetch wallet balance", "FETCH_FAILED", 500, origin);
  }

  const availableToPlay = wallet?.available_to_play_pence ?? 0;
  if (!hasSufficientBalance(availableToPlay)) {
    return errorResponse(
      `Insufficient balance. Need £5 (${STAKE_PENCE}p), have ${availableToPlay}p. Please top up your wallet.`,
      "INSUFFICIENT_BALANCE",
      402,
      origin,
    );
  }

  // ── 2. Check 5-league cap ─────────────────────────────────────────────────
  // Count leagues where this user is a member and paid_status is 'waiting' or 'active'
  const { data: activeMemberships, error: membershipError } = await db
    .from("league_members")
    .select("league_id, leagues!inner(paid_status, type)")
    .eq("user_id", user.id)
    .in("leagues.paid_status", ["waiting", "active"])
    .eq("leagues.type", "paid");

  if (membershipError) {
    log.error("Failed to check active league memberships", membershipError);
    return errorResponse("Failed to check league memberships", "FETCH_FAILED", 500, origin);
  }

  const activePaidCount = (activeMemberships ?? []).length;
  if (isAtLeagueCap(activePaidCount)) {
    return errorResponse(
      "You are already in 5 active paid leagues. You can join another once one completes.",
      "LEAGUE_CAP_REACHED",
      409,
      origin,
    );
  }

  // ── 3. Find or create a league ────────────────────────────────────────────
  // Fetch all waiting paid leagues with their member counts
  const { data: waitingLeagues, error: leaguesError } = await db
    .from("leagues")
    .select("id, paid_status, league_members(count)")
    .eq("type", "paid")
    .eq("paid_status", "waiting");

  if (leaguesError) {
    log.error("Failed to fetch waiting leagues", leaguesError);
    return errorResponse("Failed to fetch available leagues", "FETCH_FAILED", 500, origin);
  }

  const leagueInfos: LeagueInfo[] = (waitingLeagues ?? []).map((l) => ({
    id: l.id as string,
    paid_status: l.paid_status as PaidLeagueStatus,
    player_count: (l.league_members as { count: number }[])?.[0]?.count ?? 0,
  }));

  let targetLeague = selectLeagueToJoin(leagueInfos);

  if (!targetLeague) {
    // No suitable league — create one
    const joinCode = generateJoinCode();
    const { data: newLeague, error: createError } = await db
      .from("leagues")
      .insert({
        name: `Paid League (${new Date().toISOString().slice(0, 10)})`,
        join_code: joinCode,
        type: "paid",
        status: "pending",        // existing enum field
        paid_status: "waiting",   // new paid lifecycle field
        stake_pence: STAKE_PENCE,
        created_by: user.id,
        season: CURRENT_SEASON,
        start_gameweek_id: await resolveCurrentGameweekId(db),
        max_players: MAX_PLAYERS,
      })
      .select("id, paid_status")
      .single();

    if (createError || !newLeague) {
      log.error("Failed to create new paid league", createError);
      return errorResponse("Failed to create league", "CREATE_FAILED", 500, origin);
    }

    targetLeague = {
      id: newLeague.id as string,
      paid_status: newLeague.paid_status as PaidLeagueStatus,
      player_count: 0,
    };
  }

  // ── 4. Check if user is already a member of this league (idempotent) ──────
  const { data: existingMember } = await db
    .from("league_members")
    .select("id, pseudonym")
    .eq("league_id", targetLeague.id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (existingMember) {
    // Already a member — return existing membership (idempotent)
    const { data: refreshedLeague } = await db
      .from("leagues")
      .select("paid_status, league_members(count)")
      .eq("id", targetLeague.id)
      .single();

    const currentCount = (refreshedLeague?.league_members as { count: number }[])?.[0]?.count ?? 0;

    return new Response(
      JSON.stringify({
        league_id: targetLeague.id,
        pseudonym: existingMember.pseudonym as string,
        status: (refreshedLeague?.paid_status ?? "waiting") as PaidLeagueStatus,
        player_count: currentCount,
      } satisfies JoinPaidLeagueResponse),
      { status: 200, headers: responseHeaders(origin) },
    );
  }

  // ── 5+6. Atomic: add member + deduct stake in a single Postgres transaction ─
  // Pseudonym is based on current count; the atomic function handles the insert.
  const pseudonym = generatePseudonym(targetLeague.player_count + 1);

  const { data: joinResult, error: joinError } = await db.rpc("atomic_join_paid_league", {
    p_user_id: user.id,
    p_league_id: targetLeague.id,
    p_pseudonym: pseudonym,
    p_stake_pence: STAKE_PENCE,
  }).single();

  if (joinError) {
    const msg = joinError.message ?? "";

    if (msg.includes("ALREADY_MEMBER") || joinError.code === "23505") {
      return errorResponse(
        "You are already a member of this league",
        "ALREADY_MEMBER",
        409,
        origin,
      );
    }

    if (msg.includes("INSUFFICIENT_BALANCE")) {
      return errorResponse(
        "Insufficient balance to cover the £5 stake. Please top up your wallet.",
        "INSUFFICIENT_BALANCE",
        402,
        origin,
      );
    }

    log.error("Atomic join failed", joinError, { userId: user.id, leagueId: targetLeague.id });
    return errorResponse("Failed to join league", "JOIN_FAILED", 500, origin);
  }

  const newPlayerCount: number = joinResult.new_player_count as number;

  const newStatus = computeLeagueStatusAfterJoin(newPlayerCount);
  const leagueFull = isLeagueFull(newPlayerCount);

  const leagueUpdate: Record<string, unknown> = {
    paid_status: newStatus,
  };

  if (newStatus === "active" && newPlayerCount === MIN_PLAYERS) {
    // Round just started — compute prize pot
    const grossPot = computeGrossPot(newPlayerCount);
    const platformFee = computePlatformFee(grossPot);
    leagueUpdate.round_started_at = new Date().toISOString();
    leagueUpdate.prize_pot_pence = grossPot;
    leagueUpdate.platform_fee_pence = platformFee;
    leagueUpdate.status = "active"; // also update the legacy status field
  } else if (leagueFull) {
    // League reached 30 — update prize pot to reflect final player count
    const grossPot = computeGrossPot(newPlayerCount);
    const platformFee = computePlatformFee(grossPot);
    leagueUpdate.prize_pot_pence = grossPot;
    leagueUpdate.platform_fee_pence = platformFee;
    leagueUpdate.status = "active";
  }

  const { error: updateError } = await db
    .from("leagues")
    .update(leagueUpdate)
    .eq("id", targetLeague.id);

  if (updateError) {
    log.error("Failed to update league status after join", updateError);
    // Non-fatal: member was added and stake deducted; status will be corrected on next join.
  }

  const response: JoinPaidLeagueResponse = {
    league_id: targetLeague.id,
    pseudonym,
    status: newStatus,
    player_count: newPlayerCount,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: responseHeaders(origin),
  });
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function generateJoinCode(): string {
  const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  return Array.from({ length: 6 }, () => ALPHABET[Math.floor(Math.random() * ALPHABET.length)]).join("");
}

// deno-lint-ignore no-explicit-any
async function resolveCurrentGameweekId(db: any): Promise<number> {
  const { data } = await db
    .from("gameweeks")
    .select("id")
    .eq("is_current", true)
    .maybeSingle();
  return (data?.id as number) ?? 1;
}
