# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| PYR-191 | feature/PYR-191-production-cicd | Orchestrator | In Progress | .github/workflows/deploy-*.yml, docs/runbooks/production-deployment.md, ios/Config/Release.xcconfig, ios/exportOptions.plist | 2026-03-27 |

## Recommended Queue (2026-03-27)

<!-- Next agent session: pick from this queue in order -->
<!-- 1. PYR-191: Production CI/CD pipeline (Launch Readiness, Urgent) — biggest launch blocker -->
<!-- 2. PYR-192: Error monitoring / crash reporting (Launch Readiness, Urgent) -->
<!-- 3. PYR-161: Post-elimination spectator experience (Community V1, Medium, 2pts) — completes V1 milestone -->
<!-- 4. PYR-194: Rate limiting on Edge Functions (Launch Readiness, High) — follows PYR-193 -->
<!-- 5. PYR-183: Players remaining redesign (Homepage, High, 3pts) -->
<!-- 6. PYR-103: Shared tension moments (Community V2, Medium, 2pts) -->
<!-- 7. PYR-195: Uptime monitoring and health checks (Launch Readiness, High) -->
<!-- 8. PYR-190: Analytics infrastructure (Launch Readiness, High) -->

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
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
