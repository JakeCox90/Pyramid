# Linear What Next — Prioritised Work Queue

Review what's been delivered recently, assess the current state of all active projects, and recommend the best next work items in priority order.

## Instructions

You are the Orchestrator building a prioritised work queue. Work through every phase below systematically. Do NOT ask the user for confirmation — produce the recommendation directly.

---

## Phase 1: Recent Delivery Summary

Understand what landed recently to avoid recommending duplicate or stale work.

1. Run `git log --oneline -20` to see recent commits on main
2. Run `gh pr list --state merged --limit 15 --json number,title,mergedAt,headRefName` to see recently merged PRs
3. Read `docs/agent-coordination.md` to check for any active agent work
4. Cross-reference merged PRs with Linear tickets to build a "recently delivered" list

**Output:** Compact summary of what shipped in the last 3 days — grouped by project.

---

## Phase 2: Current Project State

For each active project (not "Completed"), get the current ticket breakdown:

```
mcp__linear__list_issues(project="<name>", team="Pyramid", limit=100)
```

For each project, calculate:
- Total issues (excluding Canceled)
- Done count and percentage
- Issues in Todo (ready to work)
- Issues in Backlog (not yet ready)
- Issues in In Progress or In Review (active work)

Also check milestones:
```
mcp__linear__list_milestones(project="<name>")
```

**Output:** Progress table per project with milestone status.

---

## Phase 3: Identify Candidate Work Items

Collect all non-Done, non-Canceled issues across active projects. For each candidate:

1. **Status** — Todo items are ready; Backlog items may need refinement
2. **Priority** — Urgent > High > Medium > Low
3. **Dependencies** — check `blockedBy` or description for dependency mentions
4. **Project context** — which project/milestone does it advance?
5. **Effort** — check estimate points if available; check complexity score in description

Filter out:
- GATE tickets (PYR-26, PYR-34) — these require human decisions
- Tickets blocked by unfinished dependencies
- Archived tickets

---

## Phase 4: Scoring & Ranking

Score each candidate using this formula:

### Priority Score (0-40 points)
| Priority | Points |
|----------|--------|
| Urgent | 40 |
| High | 30 |
| Medium | 20 |
| Low | 10 |

### Strategic Impact (0-30 points)
| Factor | Points |
|--------|--------|
| Completes a milestone (last ticket) | +15 |
| Completes a project (last milestone) | +15 |
| Advances a near-complete project (>80%) | +10 |
| Advances a near-complete milestone (>80%) | +10 |
| Unblocks other tickets | +10 |
| Part of the current phase focus | +5 |

### Readiness (0-20 points)
| Factor | Points |
|--------|--------|
| Status is Todo (refined, ready) | +20 |
| Status is Backlog but has acceptance criteria | +10 |
| Status is Backlog, no acceptance criteria | +5 |
| Has files likely affected listed | +5 |

### Effort Efficiency (0-10 points)
| Estimate | Points |
|----------|--------|
| 1 point (quick win) | +10 |
| 2 points | +8 |
| 3 points | +5 |
| 5 points | +2 |
| No estimate | +3 |

---

## Phase 5: Recommendation

Output a prioritised work queue with the top 5-8 items:

```markdown
## What Next — YYYY-MM-DD

### Recently Delivered (last 3 days)
- [Project]: X tickets completed (list key ones)

### Current State
| Project | Progress | Next Milestone |
|---------|----------|---------------|
| ... | X/Y (Z%) | milestone name — N remaining |

### Recommended Work Queue

#### 1. PYR-XXX: Title (Score: NN)
- **Project:** name | **Milestone:** name
- **Priority:** High | **Estimate:** 2 pts | **Status:** Todo
- **Why now:** Completes milestone X / unblocks Y / quick win
- **Files:** list from ticket

#### 2. PYR-XXX: Title (Score: NN)
...

### Also Consider
- Items that scored lower but have strategic value
- Items that need refinement before they're workable

### Blocked (human action needed)
- GATE items with days pending
- Any tickets waiting on external input
```

---

## Phase 6: Update Agent Coordination

After presenting the recommendation, update `docs/agent-coordination.md` to reflect:
- Clear any stale "Active Work" entries
- Note the recommended queue in a comment so the next agent session can pick up

---

## Important Notes

- **Never modify ticket titles or descriptions** — this is read-only analysis
- **GATE tickets stay blocked** — flag them but don't recommend them as work items
- **Check git for ground truth** — a ticket marked Todo might already have code in a branch
- **Prefer completing near-done projects/milestones** — finishing > starting
- **Current phase focus** — check `docs/plans/active/` and CLAUDE.md for what the current phase priorities are
- **Respect the pre-flight checklist** from `agents/orchestrator/CLAUDE.md` — complexity <= 3, binary acceptance criteria, files listed, dependencies resolved
- Use `mcp__linear__*` tools for all Linear reads
- Cross-reference with `gh` CLI for PR/branch state
