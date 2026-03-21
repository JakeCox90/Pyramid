# Execution Plan: Phase 3 — Core Game Experience

**File:** docs/plans/active/phase-3-core-game-experience.md
**Linear project:** Pyramid
**Created:** 2026-03-14 (retroactive — Phase 3 work began 2026-03-10 without a plan)
**Updated:** 2026-03-21
**Owner:** Orchestrator
**Status:** NEAR COMPLETE — 35 features merged, 2 items remaining

---

## Goal

Make the game loop complete and entertaining. Polish the free league experience so it's ready for real users. Phase 3 focuses on UX, engagement, and game lifecycle — not payments (blocked on GATEs from Phase 2).

---

## Context

- Phase 2 development complete but blocked on GATE-1 (Compliance PYR-26) and GATE-2 (Cost sign-off PYR-34)
- Phase 3 ran without a formal execution plan — this document is retroactive
- 19 features shipped between 2026-03-10 and 2026-03-14 (original batch)
- 16 additional features shipped between 2026-03-14 and 2026-03-21 (polish + accessibility + dev tooling)
- Free league game loop is now functionally complete end-to-end
- Paid league code exists but Stripe integration is stubbed (behind GATE)

---

## Completed (all merged to main)

### Original batch (2026-03-10 to 2026-03-14)

| ID | Task | Linear | Agent | PR | Notes |
|---|---|---|---|---|---|
| 1 | Winner detection in settle-picks | PYR-66 | Backend | #40 | Settlement now detects last-man-standing |
| 2 | GW38 season hard cutoff — joint winners | PYR-67 | Backend | #43 | Season ends correctly at GW38 |
| 3 | Automatic gameweek advancement | PYR-68 | Backend | #39 | Advances after all fixtures settle |
| 4 | League completion UI and winner announcement | PYR-69 | iOS | #44 | End-of-league screens |
| 5 | Sign-out button | PYR-70 | iOS | #38 | Profile → sign out |
| 6 | Onboarding carousel | PYR-71 | iOS | #45 | First-time user flow |
| 7 | Enhanced empty states | PYR-72 | iOS | #50 | Rules summary + SF Symbol illustration |
| 8 | Live score updates | PYR-73 | iOS | #57 | Real-time scores in league detail |
| 9 | My Pick live survival card | PYR-74 | iOS | #60 | Visual feedback on pick status |
| 10 | Pick celebration with haptics | PYR-75 | iOS | #52 | Confetti + haptic feedback on successful pick |
| 11 | Profile overhaul with stats/streaks | PYR-77 | iOS | #62 | Stats, streaks, league history |
| 12 | League share/invite | PYR-78 | iOS | #54 | Share sheet from league detail |
| 13 | Pick history per league | PYR-79 | iOS | #55 | Historical picks view |
| 14 | Browse and join free leagues | PYR-80 | iOS | #37 | Discovery of public leagues |
| 15 | Club badges in fixture rows | PYR-83 | iOS | #41 | Visual polish |
| 16 | Pick screen title flash fix | PYR-84 | iOS | #46 | Bug fix |
| 17 | Home tab (3-tab layout) | PYR-85 | iOS | #48 | App navigation restructured |
| 18 | HomeService aggregate layer | PYR-86 | iOS | #59 | Data layer for home screen |
| 19 | Apple & Google social sign-on | PYR-39 | iOS | #63 | OAuth sign-in options |

### Polish, accessibility & dev tooling (2026-03-14 to 2026-03-21)

| ID | Task | Linear | Agent | PR | Notes |
|---|---|---|---|---|---|
| 20 | Live match-day card on homepage | PYR-91 | iOS | #65 | Match-day engagement |
| 21 | Last gameweek results summary | PYR-92 | iOS | #66 | Results on homepage |
| 22 | Backend player profile service | PYR-95 | Backend | — | update-profile Edge Function (on branch, PR pending) |
| 23 | Touch target fix (44pt minimum) | PYR-116 | iOS | #70 | Accessibility compliance |
| 24 | VoiceOver accessibility labels | PYR-117 | iOS | #76 | App-wide VoiceOver support |
| 25 | Hardcoded colors → Theme tokens | PYR-118 | iOS | #69 | Design system alignment |
| 26 | Shared ErrorState/EmptyState views | PYR-119 | iOS | #71 | Component reuse |
| 27 | Session load timeout and retry | PYR-120 | iOS | #73 | Resilience improvement |
| 28 | Pick submission loading state | PYR-121 | iOS | #72 | UX feedback on team buttons |
| 29 | Error message categorization | PYR-122 | iOS | #67 | AppError enum |
| 30 | Wallet UX clarification | PYR-123 | iOS | #74 | Financial UX improvement |
| 31 | Dark mode enforced at root level | PYR-124 | iOS | #68 | Explicit dark mode decision |
| 32 | Reduce Motion accessibility checks | PYR-125 | iOS | #75 | All animations respect system setting |
| 33 | Comprehensive dev seed data | PYR-127 | Backend | #77 | 3 leagues, 20 bots for testing |
| 34 | reset-dev-data Edge Function | PYR-128 | Backend | #78 | Dev environment reset |
| 35 | Debug reset UI on Profile | PYR-129 | iOS | #79 | Dev-only reset button |
| 36 | Terminal reset script | PYR-130 | iOS | #80 | Dev tooling |
| 37 | Picks-needed scroll rail on home | — | iOS | #81 | Home screen engagement |
| 38 | Redesign Make Your Pick page | PYR-122 | iOS | #82 | Full Figma redesign with design system |
| 39 | Design system updates (Inter font, purple theme) | — | iOS | #81 | Font + color scheme overhaul |

---

## Remaining Work

| ID | Task | Linear | Agent | Status | Priority | Notes |
|---|---|---|---|---|---|---|
| 40 | Accessibility: Dynamic Type support | TBD | iOS | TODO | Medium | All fonts hardcoded — no `.dynamicTypeSize()` |
| 41 | Result discrepancy alert system | TBD | Backend | TODO | Medium | poll-live-scores detects discrepancies but doesn't notify (TODO in code) |

---

## GATE Dependencies (from Phase 2 — still blocking)

| GATE | Linear | Status | Days Pending | Impact |
|---|---|---|---|---|
| GATE-1: Compliance / UKGC / KYC | PYR-26 | BLOCKED | 14 days | All paid features blocked from production |
| GATE-2: Stripe cost sign-off | PYR-34 | BLOCKED | 14 days | Payment processing cannot go live |

---

## Decision Log

| Decision | Outcome | Date |
|---|---|---|
| Phase 3 ran without formal plan | Retroactive plan created 2026-03-14 — process gap noted | 2026-03-14 |
| Dark mode deferred from Phase 2 | Resolved — PYR-124 enforces dark mode at root level (PR #68) | 2026-03-20 |
| Coordination ledger was stale | Cleaned up 2026-03-14 — all 7 "active" items were already merged | 2026-03-14 |
| Plan doc was stale | Updated 2026-03-21 — 16 additional features shipped since last update | 2026-03-21 |
| Reduce Motion was TODO | Completed — PYR-125 shipped (PR #75) | 2026-03-20 |

---

## Definition of Done (Phase 3)

- [x] Home tab with aggregate data layer
- [x] Live score updates in league detail
- [x] My Pick survival card with live status
- [x] Pick celebration with haptics and animation
- [x] League share/invite flow
- [x] Pick history per league
- [x] Browse and join free leagues (discovery)
- [x] Profile with stats and streaks
- [x] Onboarding carousel for new users
- [x] Winner detection and league completion UI
- [x] Gameweek advancement automation
- [x] Season hard cutoff at GW38
- [x] Sign-out functionality
- [x] Social sign-on (Apple + Google)
- [x] Enhanced empty states
- [x] Club badges on fixtures
- [x] Accessibility: VoiceOver labels (PYR-117)
- [x] Accessibility: Reduce Motion (PYR-125)
- [x] Accessibility: Touch targets 44pt minimum (PYR-116)
- [x] Dark mode enforced at root (PYR-124)
- [x] Design system alignment (Inter font, theme tokens, purple palette)
- [x] Make Your Pick redesign (PYR-122)
- [x] Dev tooling (seed data, reset function, debug UI)
- [ ] Accessibility: Dynamic Type
- [ ] Result discrepancy alerting (backend)

---

## Open Questions

1. Should Dynamic Type be a Phase 3 blocker or Phase 4?
2. Are there additional Phase 3 features the human owner wants before moving to Phase 4?
