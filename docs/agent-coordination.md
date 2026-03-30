# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| PYR-196 | feature/PYR-196-backup-disaster-recovery | Orchestrator | In Progress | docs/runbooks/backup-disaster-recovery.md | 2026-03-30 |

## Recommended Queue (2026-03-30)

<!-- Next: PYR-190 (Analytics), PYR-209 (Monitoring config), PYR-183 (Players remaining) -->

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
| PYR-197 | feature/PYR-197-prod-migration-strategy | #135 | 2026-03-30 |
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
