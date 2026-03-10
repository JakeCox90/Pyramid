# Agent Coordination Ledger

> **Every Claude instance MUST read this file at session start and update it when starting/finishing work.**
> This prevents branch conflicts and duplicate effort across parallel agents.

## Active Work

| Ticket | Branch | Agent | Status | Key Files | Started |
|--------|--------|-------|--------|-----------|---------|
| PYR-68 | feature/PYR-68-gameweek-advancement | Backend | In Review | `supabase/functions/poll-live-scores/index.ts` | 2026-03-10 |
| PYR-70 | feature/PYR-70-sign-out | iOS | In Review | `ios/Pyramid/Sources/Features/Profile/ProfileView.swift` | 2026-03-10 |
| PYR-80 | feature/PYR-80-browse-free-leagues | iOS | In Review | `ios/Pyramid/Sources/Features/Leagues/BrowseLeaguesView.swift` | 2026-03-10 |

## Recently Completed

| Ticket | Branch | PR | Merged |
|--------|--------|----|--------|
| PYR-62 | feature/PYR-62-results-history | #33 | Pending |
| PYR-49 | feature/PYR-49-usage-guide | #22 | Pending |
| PYR-46 | feature/PYR-46-swiftui-patterns | #23 | Pending |

## Rules

1. **One branch per ticket** — never share branches between tickets
2. **Check before starting** — if another agent is modifying the same files, coordinate or sequence
3. **Update on start** — add your row to Active Work before writing any code
4. **Update on finish** — move your row to Recently Completed when PR is raised
5. **File conflicts** — if two tickets touch the same file, the second one must list the first as a dependency in Linear
