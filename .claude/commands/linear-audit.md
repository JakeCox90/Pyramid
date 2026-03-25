# Linear Audit — Project Hygiene Review

Run a comprehensive audit of all Linear projects, tickets, milestones, status updates, and project icons to ensure everything is accurate and up to date.

## Instructions

You are the Orchestrator performing a Linear hygiene audit. Work through every step below systematically. Do NOT ask the user for confirmation at any point — fix issues as you find them.

---

## Phase 1: Review Recent Work

1. Run `git log --oneline -30` to see recent commits on `main`
2. Run `gh pr list --state merged --limit 20 --json number,title,mergedAt,headRefName` to see recently merged PRs
3. Read `docs/agent-coordination.md` to see what's recorded as completed
4. Cross-reference: every merged PR should have a corresponding Linear ticket. Note any PRs without tickets (branches like `fix/...` or `feature/...` without `PYR-` prefix)

**Output:** List of recently merged PRs and their ticket mapping. Flag any orphan PRs (no ticket) or orphan tickets (marked done but no PR).

---

## Phase 2: Ticket Status Accuracy

For each active project, list all issues and verify statuses are correct:

### Status Rules
- **Done**: PR merged to main. Verify with `gh pr list --state merged` cross-reference
- **In Review**: PR exists and is open. Verify with `gh pr list --state open`
- **In Progress**: Agent is actively working (check `docs/agent-coordination.md`). If no agent is working, this is wrong — should be Todo or Backlog
- **Todo**: Ready to work, not started
- **Backlog**: Not yet prioritised for current work

### Check each project:
```
mcp__linear__list_issues(project="<project name>", team="Pyramid", limit=100)
```

For each issue:
- If status is "Done" but no merged PR exists → flag as discrepancy
- If status is "In Review" but no open PR exists → likely should be "Done" (PR merged) or "Todo" (PR was closed)
- If status is "In Progress" but no entry in agent-coordination.md → move to "Todo"
- If a PR was merged but ticket is still "In Review" or "In Progress" → move to "Done"

**Fix issues inline** using `mcp__linear__save_issue(id="PYR-XXX", state="Done")`.

---

## Phase 3: Project Status Updates

Each active project (not "Completed" status) needs a current status update. Check when the last update was posted:

```
mcp__linear__get_status_updates(type="project", project="<name>", limit=1)
```

### Status Update Rules
- If the last update is older than 2 days, post a new one
- Format for status updates:

```markdown
## Status Update — YYYY-MM-DD

**Progress: X/Y tickets done (Z%)**

### Completed since last update
- PYR-XXX: description (PR #NN)

### In Progress
- PYR-XXX: description — current state

### Remaining
- Count of Todo + Backlog tickets

### Blockers
- Any blocked tickets or GATE items
```

- Health: `onTrack` if progress is advancing, `atRisk` if blocked, `offTrack` if regressing
- Post using: `mcp__linear__save_status_update(type="project", project="<name>", body="...", health="...")`

### Projects to check:
1. Phase 3: Core Game Experience
2. Homepage Experience
3. Community & Social
4. Planning
5. Compliance & Gates

Skip completed projects (Foundation, Pick & Settlement, League Management, Push Notifications, Paid Leagues, Wallet & Payments, Authentication, Design System).

---

## Phase 4: Milestone Accuracy

For each active project, verify milestones are accurate:

```
mcp__linear__list_milestones(project="<project name>")
```

### Milestone Rules
- Milestone progress should reflect the ratio of Done issues to total issues assigned to it
- Every issue in an active project should belong to a milestone (flag orphans)
- If all issues in a milestone are Done, progress should be 100%
- If a milestone shows wrong progress, the issue-to-milestone assignments may be wrong

### Check each milestone:
1. List issues in the project
2. Group by milestone
3. Compare done/total ratio to reported progress
4. Flag any issues not assigned to a milestone
5. Flag any milestones where progress doesn't match reality

**Fix:** If an issue should be in a milestone but isn't, assign it:
```
mcp__linear__save_issue(id="PYR-XXX", milestone="<milestone name>")
```

---

## Phase 5: Project Icons & Colours

Update every project's icon and colour based on completion progress.

### Icon Rules (from MEMORY.md)
| Progress | Icon | Colour |
|----------|------|--------|
| 0% (not started) | default | default |
| >0% and <50% done | `IssueStatusStarted` | `#f2c94c` (yellow) |
| >=50% and <100% done | `IssueStatusReview` | `#f2c94c` (yellow) |
| 100% done | `IssueStatusDone` | `#4cb782` (green) |

### For each project:
1. Count total issues (exclude Canceled)
2. Count Done issues
3. Calculate percentage
4. Determine correct icon and colour
5. Compare to current icon/colour
6. Update if wrong:
```
mcp__linear__save_project(id="<project-id>", icon="<icon>", color="<hex>")
```

Also update project `state`:
- 100% complete → state: "Completed"
- >0% → state: "In Progress" (if not already)

---

## Phase 6: Summary Report

Output a markdown summary to the user:

```markdown
## Linear Audit Report — YYYY-MM-DD

### Ticket Status Changes
| Ticket | Old Status | New Status | Reason |
|--------|-----------|-----------|--------|

### Orphan PRs (no Linear ticket)
- PR #XX: title

### Status Updates Published
- Project Name: health status

### Milestone Corrections
| Ticket | Change | Reason |
|--------|--------|--------|

### Project Icon Updates
| Project | Old Icon/Colour | New Icon/Colour | Progress |
|---------|----------------|----------------|----------|

### Issues Found (not auto-fixed)
- Any items requiring human attention
```

---

## Important Notes

- **Never overwrite user-created ticket titles or descriptions** — only update status, milestone, and project fields
- **Tickets are not Done until PR is merged** — In Review if PR is open
- **GATE tickets (PYR-26, PYR-34) stay in Backlog** — these are human decisions, do not move them
- **Canceled tickets are excluded** from progress calculations
- **Archived tickets are excluded** from all counts
- Use the `mcp__linear__*` tools for all Linear operations
- Cross-reference git/GitHub for ground truth on what's actually been completed
