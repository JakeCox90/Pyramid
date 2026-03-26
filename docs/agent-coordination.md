# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| — | — | — | — | — | — |

> No active agent work as of 2026-03-26.

## Recommended Queue (2026-03-26)

<!-- Next agent session: pick from this queue in order -->
<!-- 1. PYR-182: Homepage hero card survived/eliminated variant (Homepage, High, 2pts) -->
<!-- 2. PYR-186: Leave league with confirmation modal (Community, High, 2pts) — DONE -->
<!-- 3. PYR-99: Survival celebration reactions (Community, Medium, 2pts) -->
<!-- 4. PYR-161: Post-elimination spectator experience (Community, Medium, 2pts) -->
<!-- 5. PYR-183: Players remaining redesign (Homepage, High, 3pts) -->
<!-- 6. PYR-103: Shared tension moments (Community, Medium, 2pts) -->

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
| PYR-187 | feature/PYR-187-league-detail-tabs | #114 | 2026-03-26 |
| PYR-186 | feature/PYR-186-leave-league | #113 | 2026-03-26 |
| PYR-188 | feature/PYR-188-recap-close-button | #115 | 2026-03-26 |
| PYR-185 | feature/PYR-185-elimination-card-league-state | #112 | 2026-03-26 |
| PYR-170 | feature/PYR-170-paid-features-toggle | #110 | 2026-03-26 |
| CI | chore/ci-speedup | #116 | 2026-03-26 |
| PYR-149 | feature/PYR-149-wire-odds-v2 | #109 | 2026-03-25 |
| PYR-169 | feature/PYR-169-remove-broadcast | #108 | 2026-03-25 |
| PYR-167 | feature/PYR-167-extract-venue | #107 | 2026-03-25 |
| PYR-98 | feature/PYR-98-elimination-cards | #106 | 2026-03-25 |
| PYR-160 | feature/PYR-160-wire-wallet | #104 | 2026-03-25 |
| PYR-162 | feature/PYR-162-gw-recap-empty-state | #103 | 2026-03-25 |
| PYR-163 | feature/PYR-163-delete-picksheaderview | #102 | 2026-03-25 |
| PYR-97 | feature/PYR-97-pick-reveal-animation | #101 | 2026-03-25 |

## Rules

1. **One branch per ticket** — never share branches between tickets
2. **Check before starting** — if another agent is modifying the same files, coordinate or sequence
3. **Update on start** — add your row to Active Work before writing any code
4. **Update on finish** — move your row to Recently Completed when PR is raised
5. **File conflicts** — if two tickets touch the same file, the second one must list the first as a dependency in Linear
