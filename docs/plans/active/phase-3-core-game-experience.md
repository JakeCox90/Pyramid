# Execution Plan: Phase 3 — Core Game Experience

**File:** docs/plans/active/phase-3-core-game-experience.md
**Linear project:** Pyramid
**Created:** 2026-03-14 (retroactive — Phase 3 work began 2026-03-10 without a plan)
**Updated:** 2026-03-23
**Owner:** Orchestrator
**Status:** NEAR COMPLETE — 37 features merged, pick carousel + homepage redesign in progress

---

## Goal

Make the game loop complete and entertaining. Polish the free league experience so it's ready for real users. Phase 3 focuses on UX, engagement, and game lifecycle — not payments (blocked on GATEs from Phase 2).

---

## Context

- Phase 2 development complete but blocked on GATE-1 (Compliance PYR-26) and GATE-2 (Cost sign-off PYR-34)
- Phase 3 ran without a formal execution plan — this document is retroactive
- 37 features shipped between 2026-03-10 and 2026-03-21
- Free league game loop is now functionally complete end-to-end
- Paid league code exists but Stripe integration is stubbed (behind GATE)
- Pick carousel + homepage redesign actively in progress on `feature/PYR-131-pick-carousel` (8 tickets)

---

## Completed (all merged to main)

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
| 20 | Live match-day card on homepage | PYR-91 | iOS | #65 | Match-day status on home |
| 21 | Last gameweek results summary | PYR-92 | iOS | #66 | Results on homepage |
| 22 | DSButton touch targets 44pt min | PYR-116 | iOS | #70 | Accessibility fix |
| 23 | VoiceOver accessibility labels | PYR-117 | iOS | #76 | App-wide a11y |
| 24 | Replace hardcoded hex with Theme tokens | PYR-118 | iOS | #69 | Design system alignment |
| 25 | Shared ErrorStateView/EmptyStateView | PYR-119 | iOS | #71 | Reusable components |
| 26 | Session load timeout + retry | PYR-120 | iOS | #73 | Resilience |
| 27 | Pick submission loading state | PYR-121 | iOS | #72 | UX feedback |
| 28 | Error message categorization | PYR-122 | iOS | #67 | User-friendly errors |
| 29 | Wallet financial UX clarity | PYR-123 | iOS | #74 | Stake/settlement clarity |
| 30 | Dark mode enforced at root | PYR-124 | iOS | #68 | Consistent dark theme |
| 31 | Reduce Motion accessibility | PYR-125 | iOS | #75 | a11y — animation checks |
| 32 | Dev seed data | PYR-127 | Backend | #77 | 3 leagues, 20 bots |
| 33 | Reset Edge Function + RPC | PYR-128 | Backend | #78 | Dev environment reset |
| 34 | Debug reset UI | PYR-129 | iOS | #79 | Profile reset buttons |
| 35 | Terminal reset script | PYR-130 | iOS | #80 | Dev tooling |
| 36 | Picks redesign (Make Your Pick page) | PYR-122 | iOS | #82 | Figma-aligned redesign |
| 37 | Picks-needed scroll rail on home | — | iOS | #81 | Home screen enhancement |

---

## In Progress (unmerged — all on `feature/PYR-131-pick-carousel`)

| ID | Task | Linear | Status | Notes |
|---|---|---|---|---|
| 38 | Pick carousel — horizontal swipeable match cards | PYR-131 | In Progress | Core carousel UI |
| 39 | Match carousel card component | PYR-133 | In Progress | Individual card design |
| 40 | HomeData + HomeService extension | PYR-139 | In Progress | Data layer for gameweeks, player counts |
| 41 | HomeViewModel rewrite | PYR-140 | In Progress | Countdown timer, gameweek switching |
| 42 | Homepage countdown timer + GW dropdown | PYR-141 | In Progress | Countdown UI component |
| 43 | Homepage hero match card | PYR-142 | In Progress | Current pick display |
| 44 | Homepage players remaining + previous picks | PYR-143 | In Progress | Status sections |
| 45 | Homepage root view rewrite | PYR-144 | In Progress | Cleanup old extensions |

---

## Remaining Work (backlog)

| ID | Task | Linear | Status | Priority | Notes |
|---|---|---|---|---|---|
| 46 | H2H endpoint — API-Football client + edge function | PYR-132 | Backlog | Medium | Backend for stats panel |
| 47 | Horizontal paged carousel gesture system | PYR-134 | Backlog | Medium | Advanced gesture handling |
| 48 | H2H stats panel (behind card) | PYR-135 | Backlog | Medium | Swipe-up reveal |
| 49 | Pick commit flow — celebration + return home | PYR-136 | Backlog | Medium | Post-pick UX |
| 50 | Pick view mode toggle (list ↔ carousel) | PYR-137 | Backlog | Low | User preference |
| 51 | Homepage redesign — match Figma node 7:10127 | PYR-138 | Backlog | Medium | Full Figma alignment |
| 52 | Result discrepancy alert system | TBD | Backlog | Medium | Backend notification |

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
| Dark mode deferred from Phase 2 | Resolved — PYR-124 enforced dark mode at root level | 2026-03-20 |
| Coordination ledger was stale | Cleaned up 2026-03-14 — all 7 "active" items were already merged | 2026-03-14 |
| Reduce Motion accessibility | Completed via PYR-125 — was listed as remaining, now merged | 2026-03-20 |
| Coordination ledger stale again | Updated 2026-03-23 — 18 PRs merged since last update | 2026-03-23 |
| Pick carousel + homepage on shared branch | 8 tickets grouped on one branch (tightly coupled UI work) | 2026-03-23 |

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
- [x] Accessibility: Reduce Motion (PYR-125)
- [x] Accessibility: VoiceOver labels (PYR-117)
- [x] Dark mode enforced at root (PYR-124)
- [x] Design system token alignment (PYR-118)
- [x] Error message categorization (PYR-122)
- [x] Dev seed + reset tooling (PYR-127/128/129/130)
- [ ] Pick carousel + homepage redesign (PYR-131/133/139-144 — in progress)
- [ ] H2H stats backend + panel (PYR-132/135 — backlog)
- [ ] Result discrepancy alerting (backend — backlog)

---

## Open Questions

1. Are PYR-132 (H2H backend) and PYR-135 (H2H stats panel) Phase 3 blockers or can they be deferred?
2. Should PYR-134 (advanced carousel gestures) and PYR-137 (list/carousel toggle) be cut from Phase 3?
3. GATE-1 and GATE-2 have been pending 14 days — any movement on compliance/cost decisions?
