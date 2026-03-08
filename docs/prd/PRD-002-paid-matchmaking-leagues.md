# PRD-002: Paid Matchmaking Leagues

**Status:** Draft
**Date:** 2026-03-07
**Author:** Orchestrator
**Linear:** PYR-23
**Phase:** 2
**Rules reference:** docs/game-rules/rules.md §1, §2.2, §5

---

## Goal

Users can join a paid public matchmaking league with a fixed £5 stake, be randomly allocated to a league with other players at the same stake level, and compete for a prize pot distributed across the top 3 positions on round completion.

---

## Background

Paid matchmaking leagues use random allocation (no browsing or self-selection) to prevent coordination. The stake is fixed at £5. Leagues require a minimum of 5 players to begin and hold a maximum of 30. Prize pot = £5 × number of players, minus 8% platform fee. Full rules in `docs/game-rules/rules.md §2.2`.

---

## Acceptance Criteria

### Join Flow (iOS)
- [ ] "Join Paid League" button visible on Leagues screen (separate from free league flow)
- [ ] Confirmation screen shows: stake amount (£5), current wallet balance, prize pot estimate, rules summary
- [ ] User confirms stake — £5 deducted from Available to Play immediately
- [ ] User sees "Waiting for players" state if league not yet full (min 5 not yet met)
- [ ] When minimum is met and round begins, user is notified (push + in-app) and league appears in My Leagues
- [ ] If user is already in 5 active paid leagues, join is blocked with clear message

### Matchmaking (Backend)
- [ ] `join-paid-league` Edge Function: deducts stake, adds user to matchmaking queue for the stake tier
- [ ] Matchmaking assigns users to the least-full available league at that stake tier (fill existing before creating new)
- [ ] When a league reaches 5 players, the round begins: league status → `active`, `round_started_at` set
- [ ] When a league reaches 30 players, it is closed — a new league is opened for the next joiner
- [ ] Users already in 5 active paid leagues are rejected at the Edge Function level

### Pseudonymity (Backend + iOS)
- [ ] In active paid leagues, all members shown as pseudonyms (e.g. "Player 1", "Player 2")
- [ ] Real identities not revealed until round ends (league status → `complete`)
- [ ] Pseudonym assignment: stable per user per league (same pseudonym across all GWs)

### Prize Distribution (Backend)
- [ ] On round completion, `distribute-prizes` Edge Function runs
- [ ] Prize pot = (£5 × player count) × 0.92 (after 8% platform fee)
- [ ] Positions determined per rules §5.2: 1st = last survivor(s), 2nd = last eliminated GW, 3rd = GW before that
- [ ] Shares: 65% / 25% / 10% — redistributed proportionally if fewer than 3 positions filled (§5.2)
- [ ] Joint winners split their position's share equally; penny remainder goes to next position up
- [ ] Winnings credited to each winner's Available to Play via `credit-winnings` Edge Function
- [ ] League status set to `complete`, real identities revealed in standings

### Stake Refund (Backend)
- [ ] If a league never reaches 5 players before the season ends (GW38 passed), stakes refunded
- [ ] Refund via `refund-stake` Edge Function, logged in wallet_transactions as `stake_refund`

---

## Data Model Changes

### `leagues` table additions
| Column | Type | Notes |
|---|---|---|
| type | enum | free, paid |
| stake_pence | integer | 5000 for paid leagues |
| status | enum | waiting (< min players), active, complete |
| prize_pot_pence | integer | Calculated at round start |
| platform_fee_pence | integer | 8% of gross pot |
| round_started_at | timestamptz | When min players reached |
| round_ended_at | timestamptz | When winner declared |

### `league_members` additions
| Column | Type | Notes |
|---|---|---|
| pseudonym | text | e.g. "Player 7" — stable per league |
| finishing_position | integer | 1, 2, 3 or null — set at round end |
| prize_pence | integer | Amount won — set at round end |

---

## Edge Functions

| Function | Trigger | Description |
|---|---|---|
| `join-paid-league` | iOS client POST | Validates wallet, deducts stake, assigns to league |
| `distribute-prizes` | Internal (settle-picks on round end) | Calculates and credits prize shares |
| `refund-stake` | Internal (season end cleanup) | Refunds stakes for leagues that never started |

---

## Round End Detection

A round ends when `settle-picks` processes a fixture and finds that only 1 or fewer active members remain in a league (after mass elimination check). `settle-picks` calls `distribute-prizes` with the `leagueId` when this condition is met.

---

## 5-League Cap Enforcement

Enforced at Edge Function level. `join-paid-league` queries `league_members` for the user's count of active paid leagues (status = `waiting` or `active`). If count ≥ 5, return 409 with error message.

---

## Out of Scope (Phase 2)
- Variable stake tiers (fixed at £5 only)
- Private paid leagues (matchmaking only)
- League chat
- Leaderboards across leagues

---

## Agent Instructions

**Backend Agent:** Implement `join-paid-league` and `distribute-prizes` Edge Functions. Prize distribution must be atomic — use a Postgres transaction to write all winner credits in a single operation. Idempotency key per league per round on `distribute-prizes`. Test with min/max players, joint winners, fewer-than-3-positions scenarios.

**iOS Agent:** Implement paid league join flow with wallet balance check before showing confirmation. Show "Waiting for players" state with member count progress (e.g. "3 / 5 players joined"). Pseudonym display in standings for active paid leagues only.
