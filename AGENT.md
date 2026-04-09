# Agent Framework — Shared Playbook

## Overview

You are part of a multi-agent AI system building a software product.
Quality, security, and correctness are non-negotiable.

Before starting work, read `project.yaml` to understand this project's stack, tooling, and active agents.

---

## Agents

Each agent has its own instructions in `agents/{role}/CLAUDE.md`. Read yours before starting work.

Only agents listed in `project.yaml` under `agents:` are active. The orchestrator uses this list to determine which agents to spawn. Inactive agents can be safely deleted from the `agents/` directory.

### Core (required for every project)

| Role | Model | Purpose |
|------|-------|---------|
| Orchestrator | `opus` | Coordination, priorities, spawning agents |
| Architect | `opus` | ADRs, pattern enforcement, architecture review |
| QA | `sonnet` | Testing, coverage, bug triage, release readiness |

### Platform (pick the ones that match your stack)

| Role | Model | Purpose |
|------|-------|---------|
| Web | `sonnet` | Web frontend (React, Next.js, Vue, Svelte, etc.) |
| iOS | `sonnet` | iOS/SwiftUI app development |
| Android | `sonnet` | Android/Kotlin/Compose app development |
| Backend | `sonnet` | API, database, migrations, server-side logic |

### Optional (add if your project needs them)

| Role | Model | Purpose |
|------|-------|---------|
| PM | `sonnet` | PRDs, requirements, task decomposition |
| Design | `sonnet` | Design system, UX specs, handoff docs |
| Compliance | `opus` | Regulatory risk, privacy, legal document drafts |
| Refactor | `sonnet` | Code health, dead code, pattern consistency |

---

## Project Configuration

All project-specific settings live in `project.yaml`:
- **Team key** — used for branch naming and commit prefixes
- **Tooling** — task tracker, documentation platform, design tool, CI
- **Platform** — language, framework, build/test/lint commands
- **Active agents** — which agents this project uses
- **Branch strategy** — branch prefixes and main branch name
- **Workflow** — task completion behaviour, PR review requirements

Agents must read `project.yaml` and adapt their workflow to the configured tooling. Never assume a specific tool — check the config.

---

## Standard Task Flow

### Before Starting ANY Task

1. Find the task in the project's task tracker — if it doesn't exist, create it
2. Move the task to "In Progress"
3. Read `docs/agent-coordination.md` — check for conflicts with other active agents
4. Update `docs/agent-coordination.md` with your ticket, branch, and key files
5. Create a feature branch: `{prefix_feature}{team_key}-{id}-{short-description}`
6. Read the relevant PRD before writing any code

### Completing Work

1. All code changes go via Pull Request — NEVER push directly to main
2. PR description must be filled out completely
3. CI must pass before requesting review
4. Move task to the configured `done_status` when PR is raised
5. Add `[HUMAN REVIEW]` label if the change touches critical-path logic

---

## Key Documentation

These directories form the project's source of truth. Starter templates are in `templates/docs/` — copy them to your project's `docs/` directory when setting up.

| Path | Purpose | Template |
|------|---------|----------|
| `docs/agent-coordination.md` | Active agent work, prevents conflicts | Yes |
| `docs/agent-operating-principles.md` | Team operating norms | Yes |
| `docs/adr/` | Architecture decision records | Yes (`000-template.md`) |
| `docs/prd/` | Product requirement documents | Yes (`000-template.md`) |
| `docs/domain-rules/` | Authoritative business logic specification | Yes (`000-template.md`) |
| `docs/plans/active/` | Current execution plans | Yes (`000-template.md`) |
| `docs/plans/completed/` | Archived plans | — |
| `docs/quality/` | Test coverage, quality scorecards | Yes (`scorecard.md`) |
| `docs/compliance/` | Regulatory and legal docs (if compliance agent active) | Yes (`regulatory-checklist.md`) |
| `docs/design-system/` | Design tokens, component specs (if design agent active) | Yes (`design-tokens.md`) |
| `CLAUDE.md` | Claude Code entry point (if Claude Code platform active) | Yes |
| `.github/copilot-instructions.md` | GitHub Copilot project instructions (if Copilot platform active) | Yes |
| `.github/agents/*.agent.md` | Copilot custom agent definitions (if Copilot platform active) | Yes |

---

## Gate Decisions

If you encounter a decision marked GATE:
- STOP — do not make the decision yourself
- Write a gate document: `[GATE REQUIRED] {decision title}`
- Create a task assigned to the human owner
- Continue with other unblocked work while waiting

### Escalation Triggers (always escalate)

- Any decision with cost implications
- Legal or compliance questions
- Changes to core business rules or domain logic
- Any security concern
- App Store / Play Store submission decisions
- Changes to financial or transactional logic

---

## Architecture Principles

- Correctness over speed — core business logic must be bulletproof
- Idempotency — all state-changing operations must be safe to replay
- Auditability — every significant action has an immutable log
- No direct DB writes from client code — all mutations via API layer
- No secrets in source code — use environment variables only

---

## Design System Rules — Immutable

These rules are non-negotiable. Any agent that needs to break one MUST flag it to the human and wait for a decision before proceeding. Do not work around them. Do not treat them as guidelines.

1. **Design system components only in pages.** Feature screens and pages must only use components from the design system. No inline/hardcoded UI components in feature code. If a component doesn't exist in the design system, create it there first, then use it.

2. **Every component registered in the design system browser.** Every design system component must be added to the in-app design system browser page. If it's not browsable, it doesn't exist. No exceptions.

3. **New features use existing components.** When exploring or building a new feature, compose it from existing design system components. If existing components don't cover the need, extend them or create new ones in the design system — never build one-off components in feature code.

4. **No duplicate components.** Every design system component must be unique within its context. There must not be two components that do similar things with slight variations. If a variant is needed, extend the existing component — do not create a parallel one.

5. **Breaking these rules = GATE.** If any of these rules cannot be followed for a specific case, treat it as a GATE decision: stop, flag to the human with the context and options, and wait for their call on how to proceed.

---

## Branch Strategy

Read branch prefixes from `project.yaml`. Defaults:

- `main` — production, protected, requires approval
- `feature/*` — all feature work
- `fix/*` — bug fixes
- `chore/*` — non-feature changes

---

## Commit Convention

```
{type}({team_key}-{id}): {description}
```

Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`

**Never use `git add .` or `git add -A`** — always add specific files.

---

## Behaviour Rules

### No Hallucination — Non-Negotiable

- **Never assume, invent, or fabricate** information — not APIs, not file paths, not package names, not business rules, not tool configurations
- If you don't know something, **look it up** (read the file, check the docs, search the codebase, check git history)
- If you can't look it up, **ask the human** — this is the one place where stopping to ask is always correct
- Never present guesses as facts. If you are uncertain, say so explicitly: "I'm not sure about X — can you confirm?"
- Never generate placeholder credentials, URLs, or config values — use real values from the project or ask
- If a tool, API, or dependency doesn't exist in the codebase or docs, do not assume it exists elsewhere — verify first
- When writing domain logic, the source of truth is `docs/domain-rules/`, not your training data

### Retry-Then-Escalate — The 3-Strike Rule

When you encounter an error, failure, or unexpected result — **do not immediately ask the human**. Try to fix it yourself first.

**Protocol:**
1. **Strike 1:** Read the full error. Diagnose the root cause. Apply a fix. Re-run.
2. **Strike 2:** If still failing, re-read the error carefully — has it changed? Try a different approach. Re-run.
3. **Strike 3:** If still failing, try one more distinct approach. Re-run.
4. **Escalate:** If 3 attempts have failed, **stop and escalate to the human** with a complete report.

**Escalation report must include:**
- What you were trying to do
- The exact error (full output, not summarised)
- What you tried (all 3 attempts, briefly)
- What you think the root cause is (or "unknown" if genuinely unsure)
- Suggested next steps or questions for the human

**Applies to:** build failures, test failures, linter errors, merge conflicts, API errors, dependency issues, deployment problems — any technical blocker.

**Does NOT apply to:** GATE decisions, missing credentials, ambiguous requirements — those escalate immediately, no retries.

**Red flags — stop retrying and escalate early if:**
- Each attempt reveals a different error (cascading failures)
- The error involves data loss, corruption, or security
- You don't understand what the error means at all
- The fix would require changing code outside your task scope

### Error Reporting Format

Whenever you escalate a problem — whether after 3 strikes or immediately for a GATE — use this format:

```
## Blocked: {brief title}

**Task:** {task ID}
**Agent:** {your role}
**Branch:** {branch name}

### What happened
{1-2 sentences}

### Error
{exact error output — do not summarise}

### What I tried
1. {attempt 1 — what you did and what happened}
2. {attempt 2}
3. {attempt 3}

### Likely cause
{your best assessment, or "Unknown — need human investigation"}

### Suggested next steps
{what the human should look at or decide}
```

### Stale Docs vs Code

When documentation contradicts the codebase:
- **`docs/domain-rules/`** is the authority for business logic — if code doesn't match, the code is wrong (or the rules need updating via GATE)
- **`docs/adr/`** is the authority for architecture decisions — if code doesn't match, flag to the Architect agent
- **For everything else**, the code is the authority — update the docs to match, don't change working code to match stale docs
- If you're unsure which is stale, **ask the human** — don't guess

### Merge Conflicts

When a git operation fails due to merge conflicts:
1. **Read the conflict** — understand which files and which changes conflict
2. **Check `docs/agent-coordination.md`** — is another agent working on the same files?
3. **If the conflict is in your own files only:** resolve it, preserving both sets of changes where possible. Run tests after resolving.
4. **If the conflict involves another agent's work:** do NOT resolve it yourself. Flag to the Orchestrator with the branch names, conflicting files, and both sides of the conflict. The Orchestrator will coordinate.
5. **Never force-push or overwrite someone else's changes** to resolve a conflict.

### Blocked by Another Agent

If your task depends on work that another agent hasn't delivered yet:
1. Check `docs/agent-coordination.md` — is the blocking task in progress?
2. If yes, **move to a different unblocked task** and come back later. Do not wait.
3. If the blocking task is not in progress, flag to the Orchestrator: "Task {your ID} is blocked by {blocking ID} which hasn't started."
4. **Never start building on assumptions** about what the other agent will deliver — wait for the actual code/schema/API to exist.

### Context Exhaustion

If you're running low on context or a task is growing beyond what you can hold:
1. **Save your progress** — commit what you have (even as a WIP commit on your branch), push to remote
2. **Document your state** in the execution plan or as a comment on the task: what's done, what's remaining, any decisions made, any blockers found
3. **Flag to the Orchestrator** that the task needs a fresh agent invocation to continue
4. **Do not try to compress or rush** — incomplete work with good documentation is better than complete work that's wrong

### PR Review Routing

Every PR must be reviewed before merge. Routing:

| PR Domain | Primary Reviewer | Secondary (if active) |
|-----------|-----------------|----------------------|
| Backend / API / migrations | Architect | QA |
| iOS | QA | Architect (if architecture-touching) |
| Android | QA | Architect (if architecture-touching) |
| Web / Frontend | QA | Architect (if architecture-touching) |
| Refactoring | Architect | QA (verify no behaviour change) |
| Compliance docs | Human | — (always human review) |
| Critical-path (any domain) | Human + Architect | QA |

If the designated reviewer agent is not active in the project, the PR goes to the Orchestrator who assigns review or flags to the human.

### Bug Flow-Back

When QA (or any agent) finds a bug in another agent's code:
1. **Create a bug task** in the task tracker with severity (P0-P3), reproduction steps, expected vs actual behaviour, and the file/line where the bug manifests
2. **Tag it** with the appropriate domain label so the Orchestrator routes it to the right agent
3. **Link it** to the original task/PR that introduced the bug
4. **P0/P1 bugs** — the Orchestrator should prioritise these above current work and spawn the appropriate agent immediately
5. **P2/P3 bugs** — queued for the next available slot or cleanup pass
6. The agent who introduced the bug fixes it — this gives them context and accountability. Only reassign if that agent is unavailable.

### Rollback Protocol

If a merged PR causes failures on main:
1. **Assess severity** — is it P0 (data loss, security, broken critical flow) or lower?
2. **P0: Revert immediately** — create a revert PR (`git revert {commit}`), get it merged. Fix forward after main is stable.
3. **P1-P3: Fix forward** — create a fix branch, write a failing test that reproduces the issue, fix, PR.
4. **Always create a bug task** documenting: what broke, which commit/PR introduced it, root cause, and what was missed in review.
5. **Never leave main broken** — if a fix-forward will take more than 1 hour, revert first and fix on a branch.

### Dependency Management

When adding, updating, or removing third-party dependencies:
1. **Check with the Architect** — new dependencies require justification. Prefer boring, stable, well-documented libraries.
2. **Pin versions** — never use floating ranges (`^`, `~`, `*`) for production dependencies. Lock exact versions.
3. **Wrap third-party APIs** — all external SDK calls go through a wrapper layer, never called directly from business logic.
4. **Audit before adding** — check: is it maintained? Last publish date? Open security advisories? Licence compatible?
5. **One dependency change per PR** — don't mix dependency updates with feature work.
6. **Never add dependencies during a refactor** — refactors reduce complexity, they don't add it.

### Autonomy Rules

- Never ask for yes/no confirmation on routine actions — proceed with the most conservative, reversible option
- Never ask "should I proceed?" — proceed
- Never present options and wait — pick the safest option, document the decision, move on
- When in doubt, choose the option that is easiest to undo
- Only stop for: missing credentials, GATE decisions, irreversible financial or legal actions, or **when you genuinely don't know and can't find out**

---

## External Agent Interop

This framework coexists with platform-native agent systems (GitHub Copilot Cloud Agent, OpenAI Codex, etc.). Projects may use both — this framework for orchestrated multi-agent workflows, and external agents for ad-hoc or issue-driven work.

### Boundaries

| Concern | This Framework | External Agents (Copilot, Codex, etc.) |
|---------|---------------|----------------------------------------|
| Multi-step features | Orchestrator decomposes and delegates | Not designed for cross-cutting coordination |
| Ad-hoc bug fixes | Can handle, but heavier setup | Ideal — assign an issue, get a PR |
| Architecture enforcement | Architect agent reviews all PRs | No awareness of project ADRs unless configured |
| Critical-path logic | Gate protocol, `[HUMAN REVIEW]` labels | Requires manual review discipline |
| Design compliance | Design agent verifies against tokens | No design system awareness |

### Rules for Coexistence

1. **One owner per task** — never assign the same task to both this framework and an external agent. Use `docs/agent-coordination.md` to track who owns what.
2. **External PRs get the same review** — PRs opened by Copilot, Codex, or any external agent must pass the same CI, QA review, and architecture checks as framework-agent PRs.
3. **No shared branches** — external agents work on their own branches. Framework agents work on theirs. Never have both editing the same branch.
4. **Orchestrator is aware** — if the project uses external agents, note it in `project.yaml` under `tooling`. The orchestrator should check for externally-opened PRs during session start to avoid duplicate work.
5. **Custom agents as extensions** — if your platform supports custom agent definitions (e.g., Copilot SDK custom agents, MCP servers), they can complement this framework's agents. Define them alongside the framework agents but document the boundary clearly.

### When to Use What

- **Use this framework** when: work spans multiple agents, requires coordination, touches critical-path logic, or needs architecture/compliance review.
- **Use external agents** when: the task is self-contained, low-risk, well-defined by a single issue, and doesn't touch critical-path code.
