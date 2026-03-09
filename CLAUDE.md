# Last Man Standing — Claude Code Agent Instructions

## Project Overview
You are part of a multi-agent AI system building a Premier League Last Man Standing iOS app.
This is a real product with real users and real money (staking). Quality, security, and correctness are non-negotiable.

## Tooling
- **GitHub**: All code, PRs, issues, ADRs, migrations
- **Linear**: ALL tasks must exist in Linear before work begins
- **Notion**: Strategy docs, PRDs, decision log, daily status
- **Figma**: All UI designs before any iOS engineering starts

## Agent Instructions
Each agent has its own CLAUDE.md in agents/{role}/CLAUDE.md. Read yours before starting work.
- Orchestrator: agents/orchestrator/CLAUDE.md (opus)
- PM: agents/pm/CLAUDE.md (sonnet)
- Architect: agents/architect/CLAUDE.md (opus)
- Design: agents/design/CLAUDE.md (sonnet)
- iOS: agents/ios/CLAUDE.md (sonnet)
- Backend: agents/backend/CLAUDE.md (sonnet)
- QA: agents/qa/CLAUDE.md (sonnet)
- Compliance: agents/compliance/CLAUDE.md (opus)
- Refactor: agents/refactor/CLAUDE-refactor.md (sonnet)

## Key Docs
- Agent operating principles: docs/agent-operating-principles.md
- Golden principles: docs/golden-principles.md
- Game rules: docs/game-rules/
- ADRs: docs/adr/
- PRDs: docs/prd/
- Active plans: docs/plans/active/

## Non-Negotiable Rules

### Before Starting ANY Task
1. Find the Linear task — if it doesn't exist, create it
2. Move Linear task to "In Progress"
3. Create a feature branch: feature/LMS-{linear-task-id}-{short-description}
4. Read relevant PRD in Notion before writing any code

### Completing Work
1. All code changes go via Pull Request — NEVER push directly to main or develop
2. PR template must be filled out completely
3. CI must pass before requesting review
4. Move Linear task to "In Review" when PR is raised

### Gate Decisions
If you encounter a decision marked GATE:
- STOP — do not make the decision yourself
- Write a Notion page: [GATE REQUIRED] {decision title}
- Create a Linear task assigned to the human owner
- Continue with other unblocked work while waiting

### Escalation Triggers (always escalate)
- Any decision with cost implications
- Legal or compliance questions
- Changes to core game rules
- Any security or fraud concern
- App Store submission decisions
- Settlement logic changes

## Architecture Principles
- Correctness over speed — pick/settle logic must be bulletproof
- Idempotency — all settlement operations must be safe to replay
- Auditability — every pick, result, and financial transaction has an immutable log
- No direct DB writes from iOS client — all mutations via Edge Functions
- No secrets in source code — use environment variables only

## Branch Strategy
- main — production only, protected, requires 1 approval
- develop — integration branch, requires passing CI
- feature/* — all feature work
- fix/* — bug fixes
- chore/* — non-feature changes

## Current Phase
Phase 2 — Development Complete. Awaiting GATE decisions (PYR-26: Compliance, PYR-34: Sign-off). See docs/plans/active/ for current execution plans.

## Behaviour Rules
- Never ask for yes/no confirmation — proceed with the most conservative, reversible option
- Never ask "should I proceed?" — proceed
- Never present options and wait — pick the safest option, document the decision, move on
- When in doubt, choose the option that is easiest to undo
- Only stop for: missing credentials, GATE decisions, irreversible financial or legal actions
