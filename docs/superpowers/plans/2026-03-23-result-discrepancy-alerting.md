# Result Discrepancy Alerting — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `TODO: send alert to Orchestrator` in `poll-live-scores` (line 150) with a structured discrepancy logging system. When API-Football returns different FT scores across consecutive polls, the system must: (1) persist the discrepancy to a DB table for audit, (2) alert via Slack (already done), and (3) provide a way to manually resolve and trigger settlement.

**Architecture:** New `score_discrepancies` table stores each event. The existing `poll-live-scores` code already holds settlement (does not set `settled_at`), logs, and alerts Slack. We add a DB insert to create an auditable record. A new `resolve-discrepancy` Edge Function allows manual resolution — an operator marks the correct score and triggers settlement. No iOS changes needed — this is an ops/backend feature.

**Tech Stack:** PostgreSQL (Supabase), Deno/TypeScript Edge Functions

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `supabase/migrations/20260323000000_score_discrepancies.sql` | Create | DB table + RLS + index |
| `supabase/functions/poll-live-scores/index.ts` | Modify | Insert discrepancy record on detection |
| `supabase/functions/resolve-discrepancy/index.ts` | Create | Manual resolution + trigger settlement |
| `supabase/config.toml` | Modify | Add `[functions.resolve-discrepancy]` |

---

## Task Breakdown

### Task 1: Database Migration — `score_discrepancies` Table

**Files:**
- Create: `supabase/migrations/20260323000000_score_discrepancies.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Migration: 20260323000000_score_discrepancies
-- Description: Tracks score discrepancies detected by poll-live-scores
-- ROLLBACK: drop table public.score_discrepancies;

create table public.score_discrepancies (
  id           uuid primary key default gen_random_uuid(),
  fixture_id   bigint not null references public.fixtures(id),
  gameweek_id  integer not null references public.gameweeks(id),
  db_home_score    integer,
  db_away_score    integer,
  api_home_score   integer,
  api_away_score   integer,
  status       text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  resolved_at  timestamptz,
  resolved_by  text,            -- operator identifier
  resolution_note text,
  detected_at  timestamptz not null default now(),

  unique (fixture_id, detected_at)
);

comment on table public.score_discrepancies is 'Score discrepancies detected between consecutive FT polls. Settlement is held until resolved.';

create index score_discrepancies_status_idx on public.score_discrepancies (status) where status = 'open';
create index score_discrepancies_fixture_idx on public.score_discrepancies (fixture_id);

alter table public.score_discrepancies enable row level security;

-- Only service role can read/write — this is an ops table
create policy "No client access"
  on public.score_discrepancies for select
  using (false);
```

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/20260323000000_score_discrepancies.sql
git commit -m "feat(PYR-41): add score_discrepancies table migration"
```

---

### Task 2: Insert Discrepancy Record in poll-live-scores

**Files:**
- Modify: `supabase/functions/poll-live-scores/index.ts`

- [ ] **Step 1: Add discrepancy insert after the Slack alert**

In `poll-live-scores/index.ts`, replace the TODO comment on line 150 with a DB insert.

Find this block (lines 130–151):

```typescript
          log.warn("Score discrepancy — holding settlement", {
            fixtureId: dbFix.id,
            dbScore: `${dbFix.home_score}-${dbFix.away_score}`,
            apiScore: `${newHomeScore}-${newAwayScore}`,
          });
          await alertSlack("Score discrepancy detected", {
            fixtureId: dbFix.id,
            dbScore: `${dbFix.home_score}-${dbFix.away_score}`,
            apiScore: `${newHomeScore}-${newAwayScore}`,
          });
          // Update score but flag for review — do not trigger settlement
          await db.from("fixtures").update({
            home_score: newHomeScore,
            away_score: newAwayScore,
            status: newStatus,
            raw_api_response: apiFix,
            // settled_at deliberately not set — settlement will not fire
          }).eq("id", dbFix.id);

          results.heldForReview++;
          // TODO: send alert to Orchestrator (Slack / notification)
          continue;
```

Replace the `// TODO: send alert to Orchestrator (Slack / notification)` line with:

```typescript
          // Persist discrepancy for audit trail and manual resolution
          const { error: discErr } = await db.from("score_discrepancies").insert({
            fixture_id: dbFix.id,
            gameweek_id: dbFix.gameweek_id,
            db_home_score: dbFix.home_score,
            db_away_score: dbFix.away_score,
            api_home_score: newHomeScore,
            api_away_score: newAwayScore,
          });
          if (discErr && discErr.code !== "23505") {
            log.error("Failed to insert score discrepancy (non-fatal)", discErr, { fixtureId: dbFix.id });
          }
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/poll-live-scores/index.ts
git commit -m "feat(PYR-41): persist score discrepancies to DB for audit"
```

---

### Task 3: resolve-discrepancy Edge Function

**Files:**
- Create: `supabase/functions/resolve-discrepancy/index.ts`
- Modify: `supabase/config.toml`

- [ ] **Step 1: Write the Edge Function**

```typescript
// Edge Function: resolve-discrepancy
// Manually resolves a score discrepancy and triggers settlement.
// Called by operators after verifying the correct score.
//
// POST /resolve-discrepancy
// Headers: Authorization: Bearer <service_role_key>
// Body: { discrepancyId: string, action: "resolve" | "dismiss", note?: string }
//
// "resolve" — accept the current fixture scores as correct, trigger settlement
// "dismiss" — mark as false positive, do NOT trigger settlement (operator will fix manually)

import { getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

interface RequestBody {
  discrepancyId: string;
  action: "resolve" | "dismiss";
  note?: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("resolve-discrepancy", req);

  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized — service role required" }, 401);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { discrepancyId, action, note } = body;
  if (!discrepancyId || !action || !["resolve", "dismiss"].includes(action)) {
    return json({ error: "discrepancyId and action (resolve|dismiss) are required" }, 400);
  }

  const db = getServiceClient();

  // 1. Fetch the discrepancy
  const { data: disc, error: fetchErr } = await db
    .from("score_discrepancies")
    .select("id, fixture_id, gameweek_id, status")
    .eq("id", discrepancyId)
    .maybeSingle();

  if (fetchErr || !disc) {
    return json({ error: "Discrepancy not found" }, 404);
  }

  if (disc.status !== "open") {
    return json({ error: `Discrepancy already ${disc.status}` }, 409);
  }

  // 2. Mark as resolved/dismissed
  const newStatus = action === "resolve" ? "resolved" : "dismissed";
  const { error: updateErr } = await db
    .from("score_discrepancies")
    .update({
      status: newStatus,
      resolved_at: new Date().toISOString(),
      resolved_by: "operator",
      resolution_note: note ?? null,
    })
    .eq("id", discrepancyId);

  if (updateErr) {
    log.error("Failed to update discrepancy", updateErr, { discrepancyId });
    return json({ error: "Failed to update discrepancy" }, 500);
  }

  log.info(`Discrepancy ${newStatus}`, { discrepancyId, fixtureId: disc.fixture_id, action });

  // 3. If resolving, trigger settlement for the fixture
  if (action === "resolve") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (supabaseUrl) {
      try {
        const res = await fetch(`${supabaseUrl}/functions/v1/settle-picks`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${serviceKey}`,
          },
          body: JSON.stringify({
            fixtureId: disc.fixture_id,
            gameweekId: disc.gameweek_id,
          }),
        });

        const settlementResult = await res.json();
        log.info("Settlement triggered after discrepancy resolution", {
          discrepancyId,
          fixtureId: disc.fixture_id,
          settlementResult,
        });

        return json({
          discrepancyId,
          status: newStatus,
          settlementTriggered: true,
          settlementResult,
        }, 200);
      } catch (err) {
        log.error("Settlement trigger failed after resolution", err, {
          discrepancyId,
          fixtureId: disc.fixture_id,
        });
        return json({
          discrepancyId,
          status: newStatus,
          settlementTriggered: false,
          error: "Settlement trigger failed — retry manually",
        }, 200);
      }
    }
  }

  return json({ discrepancyId, status: newStatus, settlementTriggered: false }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Add config.toml entry**

```toml
[functions.resolve-discrepancy]
verify_jwt = false
```

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/resolve-discrepancy/index.ts supabase/config.toml
git commit -m "feat(PYR-41): add resolve-discrepancy Edge Function"
```

---

### Task 4: Update Coordination Ledger and Phase 3 Plan

**Files:**
- Modify: `docs/agent-coordination.md`
- Modify: `docs/plans/active/phase-3-core-game-experience.md`

- [ ] **Step 1: Update coordination ledger — mark discrepancy alerting in progress**
- [ ] **Step 2: Update Phase 3 plan — mark item 41 (Result discrepancy alert system) as DONE**
- [ ] **Step 3: Commit**

```bash
git add docs/agent-coordination.md docs/plans/active/phase-3-core-game-experience.md
git commit -m "chore: update coordination ledger and Phase 3 plan for discrepancy alerting"
```

---

### Task 5: Push Branch

- [ ] **Step 1: Push**

```bash
git push -u origin claude/next-best-action-ErNi3
```

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Ops-only table (no client RLS access) | Discrepancies are internal ops data — players should never see them |
| `resolve` vs `dismiss` actions | Resolve = scores are correct, trigger settlement. Dismiss = false positive, operator handles manually |
| Unique on `(fixture_id, detected_at)` | Prevents duplicate discrepancy records from concurrent polls |
| Settlement triggered on resolve | Operator verifies correct score, then the function triggers settle-picks automatically |
| No iOS changes | This is backend ops tooling — no user-facing UI needed |

## Out of Scope

- Admin dashboard UI for viewing/resolving discrepancies
- Automated resolution (e.g., polling API-Football again after 10 minutes)
- Email/SMS alerts to operators (Slack is sufficient for now)
