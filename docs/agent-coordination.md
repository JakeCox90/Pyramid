# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| — | — | — | — | — | — |

> No active work as of 2026-03-14. All Phase 3 tickets merged.

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
| PYR-39 | feature/PYR-39-social-sign-on | #63 | 2026-03-14 |
| PYR-77 | feature/PYR-77-profile-overhaul | #62 | 2026-03-14 |
| PYR-74 | feature/PYR-74-my-pick-card-agent | #60 | 2026-03-13 |
| PYR-86 | feature/PYR-86-home-service | #59 | 2026-03-13 |
| PYR-73 | feature/PYR-73-live-scores | #57 | 2026-03-12 |
| PYR-85 | feature/PYR-85-home-tab | #48 | 2026-03-12 |
| PYR-79 | feature/PYR-79-pick-history | #55 | 2026-03-12 |
| PYR-78 | feature/PYR-78-league-share | #54 | 2026-03-12 |
| PYR-75 | feature/PYR-75-pick-celebration | #52 | 2026-03-11 |
| PYR-72 | feature/PYR-72-enhanced-empty-state | #50 | 2026-03-11 |
| PYR-80 | feature/PYR-80-browse-free-leagues | #37 | 2026-03-10 |
| PYR-70 | feature/PYR-70-sign-out | #38 | 2026-03-10 |
| PYR-68 | feature/PYR-68-gameweek-advancement | #39 | 2026-03-10 |
| PYR-66 | feature/PYR-66-winner-detection | #40 | 2026-03-10 |
| PYR-69 | feature/PYR-69-league-completion | #44 | 2026-03-11 |
| PYR-67 | feature/PYR-67-gw38-cutoff | #43 | 2026-03-11 |
| PYR-83 | feature/PYR-83-club-badges | #41 | 2026-03-10 |
| PYR-71 | feature/PYR-71-onboarding | #45 | 2026-03-11 |
| PYR-84 | fix/PYR-84-pick-title-flash | #46 | 2026-03-11 |
| PYR-62 | feature/PYR-62-results-history | #33 | 2026-03-09 |
| PYR-49 | feature/PYR-49-usage-guide | #22 | 2026-03-08 |
| PYR-46 | feature/PYR-46-swiftui-patterns | #23 | 2026-03-08 |

## Rules

1. **One branch per ticket** — never share branches between tickets
2. **Check before starting** — if another agent is modifying the same files, coordinate or sequence
3. **Update on start** — add your row to Active Work before writing any code
4. **Update on finish** — move your row to Recently Completed when PR is raised
5. **File conflicts** — if two tickets touch the same file, the second one must list the first as a dependency in Linear
