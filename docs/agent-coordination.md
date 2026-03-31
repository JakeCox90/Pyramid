# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| PYR-103 | feature/PYR-103-shared-tension-moments | Claude | In Progress | TensionMoment.swift, TensionBannerView.swift, LeagueDetailViewModel.swift, LeagueDetailView+Standings.swift | 2026-03-31 |

## Recommended Queue (2026-03-31, updated 13:30)

<!-- Priority order (2026-03-31 whatnext audit): PYR-103 IN PROGRESS, PYR-108 (Records wall, 2pts, completes C&S V3 milestone), PYR-94 (Stats widget, 2pts, completes Homepage V3 milestone), PYR-100 (Chat backend, 5pts, unblocks PYR-101), PYR-111 (Rival tracking, 3pts, Todo), PYR-110 (Social push, 2pts). Also: PYR-189 needs Figma first; PYR-215/216/217 need refinement. -->

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
| PYR-213 | feature/PYR-213-figma-token-source | #144 | 2026-03-31 |
| PYR-198 | feature/PYR-198-verify-prod-deploy | #143 | 2026-03-31 |
| PYR-209 | feature/PYR-209-uptime-monitoring | #145 | 2026-03-31 |
| PYR-210 | feature/PYR-210-ios-client-update | #142 | 2026-03-31 |
| PYR-190 | feature/PYR-190-analytics-infrastructure | #137 | 2026-03-31 |
| PYR-197 | feature/PYR-197-prod-migration-strategy | #135 | 2026-03-30 |
| PYR-195 | feature/PYR-195-health-check | #134 | 2026-03-30 |
| PYR-194 | feature/PYR-194-rate-limiting | #131 | 2026-03-30 |
| PYR-161 | feature/PYR-161-spectator-experience | #133 | 2026-03-30 |
| PYR-207 | feature/PYR-207-used-teams-docs | #132 | 2026-03-30 |
| PYR-204 | feature/PYR-204-atomic-stake-deduction | #130 | 2026-03-27 |
| PYR-203 | feature/PYR-203-withdrawal-atomicity | #129 | 2026-03-27 |
| PYR-202 | feature/PYR-202-topup-production-guard | #122 | 2026-03-27 |
| PYR-193 | feature/PYR-193-security-hardening | #120 | 2026-03-27 |
| PYR-173 | feature/PYR-173-visual-qa-snapshots | #119 | 2026-03-26 |
| PYR-99 | feature/PYR-99-survival-reactions | #118 | 2026-03-26 |
| PYR-182 | feature/PYR-182-hero-card-settlement | #117 | 2026-03-26 |
| PYR-187 | feature/PYR-187-league-detail-tabs | #114 | 2026-03-26 |
| PYR-186 | feature/PYR-186-leave-league | #113 | 2026-03-26 |
| PYR-188 | feature/PYR-188-recap-close-button | #115 | 2026-03-26 |
| PYR-185 | feature/PYR-185-elimination-card-league-state | #112 | 2026-03-26 |
| PYR-170 | feature/PYR-170-paid-features-toggle | #110 | 2026-03-26 |
| CI | chore/ci-speedup | #116 | 2026-03-26 |

## Rules

1. **One branch per ticket** — never share branches between tickets
2. **Check before starting** — if another agent is modifying the same files, coordinate or sequence
3. **Update on start** — add your row to Active Work before writing any code
4. **Update on finish** — move your row to Recently Completed when PR is raised
5. **File conflicts** — if two tickets touch the same file, the second one must list the first as a dependency in Linear
