# Execution Plan: Phase 3 — Core Game Experience

**File:** docs/plans/active/phase-3-core-game-experience.md
**Linear project:** Pyramid
**Created:** 2026-03-14 (retroactive — Phase 3 work began 2026-03-10 without a plan)
**Owner:** Orchestrator
**Status:** NEAR COMPLETE — 19 features merged, 3–4 items remaining

---

## Goal

Make the game loop complete and entertaining. Polish the free league experience so it's ready for real users. Phase 3 focuses on UX, engagement, and game lifecycle — not payments (blocked on GATEs from Phase 2).

---

## Context

- Phase 2 development complete but blocked on GATE-1 (Compliance PYR-26) and GATE-2 (Cost sign-off PYR-34)
- Phase 3 ran without a formal execution plan — this document is retroactive
- 19 features shipped between 2026-03-10 and 2026-03-14
- Free league game loop is now functionally complete end-to-end
- Paid league code exists but Stripe integration is stubbed (behind GATE)

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

---

## Remaining Work

| ID | Task | Linear | Agent | Status | Priority | Notes |
|---|---|---|---|---|---|---|
| 20 | Accessibility: Dynamic Type support | TBD | iOS | TODO | Medium | All fonts hardcoded — no `.dynamicTypeSize()` |
| 21 | Accessibility: Reduce Motion support | TBD | iOS | TODO | Medium | Confetti/animations don't check `accessibilityReduceMotion` |
| 22 | Result discrepancy alert system | TBD | Backend | TODO | Medium | poll-live-scores detects discrepancies but doesn't notify (TODO in code) |
| 23 | Dark mode toggle (or confirm dark-only) | TBD | iOS/Design | TODO | Low | App locked to dark theme — Phase 2 decision log deferred this to Phase 3 |

---

## GATE Dependencies (from Phase 2 — still blocking)

| GATE | Linear | Status | Days Pending | Impact |
|---|---|---|---|---|
| GATE-1: Compliance / UKGC / KYC | PYR-26 | BLOCKED | 7 days | All paid features blocked from production |
| GATE-2: Stripe cost sign-off | PYR-34 | BLOCKED | 7 days | Payment processing cannot go live |

---

## Decision Log

| Decision | Outcome | Date |
|---|---|---|
| Phase 3 ran without formal plan | Retroactive plan created 2026-03-14 — process gap noted | 2026-03-14 |
| Dark mode deferred from Phase 2 | Still deferred — app ships dark-only for now | 2026-03-14 |
| Coordination ledger was stale | Cleaned up 2026-03-14 — all 7 "active" items were already merged | 2026-03-14 |

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
- [ ] Accessibility: Dynamic Type
- [ ] Accessibility: Reduce Motion
- [ ] Result discrepancy alerting (backend)
- [ ] Dark mode toggle or explicit dark-only decision

---

## Open Questions

1. Is dark-only acceptable for App Store launch, or do we need light mode / system-follow?
2. Should accessibility items (Dynamic Type, Reduce Motion) be Phase 3 blockers or Phase 4?
3. Are there additional Phase 3 features the human owner wants before moving to Phase 4?
