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

File: `docs/plans/active/LMS-{id}-{name}.md`

Required sections: Goal | Context | Steps (TODO/IN PROGRESS/DONE/BLOCKED) | Decision Log | Open Questions | Definition of Done

When complete: move to `docs/plans/completed/` — never delete. Completed plans are institutional memory.

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
