// Unit tests for wallet business logic.
// Run with: deno test supabase/functions/top-up/wallet.test.ts

import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeBalances,
  computeDisputeWindowExpiry,
  computeGrossPot,
  computeNetPot,
  computePlatformFee,
  distributePrizes,
  validateTopUp,
  validateWithdrawal,
  type Transaction,
} from "./wallet.ts";

// ─── computeBalances ──────────────────────────────────────────────────────────

const PAST = new Date("2026-01-01T00:00:00Z"); // always in the past relative to our test `now`
const FUTURE = new Date("2030-01-01T00:00:00Z"); // always in the future
const NOW = new Date("2026-03-08T12:00:00Z");

Deno.test("computeBalances: zero balances when no transactions", () => {
  const result = computeBalances([], NOW);
  assertEquals(result.available_to_play_pence, 0);
  assertEquals(result.withdrawable_pence, 0);
  assertEquals(result.pending_pence, 0);
});

Deno.test("computeBalances: top_up credits available and withdrawable", () => {
  const txs: Transaction[] = [{ type: "top_up", amount_pence: 1000 }];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 1000);
  assertEquals(result.withdrawable_pence, 1000);
  assertEquals(result.pending_pence, 0);
});

Deno.test("computeBalances: stake deducts from available and withdrawable", () => {
  const txs: Transaction[] = [
    { type: "top_up", amount_pence: 5000 },
    { type: "stake", amount_pence: 500 },
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 4500);
  assertEquals(result.withdrawable_pence, 4500);
});

Deno.test("computeBalances: winnings within dispute window count as available but not withdrawable", () => {
  const txs: Transaction[] = [
    { type: "top_up", amount_pence: 1000 },
    { type: "winnings", amount_pence: 2000, dispute_window_expires_at: FUTURE.toISOString() },
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 3000);
  assertEquals(result.withdrawable_pence, 1000); // top_up only — winnings not yet past window
  assertEquals(result.pending_pence, 2000);
});

Deno.test("computeBalances: winnings past dispute window become withdrawable", () => {
  const txs: Transaction[] = [
    { type: "winnings", amount_pence: 3000, dispute_window_expires_at: PAST.toISOString() },
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 3000);
  assertEquals(result.withdrawable_pence, 3000);
  assertEquals(result.pending_pence, 0);
});

Deno.test("computeBalances: stake_refund credits available and withdrawable", () => {
  const txs: Transaction[] = [
    { type: "stake_refund", amount_pence: 500 },
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 500);
  assertEquals(result.withdrawable_pence, 500);
});

Deno.test("computeBalances: withdrawal deducts from available and withdrawable", () => {
  const txs: Transaction[] = [
    { type: "top_up", amount_pence: 5000 },
    { type: "withdrawal", amount_pence: 2000 },
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, 3000);
  assertEquals(result.withdrawable_pence, 3000);
});

Deno.test("computeBalances: multiple transactions with mixed types", () => {
  const txs: Transaction[] = [
    { type: "top_up", amount_pence: 10000 },
    { type: "stake", amount_pence: 500 },                             // join league 1
    { type: "stake", amount_pence: 500 },                             // join league 2
    { type: "winnings", amount_pence: 9200, dispute_window_expires_at: FUTURE.toISOString() }, // win league 1
    { type: "withdrawal", amount_pence: 2000 },
  ];
  const result = computeBalances(txs, NOW);
  // available = 10000 - 500 - 500 + 9200 - 2000 = 16200
  assertEquals(result.available_to_play_pence, 16200);
  // withdrawable = 10000 - 500 - 500 - 2000 = 7000 (winnings still pending)
  assertEquals(result.withdrawable_pence, 7000);
  assertEquals(result.pending_pence, 9200);
});

Deno.test("computeBalances: negative balance scenario after result correction", () => {
  // User won £92 (winnings), re-staked £5, then winnings were reversed (not modelled here)
  // This tests that the computation works when available_to_play goes negative.
  const txs: Transaction[] = [
    { type: "top_up", amount_pence: 500 },
    { type: "stake", amount_pence: 500 },
    { type: "stake", amount_pence: 500 }, // second stake — now negative
  ];
  const result = computeBalances(txs, NOW);
  assertEquals(result.available_to_play_pence, -500);
});

// ─── validateTopUp ────────────────────────────────────────────────────────────

Deno.test("validateTopUp: valid input", () => {
  assertEquals(validateTopUp("pi_valid123", 1000).valid, true);
});

Deno.test("validateTopUp: missing payment intent id", () => {
  const result = validateTopUp(null, 1000);
  assertEquals(result.valid, false);
  assertEquals(result.error, "MISSING_PAYMENT_INTENT");
});

Deno.test("validateTopUp: empty string payment intent id", () => {
  const result = validateTopUp("", 1000);
  assertEquals(result.valid, false);
  assertEquals(result.error, "MISSING_PAYMENT_INTENT");
});

Deno.test("validateTopUp: amount zero is invalid", () => {
  const result = validateTopUp("pi_valid", 0);
  assertEquals(result.valid, false);
  assertEquals(result.error, "INVALID_AMOUNT");
});

Deno.test("validateTopUp: negative amount is invalid", () => {
  const result = validateTopUp("pi_valid", -100);
  assertEquals(result.valid, false);
  assertEquals(result.error, "INVALID_AMOUNT");
});

Deno.test("validateTopUp: amount below minimum (£5) is rejected", () => {
  const result = validateTopUp("pi_valid", 499);
  assertEquals(result.valid, false);
  assertEquals(result.error, "AMOUNT_TOO_LOW");
});

Deno.test("validateTopUp: amount exactly at minimum (£5 = 500p) is valid", () => {
  assertEquals(validateTopUp("pi_valid", 500).valid, true);
});

// ─── validateWithdrawal ───────────────────────────────────────────────────────

Deno.test("validateWithdrawal: valid withdrawal", () => {
  const result = validateWithdrawal(2000, 5000, null, NOW);
  assertEquals(result.valid, true);
});

Deno.test("validateWithdrawal: invalid amount (non-number)", () => {
  const result = validateWithdrawal("abc", 5000, null, NOW);
  assertEquals(result.valid, false);
  assertEquals(result.error, "INVALID_AMOUNT");
});

Deno.test("validateWithdrawal: amount below minimum (£20)", () => {
  const result = validateWithdrawal(1999, 5000, null, NOW);
  assertEquals(result.valid, false);
  assertEquals(result.error, "AMOUNT_TOO_LOW");
});

Deno.test("validateWithdrawal: amount exactly at minimum (£20 = 2000p)", () => {
  assertEquals(validateWithdrawal(2000, 5000, null, NOW).valid, true);
});

Deno.test("validateWithdrawal: insufficient withdrawable balance", () => {
  const result = validateWithdrawal(3000, 2000, null, NOW);
  assertEquals(result.valid, false);
  assertEquals(result.error, "INSUFFICIENT_BALANCE");
});

Deno.test("validateWithdrawal: exact balance amount is valid", () => {
  assertEquals(validateWithdrawal(2000, 2000, null, NOW).valid, true);
});

Deno.test("validateWithdrawal: rate limited — last withdrawal < 24h ago", () => {
  const lastWithdrawal = new Date(NOW.getTime() - 23 * 60 * 60 * 1000); // 23 hours ago
  const result = validateWithdrawal(2000, 5000, lastWithdrawal, NOW);
  assertEquals(result.valid, false);
  assertEquals(result.error, "RATE_LIMITED");
});

Deno.test("validateWithdrawal: not rate limited — last withdrawal exactly 24h ago", () => {
  const lastWithdrawal = new Date(NOW.getTime() - 24 * 60 * 60 * 1000); // exactly 24 hours ago
  assertEquals(validateWithdrawal(2000, 5000, lastWithdrawal, NOW).valid, true);
});

Deno.test("validateWithdrawal: not rate limited — last withdrawal > 24h ago", () => {
  const lastWithdrawal = new Date(NOW.getTime() - 25 * 60 * 60 * 1000); // 25 hours ago
  assertEquals(validateWithdrawal(2000, 5000, lastWithdrawal, NOW).valid, true);
});

// ─── distributePrizes ─────────────────────────────────────────────────────────

Deno.test("distributePrizes: full 3-position split — single winner each", () => {
  // 10 players × £5 = £50 gross; net = £50 × 0.92 = £46 = 4600p
  const grossPot = 10 * 5000; // 50000p
  const shares = distributePrizes(grossPot, ["u1"], ["u2"], ["u3"]);
  assertEquals(shares.length, 3);

  const total = shares.reduce((s, x) => s + x.amount_pence, 0);
  // Net pot = 50000 × 0.92 = 46000
  assertEquals(total, 46000);

  const first = shares.find((s) => s.position === 1)!;
  const second = shares.find((s) => s.position === 2)!;
  const third = shares.find((s) => s.position === 3)!;

  // 65% of 46000 = 29900; 25% = 11500; 10% = 4600
  assertEquals(first.amount_pence, 29900);
  assertEquals(second.amount_pence, 11500);
  assertEquals(third.amount_pence, 4600);
});

Deno.test("distributePrizes: joint 1st place — 2 winners split 65%", () => {
  const grossPot = 10 * 5000; // 50000p; net = 46000p
  const shares = distributePrizes(grossPot, ["u1", "u2"], ["u3"], ["u4"]);

  const firstShares = shares.filter((s) => s.position === 1);
  assertEquals(firstShares.length, 2);
  // 65% of 46000 = 29900; split 2 ways = 14950 each (no remainder)
  assertEquals(firstShares[0].amount_pence, 14950);
  assertEquals(firstShares[1].amount_pence, 14950);

  const total = shares.reduce((s, x) => s + x.amount_pence, 0);
  assertEquals(total, 46000);
});

Deno.test("distributePrizes: only 1 position filled — 100% goes to 1st", () => {
  // No 2nd or 3rd place — all survivors won simultaneously (e.g. 5-player league all survive)
  const grossPot = 5 * 5000; // 25000p; net = 23000p
  const shares = distributePrizes(grossPot, ["u1", "u2"], [], []);

  assertEquals(shares.length, 2);
  const total = shares.reduce((s, x) => s + x.amount_pence, 0);
  assertEquals(total, 23000);

  // Both first-place winners split equally — 11500 each (no remainder)
  assertEquals(shares[0].amount_pence, 11500);
  assertEquals(shares[1].amount_pence, 11500);
});

Deno.test("distributePrizes: only 2 positions filled — proportional split (65+25=90 weight)", () => {
  const grossPot = 10 * 5000; // 50000p; net = 46000p
  const shares = distributePrizes(grossPot, ["u1"], ["u2"], []);

  assertEquals(shares.length, 2);
  const total = shares.reduce((s, x) => s + x.amount_pence, 0);
  assertEquals(total, 46000);

  // Proportional: 65/90 and 25/90 of 46000
  // 1st = floor(46000 × 65 / 90) = floor(33222.2) = 33222
  // 2nd = 46000 - 33222 = 23778
  const first = shares.find((s) => s.position === 1)!;
  const second = shares.find((s) => s.position === 2)!;
  assertEquals(first.amount_pence, 33222);
  assertEquals(second.amount_pence, 12778);
});

Deno.test("distributePrizes: penny remainder is absorbed by first user in group", () => {
  // 3 joint 1st winners splitting an amount that doesn't divide evenly
  const grossPot = 1 * 5000; // 5000p; net = 4600p
  const shares = distributePrizes(grossPot, ["u1", "u2", "u3"], [], []);

  const total = shares.reduce((s, x) => s + x.amount_pence, 0);
  assertEquals(total, 4600);

  // 4600 / 3 = 1533 rem 1
  // u1 gets 1534, u2 and u3 get 1533
  assertEquals(shares[0].amount_pence, 1534);
  assertEquals(shares[1].amount_pence, 1533);
  assertEquals(shares[2].amount_pence, 1533);
});

Deno.test("distributePrizes: throws if no 1st-place winners provided", () => {
  assertThrows(
    () => distributePrizes(50000, [], ["u1"], []),
    Error,
    "winners1st must not be empty",
  );
});

// ─── computeGrossPot / computeNetPot / computePlatformFee ────────────────────

Deno.test("computeGrossPot: 10 players × £5", () => {
  assertEquals(computeGrossPot(10, 5000), 50000);
});

Deno.test("computeNetPot: 8% platform fee deducted", () => {
  // 50000 × 0.92 = 46000
  assertEquals(computeNetPot(50000), 46000);
});

Deno.test("computePlatformFee: 8% of gross", () => {
  // 50000 × 0.08 = 4000
  assertEquals(computePlatformFee(50000), 4000);
});

Deno.test("computeNetPot + computePlatformFee sums to gross", () => {
  const gross = 50000;
  assertEquals(computeNetPot(gross) + computePlatformFee(gross), gross);
});

// ─── computeDisputeWindowExpiry ───────────────────────────────────────────────

Deno.test("computeDisputeWindowExpiry: exactly 24 hours from now", () => {
  const now = new Date("2026-03-08T12:00:00Z");
  const expiry = computeDisputeWindowExpiry(now);
  assertEquals(expiry, "2026-03-09T12:00:00.000Z");
});
