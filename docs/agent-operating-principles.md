# Agent Operating Principles
> Distilled from large-scale agent-driven software development.
> This is the authority on HOW to work. Read it once per project, reference it when stuck.

## The Core Mental Model

**Humans steer. Agents execute.**

Three things follow from this:

1. **Speed of correction beats perfection.** When output is wrong, the fix is almost never "try harder" — it is "what tool, guardrail, or document is missing?"

2. **What the agent cannot see does not exist.** Context in Slack, email, or someone's head is invisible. Every decision, rule, and principle must be in the repository to be real.

3. **Constraints are multipliers.** Strict rules feel pedantic to humans. For agents they apply to every line ever written — the highest-leverage investment possible.

---

## Decision Hierarchy

When facing a choice, follow this order:

| Level | Source | Action |
|---|---|---|
| 1 | Explicit rule in docs/ | Follow it. No deviation. |
| 2 | Existing pattern in codebase | Replicate exactly. |
| 3 | Implied by ADR or PRD | Apply, log reasoning in PR. |
| 4 | Judgement within agent's domain | Decide, document in PR, flag to Orchestrator. |
| 5 | GATE item or cross-domain | STOP. Escalate. Never guess. |

---

## When Struggling

Struggling is a signal, not a failure. Ask these questions:

- What **capability** is missing? (tool, API access, data)
- What **guardrail** is missing? (lint rule, type enforcement, test)
- What **document** is missing or stale? (PRD, ADR, game rules)
- Is the **task too large**? Break it down further.

Fix the environment. Then re-run. This compounds — every improvement helps all future runs.

---

## Agent Coordination

When multiple agents run in parallel, they must coordinate to avoid merge conflicts and duplicate work.

- **Read `docs/agent-coordination.md` at session start** — check what other agents are working on
- **Update it when you start/finish a ticket** — so parallel instances don't collide
- **One branch per ticket** — never share branches between tickets
- **If two tickets touch the same files**, sequence them via Linear dependencies — never work in parallel on the same file

---

## Repository as System of Record

CLAUDE.md = map (under 120 lines, pointers only).
docs/ = the full knowledge base.

**Doc freshness rule:** Every agent that changes behaviour updates the relevant doc in the same PR. Stale docs cause confident wrong behaviour — they are worse than no docs.

**One home per piece of knowledge.** No duplication. If something is said in two places, one of them will become stale.

---

## Pull Request Philosophy

Corrections are cheap. Waiting is expensive.

In a high-throughput agent system, blocking on a perfect PR costs more than merging and fixing forward. The goal is **flow, not ceremony** — but every PR must meet the minimum bar (see individual agent CLAUDE.md files).

Human review is reserved for high-stakes, irreversible, or legally significant changes. Everything else is agent-to-agent.

---

## Entropy Management

Agents replicate patterns — good and bad. Left unchecked, a codebase drifts.

The fix: **weekly garbage collection** (Orchestrator-run).
- QA scans coverage gaps
- Architect checks pattern drift vs ADRs
- PM reviews stale PRDs
- Small fix PRs from this pass auto-merge if CI passes

**The pattern rule:** When you find a bad pattern in one place, fix it in all places in the same PR. Never fix one and leave nine — agents will continue replicating the others.

---

## Execution Plans

For tasks that span multiple sessions or involve 2+ agents: create an Execution Plan.

File: `docs/plans/active/phase-{number}-{short-description}.md`

Required sections: Goal | Context | Steps (TODO/IN PROGRESS/DONE/BLOCKED) | Decision Log | Open Questions | Definition of Done

When complete: move to `docs/plans/completed/` — never delete. Completed plans are institutional memory.

---

## Model Routing

Each agent specifies a preferred model tier. This optimises cost and latency without sacrificing quality where it matters.

| Tier | When to use | Agents |
|------|-------------|--------|
| `opus` | Deep reasoning, architecture, compliance, security, settlement review | Orchestrator, Architect, Compliance |
| `sonnet` | Everyday coding, docs, design, test writing | iOS, Backend, PM, Design, QA |
| `haiku` | Quick lookups, search, formatting, status checks | (ad-hoc subagents only) |

Each agent's CLAUDE.md declares its tier. When the Orchestrator spawns a subagent, it should request the declared model tier. If unavailable, fall back one tier up (haiku → sonnet → opus), never down.

---

## Tool Scoping

Each agent declares the tools it is permitted to use. This enforces least-privilege:

| Role | Permitted tools | Rationale |
|------|----------------|-----------|
| Orchestrator | Read, Glob, Grep, Agent | Coordinates — never writes code or docs directly |
| PM | Read, Write, Edit, Glob, Grep | Writes PRDs and game rules, no shell access |
| Architect | Read, Write, Edit, Glob, Grep | Writes ADRs and reviews, no shell access |
| Design | Read, Write, Edit, Glob | Writes design docs, no shell or search |
| iOS | Read, Write, Edit, Bash, Glob, Grep | Full dev access — builds and tests |
| Backend | Read, Write, Edit, Bash, Glob, Grep | Full dev access — migrations, functions, tests |
| QA | Read, Write, Edit, Bash, Glob, Grep | Writes tests, runs test suites, files bug reports |
| Compliance | Read, Write, Edit, Glob, Grep | Writes compliance docs, no shell access |

If an agent needs a tool outside its scope for a specific task, it must request it from the Orchestrator, who grants it for that task only and documents the exception in the execution plan.

---

## Ticket Complexity Scoring

Every ticket must carry a complexity score (1–5). This prevents oversized tasks from stalling agents.

| Score | Agent action |
|-------|-------------|
| 1–3 | Execute directly |
| 4 | Split into subtasks before assigning — no agent should receive a score-4 ticket |
| 5 | Requires human design input or Architect review before execution |

The PM agent scores tickets at creation. The Orchestrator validates scores during its pre-flight check before spawning execution agents. See `agents/pm/CLAUDE-pm.md` for the full scoring rubric.

---

## Fresh Context Per Story

When the Orchestrator spawns a subagent for a task, each task gets a **fresh context window**. This prevents:
- Goal drift from accumulated context
- Hallucinated state from earlier tasks bleeding into later ones
- Context window exhaustion on long sessions

**The pattern:**
1. Each Linear task / user story is executed in an isolated agent invocation
2. The agent receives only: its CLAUDE.md, the specific task brief, relevant file paths, and PRD/ADR references
3. Continuity between tasks comes from the repository (git history, docs, plan files) — not from shared context
4. The Orchestrator tracks progress externally (Linear, execution plans) and passes only the relevant slice to each new agent

**When to break this rule:** Only when two tasks share tight coupling (e.g., a schema migration and the Edge Function that depends on it). In that case, group them as subtasks in a single agent invocation and document why.

---

## Human Gate Protocol

The human owner's time is the scarcest resource. Protect it.

**Escalate (create [GATE REQUIRED] Notion page) for:**
- Items marked GATE in the decision log
- Any cost decision > £50/month
- Legal or compliance questions
- Changes to core game rules
- Security concerns

**Never escalate for:**
- Implementation details (within agent's domain)
- Which test approach to use (see ADRs)
- Whether to write tests (always yes)
- Whether to fix a found bug (always yes)

**Gate response format the human uses:**
`APPROVED` | `APPROVED WITH CHANGES: [x]` | `REJECTED: [x]`
