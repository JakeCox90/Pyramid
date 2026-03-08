# Execution Plan: Phase 1 — Core Game (Pick & Play)

**File:** docs/plans/active/phase-1-core-mvp.md
**Linear parent:** PYR-15
**Created:** 2026-03-07
**Owner:** Orchestrator
**Status:** IN PROGRESS

---

## Goal

Users can sign up, create or join a free league, submit a weekly pick, and see who survived.
This is the playable MVP — no payments, no live scoring cron, free leagues only.

---

## Context

- Phase 0 complete. Gate 0 approved 2026-03-07.
- PR #1 (feat: Phase 0 foundation) → main. **Pending human approval to merge.**
- Phase 1 feature branches must be cut from main after PR #1 merges.
- iOS scaffold: Auth (real), LeaguesView (placeholder), ProfileView (placeholder).
- Supabase schema: profiles, leagues, league_members, picks, fixtures, gameweeks, settlement_log — all in place with RLS.
- Edge Functions in place: sync-fixtures, poll-live-scores. Still needed: create-league, join-league, submit-pick, settle-picks.

---

## Steps

| ID | Task | Linear | Agent | Status | Notes |
|---|---|---|---|---|---|
| 1 | PRD: League Creation | PYR-16 | iOS + Backend | TODO | Acceptance criteria written in Linear |
| 2 | PRD: League Joining | PYR-17 | iOS + Backend | TODO | Acceptance criteria written in Linear |
| 3 | PRD: Pick Submission | PYR-18 | iOS + Backend | TODO | Acceptance criteria written in Linear |
| 4 | PRD: League Standings | PYR-19 | iOS | TODO | Acceptance criteria written in Linear |
| 5 | Backend: settle-picks | PYR-20 | Backend | TODO | **Human review before prod deploy** |

---

## Dependency Order

```
PR #1 merged → main
    ↓
PYR-16 (create-league) ← Backend Agent
PYR-16 (iOS Create League screen) ← iOS Agent
    ↓
PYR-17 (join-league) ← Backend Agent
PYR-17 (iOS Join League screen) ← iOS Agent
    ↓
PYR-18 (submit-pick) ← Backend Agent
PYR-18 (iOS Pick screen) ← iOS Agent
    ↓
PYR-19 (League Standings) ← iOS Agent
PYR-20 (settle-picks) ← Backend Agent [Human review before prod]
```

---

## Decision Log

| Decision | Outcome | Date |
|---|---|---|
| Phase 1 scope | Free leagues only — no paid/staking in Phase 1 | 2026-03-07 |
| settle-picks trigger | Invoked by poll-live-scores when status transitions to FT | 2026-03-07 |

---

## Open Questions (GATE Required)

None at Phase 1 start. Refer to game-rules/rules.md §6–8 for staking/wallet — out of scope for Phase 1.

---

## Definition of Done (Gate 1)

- [ ] Create free league flow works end-to-end
- [ ] Join league via code works end-to-end
- [ ] Pick submission: select team, lock at kick-off, change before deadline
- [ ] Settlement: picks settled correctly for win/draw/loss/void/mass-elimination
- [ ] League standings: correct visibility (pre/post deadline), correct order
- [ ] CI passes on all PRs
- [ ] 80% coverage on all new Edge Functions and ViewModels
- [ ] settle-picks reviewed by human before prod deployment

---

## Blockers

| Blocker | Affects | Owner | Status |
|---|---|---|---|
| PR #1 not yet merged to main | All Phase 1 branches | Human | Waiting for 1 approval on GitHub PR #1 |
