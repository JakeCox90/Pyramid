# Execution Plan: Phase 2 — Paid Leagues & Wallet

**File:** docs/plans/active/phase-2-paid-leagues-wallet.md
**Linear project:** Pyramid
**Created:** 2026-03-07
**Owner:** Orchestrator
**Status:** IN PROGRESS

---

## Goal

Enable paid matchmaking leagues with a £5 fixed entry fee, a wallet system for winnings and withdrawals, prize distribution on round completion, and push notifications for pick deadlines and results.

---

## Context

- Phase 1 delivered: free leagues, pick submission, standings, settlement (FT results)
- Game rules fully specified in `docs/game-rules/rules.md`
- Stack: SwiftUI + Supabase + API-Football
- Paid features require: payment provider, KYC/age verification, UKGC compliance groundwork
- Compliance items are GATEs — work proceeds in parallel on non-GATE items

---

## Steps

| ID | Task | Linear | Agent | Status | Notes |
|---|---|---|---|---|---|
| 1 | Phase 2 execution plan | — | Orchestrator | DONE | This document |
| 2 | PRD: Wallet System | PYR-22 | Orchestrator/PM | DONE | docs/prd/PRD-001-wallet-system.md |
| 3 | PRD: Paid Matchmaking Leagues | PYR-23 | Orchestrator/PM | DONE | docs/prd/PRD-002-paid-matchmaking-leagues.md |
| 4 | PRD: Push Notifications | PYR-24 | Orchestrator/PM | DONE | docs/prd/PRD-003-push-notifications.md |
| 5 | ADR-004: Payment provider choice | PYR-25 | Architect | TODO | Stripe is default choice; human review on cost |
| 6 | [GATE] Compliance: UKGC / KYC spec | PYR-26 | Compliance | BLOCKED | Human must define KYC provider and UKGC approach |
| 7 | Backend: Wallet Edge Functions | PYR-27 | Backend | TODO | top-up, balance, withdrawal — blocked on PYR-25 payment ADR |
| 8 | Backend: Paid league matchmaking | PYR-28 | Backend | TODO | allocation, stake locking, league formation |
| 9 | Backend: Prize distribution | PYR-29 | Backend | TODO | round end detection, payout calculation, wallet credit |
| 10 | iOS: Wallet UI | PYR-30 | iOS | TODO | balance display, top-up flow, withdrawal request |
| 11 | iOS: Paid league join flow | PYR-31 | iOS | TODO | stake confirmation, matchmaking queue, league entry |
| 12 | iOS: Push notifications | PYR-32 | iOS | TODO | APNs registration, deadline reminders, result alerts |
| 13 | Backend: Push notification Edge Functions | PYR-33 | Backend | TODO | register-device-token, send-notification utility, schedulers |
| 14 | [GATE 2] Human review: paid features sign-off | PYR-34 | Human | BLOCKED | Review before any paid feature goes to prod |

---

## Decision Log

| Decision | Outcome | Date |
|---|---|---|
| Payment provider default | Stripe — market-leading, well-documented iOS SDK, GATE for cost confirmation | 2026-03-07 |
| Notification provider | APNs direct via Supabase Edge Functions — no third-party provider needed at this scale | 2026-03-07 |
| Phase 2 scope | Wallet + paid leagues + notifications. Dark mode deferred to Phase 3. | 2026-03-07 |
| PRD authorship | Orchestrator writes PRDs — no PM Agent spawned yet, same precedent as Phase 0 ADRs | 2026-03-07 |

---

## GATE Items

### GATE-1: Compliance / UKGC / KYC
- **Decision needed:** Which KYC provider to use (Onfido, Jumio, Stripe Identity)?
- **Decision needed:** UKGC small-scale operator exemption — do we qualify, or do we need a licence?
- **Decision needed:** Responsible gambling controls required (deposit limits, self-exclusion)?
- **Blocks:** All paid features going to production

### GATE-2: Payment provider cost sign-off
- **Decision needed:** Approve Stripe as payment provider (2.9% + 30p per transaction)
- **Decision needed:** Stripe account created and connected
- **Blocks:** PYR-27 (Wallet Edge Functions)

---

## Open Questions

1. Age verification — integrate at registration or at first paid league join?
2. Withdrawal method — bank transfer only, or support Apple Pay withdrawals?
3. Responsible gambling — minimum controls for Phase 2 launch?

---

## Definition of Done (Gate 2)

- [ ] Wallet system live: top-up, Available to Play, Withdrawable, dispute window
- [ ] Paid matchmaking leagues: join, stake held, round start when min 5 met
- [ ] Prize distribution: correct splits, credited to Available to Play post-round
- [ ] Push notifications: deadline reminders + settlement alerts working on device
- [ ] Compliance groundwork complete (GATE-1 resolved)
- [ ] All tests passing, CI green
- [ ] Human review signed off (GATE-2)
