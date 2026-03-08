# PRD-001: Wallet System

**Status:** Draft
**Date:** 2026-03-07
**Author:** Orchestrator
**Linear:** PYR-22
**Phase:** 2
**Rules reference:** docs/game-rules/rules.md §6, §8

---

## Goal

Users have an in-app wallet that holds winnings and stake funds. They can top up via payment, use their balance to join paid leagues, receive winnings, and withdraw funds subject to a 24-hour dispute window.

---

## Background

The game rules (§6) define two wallet balance states: **Available to Play** and **Withdrawable**. Winnings are credited immediately post-settlement as Available to Play, then move to Withdrawable after a 24-hour dispute window. This window allows for result corrections before funds are accessible for withdrawal.

---

## Acceptance Criteria

### Wallet Balance Display (iOS)
- [ ] Wallet screen shows two balances: "Available to play" and "Withdrawable"
- [ ] Available to play balance updates immediately when winnings are credited
- [ ] Withdrawable balance shows post-dispute window total
- [ ] Dispute window countdown visible for funds not yet withdrawable (e.g. "Available to withdraw in 18h")
- [ ] Transaction history: list of all credits (winnings), debits (stakes), and withdrawals with timestamps

### Top-Up (iOS + Backend)
- [ ] User can top up via Apple Pay or card (Stripe)
- [ ] Minimum top-up: £5 (one league entry)
- [ ] Top-up credited to Available to Play immediately
- [ ] Top-up shown in transaction history

### Stake Deduction (Backend)
- [ ] Joining a paid league deducts £5 from Available to Play immediately
- [ ] If balance is insufficient, join is rejected with a clear error
- [ ] Stake is held (not credited to prize pot) until minimum players join and round begins
- [ ] If round is cancelled (never reached minimum players), stake refunded to Available to Play

### Winnings Credit (Backend)
- [ ] On round completion, prize distribution Edge Function credits each winner's Available to Play
- [ ] Amount = prize share calculated per docs/game-rules/rules.md §5
- [ ] Credited with `dispute_window_expires_at` = settlement timestamp + 24 hours
- [ ] Transaction logged to `wallet_transactions` table with full audit trail

### Dispute Window (Backend)
- [ ] A background job or triggered function moves Available to Play → Withdrawable after dispute window expires
- [ ] If a result is corrected within the dispute window, wallet balance is adjusted accordingly
- [ ] If adjustment causes negative balance: user cannot join paid leagues or withdraw; free play unaffected
- [ ] Negative balance shown clearly in UI with explanation

### Withdrawal (iOS + Backend)
- [ ] User can request withdrawal from Withdrawable balance only
- [ ] Minimum withdrawal: £20
- [ ] Maximum frequency: 1 withdrawal per day
- [ ] Withdrawal fee passed through at cost, shown before confirmation
- [ ] Withdrawal processed via Stripe payout to user's bank account
- [ ] Withdrawal logged in transaction history with status (pending → complete)

---

## Data Model

### `wallet_transactions` table
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| type | enum | top_up, stake, stake_refund, winnings, withdrawal |
| amount_pence | integer | Always positive; direction implied by type |
| balance_after_pence | integer | Snapshot for audit |
| dispute_window_expires_at | timestamptz | Null for non-winnings rows |
| reference_id | uuid | FK → league_id, pick_id, or payout_id |
| created_at | timestamptz | |
| notes | text | Human-readable for support |

### `user_wallets` view (or table)
| Column | Type | Notes |
|---|---|---|
| user_id | uuid | PK |
| available_to_play_pence | integer | Computed or maintained |
| withdrawable_pence | integer | Computed or maintained |
| updated_at | timestamptz | |

---

## Edge Functions

| Function | Trigger | Description |
|---|---|---|
| `top-up` | iOS client POST | Validates Stripe payment intent, credits Available to Play |
| `request-withdrawal` | iOS client POST | Validates eligibility, initiates Stripe payout |
| `credit-winnings` | Internal (prize distribution) | Credits Available to Play post-round, sets dispute window |
| `process-dispute-window` | Scheduled (every hour) | Moves eligible Available to Play → Withdrawable |

---

## Out of Scope (Phase 2)
- Multiple currencies (GBP only)
- Bank account verification beyond Stripe's built-in checks
- Responsible gambling deposit limits (Phase 3 / compliance GATE)
- Cryptocurrency

---

## Agent Instructions

**Backend Agent:** Implement wallet Edge Functions per this PRD. All balance mutations must be atomic (use Postgres transactions). Every mutation writes to `wallet_transactions`. No balance can go below zero without explicit negative-balance flag on user record. Idempotency required on all Edge Functions.

**iOS Agent:** Implement Wallet screen per design system tokens. Use `WalletViewModel` conforming to MVVM pattern. All balance reads from Edge Function — no direct DB reads. Show dispute window countdowns using relative timestamps.
