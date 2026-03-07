# Execution Plan: Phase 0 — Foundation

**File:** docs/plans/active/phase-0-foundation.md
**Linear project:** Pyramid
**Created:** 2026-03-07
**Owner:** Orchestrator
**Status:** IN PROGRESS

---

## Goal

Establish all infrastructure, tooling, documentation, and decisions required before any feature development begins. Gate 0 sign-off is the exit condition.

---

## Context

- App: Premier League Last Man Standing iOS app
- Stack (proposed): SwiftUI + Supabase + API-Football
- All decisions require human approval at Gate 0 before Phase 1 begins
- No code is written until Gate 0 is approved

---

## Steps

| ID | Task | Linear | Agent | Status | Notes |
|---|---|---|---|---|---|
| 1 | Set up Supabase project (dev + staging + prod) | PYR-5 / LMS-001 | Backend | DONE | Dev + prod projects live. Migration applied. Staging not yet provisioned. |
| 2 | Configure GitHub Actions CI (build + test) | PYR-6 / LMS-002 | Backend/QA | TODO | Requires Xcode project to exist first — blocked on iOS scaffold |
| 3 | Create Figma design system | PYR-7 / LMS-003 | Design | TODO | Can start independently |
| 4 | Write ADR-001: Database & backend platform | PYR-8 / LMS-004 | Orchestrator | DONE | docs/adr/ADR-001-database-backend-platform.md |
| 5 | Write ADR-002: iOS tech stack | PYR-9 / LMS-005 | Orchestrator | DONE | docs/adr/ADR-002-ios-tech-stack.md |
| 6 | Write ADR-003: PL data provider | PYR-10 / LMS-006 | Orchestrator | DONE | docs/adr/ADR-003-pl-data-provider.md |
| 7 | Create Notion workspace structure | PYR-11 / LMS-007 | Orchestrator | DONE | Completed 2026-03-07 |
| 8 | Configure API-Football account + test fixtures | PYR-12 / LMS-008 | Backend | DONE | API validated (380 fixtures, 20 teams, 38 rounds). Free tier covers dev (2022–2024). Basic tier (~£8/mo) needed for 2025 season in production. |
| 9 | Write game rules specification | PYR-13 / LMS-009 | Orchestrator | DONE | docs/game-rules/rules.md |
| 10 | [GATE 0] Human review: Decision log sign-off | PYR-14 / LMS-010 | Human | BLOCKED | Blocked on steps 4, 5, 6, 9 (now unblocked) |

---

## Decision Log

| Decision | Outcome | Date |
|---|---|---|
| Who writes the ADRs in Phase 0? | Orchestrator (faster than spawning Architect agent for pure doc work) | 2026-03-07 |
| Who writes the game rules spec? | Orchestrator (PM Agent not yet spawned; rules are needed for Gate 0) | 2026-03-07 |

---

## Open Questions (GATE Required)

These items are marked as needing human input before they can be resolved:

1. **Postponed match wildcard rule** — exact mechanic needs approval (rules.md §6.1)
2. **Entry fee limits** — minimum and maximum for paid leagues (rules.md §7.2)
3. **Platform fee percentage** — rules.md §7.4
4. **Joint winner charity remainder** — rules.md §5.2
5. **Supabase account** — needs human to create org and provision projects (PYR-5)
6. **API-Football account** — needs human to create account and provide API key (PYR-12)
7. **Figma account** — needs Design Agent or human to set up (PYR-7)

---

## Definition of Done (Gate 0)

- [x] ADR-001 written
- [x] ADR-002 written
- [x] ADR-003 written
- [x] Game rules specification written
- [x] Notion workspace created
- [x] Linear project + all Phase 0 tasks created
- [ ] Supabase projects provisioned (dev + staging + prod)
- [ ] GitHub Actions CI passing
- [ ] API-Football account configured + fixtures validated
- [ ] Human has reviewed decision log and responded APPROVED

---

## Blockers

| Blocker | Affects | Owner | Escalated? |
|---|---|---|---|
| Supabase account needs creating | PYR-5 (LMS-001) | Human | No — waiting for Gate 0 review |
| API-Football account needs creating | PYR-12 (LMS-008) | Human | No — waiting for Gate 0 review |
| iOS Xcode project not yet created | PYR-6 (LMS-002) | Backend Agent | No — CI can't run without a project |
