// wallet.ts — Pure business logic for wallet operations.
// Extracted so it can be unit-tested without Deno.serve or DB dependencies.

export const MIN_TOP_UP_PENCE = 500; // £5
export const MIN_WITHDRAWAL_PENCE = 2000; // £20
export const DISPUTE_WINDOW_HOURS = 24;
export const PLATFORM_FEE_RATE = 0.08; // 8% (rules §5.4)

// ─── Balance types ─────────────────────────────────────────────────────────────

export interface WalletSnapshot {
  available_to_play_pence: number;
  withdrawable_pence: number;
  pending_pence: number; // winnings within dispute window
}

// ─── Balance computation ───────────────────────────────────────────────────────

export type TransactionType = "top_up" | "stake" | "stake_refund" | "winnings" | "withdrawal";

export interface Transaction {
  type: TransactionType;
  amount_pence: number;
  dispute_window_expires_at?: string | null; // only set for 'winnings'
}

/**
 * Computes wallet balances from a list of transactions.
 * Mirror of the user_wallet_balances view — used for unit testing the logic.
 */
export function computeBalances(
  transactions: Transaction[],
  now: Date = new Date(),
): WalletSnapshot {
  let availableToPlay = 0;
  let withdrawable = 0;
  let pending = 0;

  for (const tx of transactions) {
    switch (tx.type) {
      case "top_up":
        availableToPlay += tx.amount_pence;
        withdrawable += tx.amount_pence;
        break;
      case "stake_refund":
        availableToPlay += tx.amount_pence;
        withdrawable += tx.amount_pence;
        break;
      case "winnings": {
        availableToPlay += tx.amount_pence;
        const expiresAt = tx.dispute_window_expires_at
          ? new Date(tx.dispute_window_expires_at)
          : null;
        if (expiresAt && expiresAt <= now) {
          withdrawable += tx.amount_pence;
        } else {
          pending += tx.amount_pence;
        }
        break;
      }
      case "stake":
        availableToPlay -= tx.amount_pence;
        withdrawable -= tx.amount_pence;
        break;
      case "withdrawal":
        availableToPlay -= tx.amount_pence;
        withdrawable -= tx.amount_pence;
        break;
    }
  }

  return { available_to_play_pence: availableToPlay, withdrawable_pence: withdrawable, pending_pence: pending };
}

// ─── Top-up validation ─────────────────────────────────────────────────────────

export type TopUpValidationError =
  | "MISSING_PAYMENT_INTENT"
  | "INVALID_AMOUNT"
  | "AMOUNT_TOO_LOW";

export interface TopUpValidationResult {
  valid: boolean;
  error?: TopUpValidationError;
}

export function validateTopUp(
  stripePaymentIntentId: unknown,
  amountPence: unknown,
): TopUpValidationResult {
  if (!stripePaymentIntentId || typeof stripePaymentIntentId !== "string") {
    return { valid: false, error: "MISSING_PAYMENT_INTENT" };
  }
  if (typeof amountPence !== "number" || amountPence <= 0 || !Number.isInteger(amountPence)) {
    return { valid: false, error: "INVALID_AMOUNT" };
  }
  if (amountPence < MIN_TOP_UP_PENCE) {
    return { valid: false, error: "AMOUNT_TOO_LOW" };
  }
  return { valid: true };
}

// ─── Withdrawal validation ─────────────────────────────────────────────────────

export type WithdrawalValidationError =
  | "INVALID_AMOUNT"
  | "AMOUNT_TOO_LOW"
  | "INSUFFICIENT_BALANCE"
  | "RATE_LIMITED";

export interface WithdrawalValidationResult {
  valid: boolean;
  error?: WithdrawalValidationError;
}

export function validateWithdrawal(
  amountPence: unknown,
  withdrawableBalance: number,
  lastWithdrawalAt: Date | null,
  now: Date = new Date(),
): WithdrawalValidationResult {
  if (typeof amountPence !== "number" || amountPence <= 0 || !Number.isInteger(amountPence)) {
    return { valid: false, error: "INVALID_AMOUNT" };
  }
  if (amountPence < MIN_WITHDRAWAL_PENCE) {
    return { valid: false, error: "AMOUNT_TOO_LOW" };
  }
  if (withdrawableBalance < amountPence) {
    return { valid: false, error: "INSUFFICIENT_BALANCE" };
  }
  if (lastWithdrawalAt !== null) {
    const hoursSinceLast = (now.getTime() - lastWithdrawalAt.getTime()) / (1000 * 60 * 60);
    if (hoursSinceLast < 24) {
      return { valid: false, error: "RATE_LIMITED" };
    }
  }
  return { valid: true };
}

// ─── Prize distribution ────────────────────────────────────────────────────────

export interface PrizeShare {
  user_id: string;
  position: 1 | 2 | 3;
  amount_pence: number;
}

/**
 * Calculates prize distribution for a completed paid league round.
 * Rules §5: 65% / 25% / 10%. Joint winners split their position's share equally.
 * If fewer than 3 positions exist, the pot is redistributed proportionally.
 * Penny remainders go to the 1st position group (highest priority).
 *
 * @param grossPotPence  Total stakes collected (player_count × 5000)
 * @param winners1st     user_ids of 1st-place finishers
 * @param winners2nd     user_ids of 2nd-place finishers (may be empty)
 * @param winners3rd     user_ids of 3rd-place finishers (may be empty)
 */
export function distributePrizes(
  grossPotPence: number,
  winners1st: string[],
  winners2nd: string[],
  winners3rd: string[],
): PrizeShare[] {
  if (winners1st.length === 0) {
    throw new Error("distributePrizes: winners1st must not be empty");
  }

  const netPot = Math.floor(grossPotPence * (1 - PLATFORM_FEE_RATE));

  // Base shares per position (weights: 65 / 25 / 10)
  const positionWeights: [number, string[], 1 | 2 | 3][] = [
    [65, winners1st, 1],
    [25, winners2nd, 2],
    [10, winners3rd, 3],
  ];

  // Filter to filled positions only
  const filledPositions = positionWeights.filter(([, users]) => users.length > 0);

  // Redistribute proportionally if fewer than 3 positions are filled (rules §5.2)
  const totalWeight = filledPositions.reduce((sum, [w]) => sum + w, 0);

  const shares: PrizeShare[] = [];
  let distributed = 0;

  for (let i = 0; i < filledPositions.length; i++) {
    const [weight, users, position] = filledPositions[i];
    const positionPot = i < filledPositions.length - 1
      ? Math.floor((netPot * weight) / totalWeight)
      : netPot - distributed; // Last position gets remainder to avoid rounding loss

    const perUserPence = Math.floor(positionPot / users.length);
    let remainder = positionPot - perUserPence * users.length;

    for (const userId of users) {
      // First user in the group absorbs the penny remainder
      const extra = remainder > 0 ? 1 : 0;
      remainder -= extra;
      shares.push({ user_id: userId, position, amount_pence: perUserPence + extra });
    }

    distributed += positionPot;
  }

  return shares;
}

/**
 * Computes the dispute window expiry timestamp.
 * Returns now + 24 hours as an ISO string.
 */
export function computeDisputeWindowExpiry(now: Date = new Date()): string {
  return new Date(now.getTime() + DISPUTE_WINDOW_HOURS * 60 * 60 * 1000).toISOString();
}

/**
 * Computes the gross prize pot for a paid league.
 * Prize pot = player_count × stake_pence (before platform fee deduction).
 */
export function computeGrossPot(playerCount: number, stakePence: number): number {
  return playerCount * stakePence;
}

/**
 * Computes the net prize pot after platform fee deduction.
 */
export function computeNetPot(grossPotPence: number): number {
  return Math.floor(grossPotPence * (1 - PLATFORM_FEE_RATE));
}

/**
 * Computes the platform fee for a gross pot.
 */
export function computePlatformFee(grossPotPence: number): number {
  return grossPotPence - computeNetPot(grossPotPence);
}
