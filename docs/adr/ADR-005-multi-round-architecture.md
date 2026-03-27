# ADR-005: Multi-Round League Architecture

**Status:** PROPOSED — requires human GATE approval (changes settlement logic and financial flows)
**Date:** 2026-03-27
**Deciders:** Architect Agent, Orchestrator
**Approver:** Human owner (GATE)
**Linear:** PYR-208

---

## Context

The game rules specification (rules.md) defines a round as "one full competition within a league, running from its start gameweek until a winner (or joint winners) is declared" (see Glossary, section 12). Section 2.4 states explicitly: "Multiple rounds can take place within a single PL season. When a round ends, a new round opens — players must explicitly opt in and re-stake (for paid leagues) to participate in the next round." Section 3.1 further requires that no-repeat pick restrictions are "scoped per round, not per season — a player's used-team list resets at the start of each new round they join."

The current schema has no concept of rounds. The system treats each league as a single, implicit competition:

- `leagues` stores `round_started_at`, `round_ended_at`, `prize_pot_pence`, and `platform_fee_pence` as direct columns — embedding a single round's lifecycle into the league itself.
- `league_members` tracks `status` as `'active' | 'eliminated' | 'winner'` with no round dimension. There is no way to record that a player was eliminated in round 1 but is active in round 2.
- `picks` has a unique constraint on `(league_id, user_id, gameweek_id)` — scoped to the league, not a round. The `used_teams` view inherits this scope, meaning pick history cannot be reset between rounds.
- `settlement_log` records settlement events against a league but has no round identifier.

This means that when a round ends and a new one should begin, there is no mechanism to: (a) create a new competition context within the same league, (b) reset the used-teams list for participating players, (c) track separate prize pots and member statuses per round, or (d) allow players in paid leagues to re-stake for a new round.

This ADR proposes the architecture for first-class multi-round support.

---

## Options Considered

### Option A: First-Class `rounds` Table (Recommended)

Introduce a dedicated `rounds` table that sits between `leagues` and the per-round data (`picks`, member status, prize pot). Each round is an independent competition context with its own lifecycle, members, and financial state.

**Strengths:**
- Clean relational model: league is the container, round is the competition. Each concept has its own table with clear responsibilities.
- Precise scoping: picks, used-teams, eliminations, and prizes are all naturally scoped to a round via foreign key.
- Used-teams reset is automatic — filtering `picks` by `round_id` gives only that round's history.
- Prize pot, platform fee, and member status live on the round (or round_members), not the league. Multiple completed rounds coexist cleanly.
- Backwards-compatible: existing single-round leagues get a "round 1" row in the migration. All existing queries continue to work with the addition of a round filter.
- Future-proof: supports manual-start rounds, configurable round rules, and round-level analytics without further schema changes.

**Weaknesses:**
- Larger migration: requires a new table, a new junction table (`round_members`), column additions to `picks`, backfill of existing data, and updates to every Edge Function.
- Additional join in queries: many queries that previously went straight from `league_id` to `picks` now route through `round_id`. Mitigated by denormalising `league_id` on `round_members`.
- Temporary dual-state: during migration, both old league-level columns and new round-level columns coexist until the old columns are deprecated and dropped.

---

### Option B: New League Per Round (Clone League When Round Ends)

When a round ends, create an entirely new league row that represents round N+1. The original league becomes a historical record. Players are copied (or re-invited) into the new league.

**Strengths:**
- Zero schema changes to existing tables — a "round" is just another league.
- Each league row is self-contained with its own prize pot, members, and picks.
- Simple mental model: one league = one competition.

**Weaknesses:**
- Destroys the concept of a persistent league. Users lose continuity — their "league" changes identity every round. The join code, league name, and league ID all change, breaking deep links, bookmarks, and the social fabric of free leagues.
- League history is scattered across multiple rows with no formal parent-child relationship. Querying "all rounds in my league" requires a linked-list traversal or a `parent_league_id` column (which is just a weaker version of Option A's `rounds` table).
- Paid league re-staking becomes awkward: the user must "join" a new league rather than opt into a new round of their existing league. This is confusing UX and creates ambiguity in the "5 active paid leagues" limit (does a new round count as a new league?).
- Duplicated data: league settings (name, type, max_players, season) are copied into every round's league row.

---

### Option C: Round Counter on Existing Tables

Add a `round_number` integer column to `picks`, `league_members`, and `settlement_log`. The league table gets a `current_round` counter. Used-teams view filters by `round_number`.

**Strengths:**
- Minimal schema change — only new columns, no new tables.
- No new join tables; existing queries just add a `WHERE round_number = X` filter.

**Weaknesses:**
- `league_members` cannot hold per-round status cleanly. A single row per `(league_id, user_id)` must somehow represent "eliminated in round 1, active in round 2." This requires either: (a) resetting `status` back to `'active'` when a new round starts (destroying round 1 history), or (b) multiple rows per member per league (breaking the existing unique constraint and semantics).
- Prize pot, platform fee, and round lifecycle have no natural home. They remain on `leagues`, which can only hold one round's data at a time. Historical round financials are lost or must be logged elsewhere.
- Pseudonym re-randomisation per round is impossible with a single `league_members` row.
- No database-level enforcement of "one active round per league" — must be enforced purely in application code.
- Round lifecycle (pending, active, completed) has no column to live in. The league's `status` and `paid_status` are overloaded to represent both league-level and round-level state.

---

## Decision

**Option A: First-class `rounds` table** with a companion `round_members` table.

This is the only option that cleanly separates the league (container, identity, settings) from the round (competition, lifecycle, financial state) without destroying historical data or overloading existing columns.

---

### Schema Design

#### New enum: `round_status`

```sql
create type round_status as enum ('pending', 'active', 'completed', 'cancelled');
```

- `pending`: Round created, waiting for minimum player count (paid leagues) or auto-transitioning (free leagues).
- `active`: Competition in progress. Picks are being submitted and settled.
- `completed`: Winner declared, prizes distributed.
- `cancelled`: Round did not start (e.g. insufficient players after opt-in window, or league disbanded).

#### New table: `rounds`

```sql
create table public.rounds (
  id                  uuid primary key default gen_random_uuid(),
  league_id           uuid not null references public.leagues(id) on delete cascade,
  round_number        integer not null default 1,
  status              round_status not null default 'pending',
  start_gameweek_id   integer references public.gameweeks(id),
  end_gameweek_id     integer references public.gameweeks(id),
  started_at          timestamptz,
  ended_at            timestamptz,
  prize_pot_pence     integer default 0,
  platform_fee_pence  integer default 0,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  unique(league_id, round_number)
);
```

**Partial unique index — one non-terminal round per league:**

```sql
create unique index rounds_one_active_per_league
  on public.rounds (league_id)
  where status in ('pending', 'active');
```

This enforces at the database level that a league can never have two concurrent rounds. Only rounds in terminal states (`completed`, `cancelled`) are excluded from the uniqueness check.

#### New table: `round_members`

```sql
create table public.round_members (
  id                        uuid primary key default gen_random_uuid(),
  round_id                  uuid not null references public.rounds(id) on delete cascade,
  league_id                 uuid not null references public.leagues(id) on delete cascade,
  user_id                   uuid not null references public.profiles(id) on delete cascade,
  status                    member_status not null default 'active',
  joined_at                 timestamptz not null default now(),
  eliminated_at             timestamptz,
  eliminated_in_gameweek_id integer references public.gameweeks(id),
  finishing_position        integer,
  prize_pence               integer,
  pseudonym                 text,

  unique(round_id, user_id)
);
```

#### `settlement_log` modification

```sql
alter table public.settlement_log add column round_id uuid references public.rounds(id);
```

All settlement events — pick settlement, prize distribution, refunds — are tagged with the round they belong to. This is critical for:
- Idempotency keys: `distribute-prizes:${leagueId}:${roundId}` (without `round_id`, a second round's distribution collides with the first).
- Audit trail: querying all settlement activity for a specific round.
- Consistency with `credit-winnings`, which already uses `round_id` in its idempotency key.

#### Picks modification

```sql
alter table public.picks add column round_id uuid references public.rounds(id);
```

The existing unique constraint `(league_id, user_id, gameweek_id)` is replaced with `(round_id, user_id, gameweek_id)`. This scopes the one-pick-per-gameweek rule to the round, not the league.

#### Updated `used_teams` view

```sql
create or replace view public.used_teams as
select
  p.league_id,
  p.round_id,
  p.user_id,
  p.team_id,
  p.team_name,
  p.gameweek_id,
  g.round_number as gameweek_number,
  p.result
from public.picks p
join public.gameweeks g on g.id = p.gameweek_id
where p.result != 'void';
```

The addition of `round_id` allows the `submit-pick` function to filter `.eq("round_id", currentRoundId)`, implementing the game rule that "a player's used-team list resets at the start of each new round" (rules section 2.4).

---

### Key Design Decisions

**1. `round_members` vs modifying `league_members`**

A new `round_members` table is introduced rather than adding round dimensions to `league_members`. The two tables serve distinct purposes:

- `league_members` answers: "Is this user a member of this league?" It is the membership roster. Its status simplifies to `'active'` (in the league) or `'left'` (departed).
- `round_members` answers: "What is this user's competition status in this specific round?" It tracks elimination, finishing position, prize allocation, and pseudonym — all per-round concerns.

A user eliminated in round 1 has a `round_members` row with `status = 'eliminated'` for that round, and a fresh `round_members` row with `status = 'active'` for round 2. The `league_members` row remains `'active'` throughout — they never left the league.

**Enum migration:** The current `member_status` enum is `('active', 'eliminated', 'winner')`. With this change:
- `round_members` continues to use the existing `member_status` enum unchanged — `'active'`, `'eliminated'`, and `'winner'` are all per-round concepts.
- `league_members` no longer needs `'eliminated'` or `'winner'`. A new `league_member_status` enum is created: `('active', 'left')`. The migration updates `league_members.status` column to use this new enum, mapping all existing `'eliminated'` and `'winner'` rows to `'active'` (they are still league members). The `eliminated_at`, `eliminated_in_gameweek_id`, `finishing_position`, `prize_pence`, and `pseudonym` columns are dropped from `league_members` after backfill to `round_members` — they are round-level concerns only.

**2. Partial unique index for round exclusivity**

The `rounds_one_active_per_league` index uses a `WHERE status IN ('pending', 'active')` filter. This is a PostgreSQL partial unique index — it enforces uniqueness only on rows matching the filter. Completed and cancelled rounds are excluded, so any number of historical rounds can coexist. But at most one round can be in a non-terminal state per league.

**3. `league_id` denormalised on `round_members`**

The most common query pattern is "show me all active members in league X's current round." Without denormalisation, this requires a join through `rounds`. The denormalised `league_id` column avoids this join at the cost of a single extra UUID per row.

**4. Pseudonym per round**

In paid leagues, pseudonyms are assigned per round on `round_members`. Each new round gets fresh pseudonyms, preventing cross-round identification and strengthening anti-collusion guarantees (rules section 2.3).

**5. Round auto-creation flow**

When `distribute-prizes` completes round N:

a. **Create round N+1**: Insert into `rounds` with `status = 'pending'`, `round_number = N + 1`, `start_gameweek_id` = next unfinished gameweek.

b. **Free leagues — auto opt-in**: All `league_members` where `status = 'active'` are automatically inserted into `round_members` for the new round. If member count >= 5, the round immediately transitions to `'active'`. No player action required.

c. **Paid leagues — re-stake required**: The round stays `'pending'`. No `round_members` rows are created. Each player must call the `opt-in-round` Edge Function, which verifies balance, deducts £5, inserts a `round_members` row, and assigns a new pseudonym. When the 5th player opts in, the round transitions to `'active'`.

d. **GW38 guard**: If no unfinished gameweeks remain in the season, do NOT create a new round. Set `leagues.status = 'completed'`. The league is done for the season.

e. **Idempotency**: If `distribute-prizes` runs twice, the second attempt detects round N+1 already exists via the `unique(league_id, round_number)` constraint. Error code 23505 is caught as a no-op.

**6. Winner detection and final-gameweek logic**

The current `settle-picks` function uses `isFinalGameweek(roundNumber)` where `roundNumber` is `gameweeks.round_number` (PL matchday 1-38), hardcoded to check `=== 38`. With rounds, this must change:

- **Within a round:** A round ends when exactly 1 active member remains (sole winner) or when all remaining members survive GW38 (joint winners per rules §5.3). The check becomes: `isFinalGameweek(gameweekRoundNumber) && round.end_gameweek_id === null` — i.e., only trigger the GW38 joint-winner path if the round has no explicit end gameweek.
- **`rounds.end_gameweek_id`** is nullable. For normal rounds it is `null` — the round ends organically when a winner emerges. It is set by `distribute-prizes` when the round completes (for historical record). A future "fixed-length round" feature could set it at creation time.
- **The GW38 guard** in `distribute-prizes` (decision 5d) prevents new round creation. But `settle-picks` must also handle GW38 joint winners correctly by checking the *gameweek's* `round_number = 38`, not the *round's* `round_number`.

**7. Mass elimination reinstatement is round-scoped**

When all remaining players lose in the same gameweek, `settle-picks` reinstates them (rules §4.5). The current query is:
```sql
UPDATE league_members SET status='active' WHERE eliminated_in_gameweek_id = ?
```

With rounds, this becomes:
```sql
UPDATE round_members SET status='active', eliminated_at=NULL, eliminated_in_gameweek_id=NULL
WHERE round_id = ? AND eliminated_in_gameweek_id = ?
```

The `round_id` filter is critical — without it, a mass elimination reinstatement could theoretically affect members from a different round if gameweek IDs overlap (they won't in practice, but defence in depth).

**8. `poll-live-scores` is round-agnostic (by design)**

`poll-live-scores` advances PL gameweeks globally — it has no league or round context. It calls `settle-picks` per fixture, which handles round logic. The ADR does not require changes to `poll-live-scores` itself. Gameweek advancement (`is_current`, `is_finished`) remains season-global. The `is_current` flag on `gameweeks` is not per-round — all leagues share the same PL calendar.

**9. `user_stats` and achievements must read from `round_members`**

Two Postgres functions need updating:

- **`refresh_user_stats()`**: Currently counts `league_members` with `status='winner'`. Must change to count `round_members` with `status='winner'`. This gives correct per-round win counting (a user who wins round 1 and round 2 of the same league gets 2 wins, not 1).
- **`check_and_insert_achievements()`**: The `full_house` badge checks if a user picked every gameweek in a league. With rounds, it must scope to the round's gameweek range: picks where `round_id = current_round_id`. The `survival_streak` badges are already per-league and work correctly — streaks span gameweeks within a round, resetting between rounds because `round_members` status resets.

**10. `generate-gameweek-story` idempotency key includes round**

Current key: `${leagueId}_${gameweekId}`. Updated to `${leagueId}_${roundId}_${gameweekId}`. This prevents key collision if a league has a story for the same gameweek in two different rounds (e.g., round 1 ended at GW10 with a story, round 2 starts at GW11 — no collision in practice, but the key should be structurally correct). The story context builder must also scope pick/member queries to the current round.

**11. Free league minimum player check on auto opt-in**

When `distribute-prizes` auto-enrolls free league members into round N+1, the enrolled count may be below the minimum (5) if members left between rounds. Behaviour:
- If auto-enrolled count >= 5: round transitions to `'active'` immediately.
- If auto-enrolled count < 5: round stays `'pending'`. New members can join the league via join code and are inserted into both `league_members` and `round_members`. When the 5th `round_member` is added, the round transitions to `'active'`.
- If no gameweek deadline passes with < 5 members: round stays `'pending'` indefinitely (no auto-cancellation for free leagues — they have no financial obligation).

**12. Active paid league limit check uses `round_members`**

Rules §2.2: "Users may be active in up to 5 paid public matchmaking leagues at any one time." The current check queries `league_members` joined with `leagues.paid_status IN ('waiting', 'active')`. With rounds:
- The check must count distinct leagues where the user has a `round_members` row with `status = 'active'` in a round with `status IN ('pending', 'active')`.
- A user eliminated in round 1 but not yet opted into round 2 does NOT count against the limit — they have no active `round_members` row.
- A user who opted into round 2 (pending) DOES count — their stake is committed.

**13. Backwards-compatible migration**

The migration preserves all existing data:

a. Create `round_status` enum. Create `rounds` table. Insert one "round 1" row per league, copying `start_gameweek_id`, `prize_pot_pence`, `platform_fee_pence`, `round_started_at` → `started_at`, `round_ended_at` → `ended_at`. Map status from `leagues.status`: `pending` → `pending`, `active` → `active`, `completed` → `completed`, `cancelled` → `cancelled`.

b. Create `round_members` table. Copy all `league_members` rows, linking each to its league's round 1. Copy `status`, `eliminated_at`, `eliminated_in_gameweek_id`, `finishing_position`, `prize_pence`, `pseudonym` from `league_members`.

c. Add `round_id` to `picks`. Backfill from the auto-created round for each league.

d. Add `round_id` to `settlement_log`. Backfill from the auto-created round for each league.

e. Replace unique constraint on `picks` from `(league_id, user_id, gameweek_id)` to `(round_id, user_id, gameweek_id)`.

f. Update `used_teams` view to include `round_id`.

g. Create `league_member_status` enum `('active', 'left')`. Alter `league_members.status` to use the new enum (all existing `'eliminated'` and `'winner'` rows map to `'active'` — they are still league members). Drop `eliminated_at`, `eliminated_in_gameweek_id`, `finishing_position`, `prize_pence`, `pseudonym` columns from `league_members` (now on `round_members`).

h. Update `refresh_user_stats()` to read from `round_members`. Update `check_and_insert_achievements()` to scope `full_house` by `round_id`.

i. Keep old league-level round columns (`round_started_at`, `round_ended_at`, `prize_pot_pence`, `platform_fee_pence`) temporarily. Mark as deprecated. Drop in a future migration.

The entire backfill runs in a single transaction. Post-migration validation checks: every league has exactly one round, every league_member has a corresponding round_member, every pick has a non-null round_id, every settlement_log entry has a non-null round_id, and row counts match.

---

## Architecture Implications

### Edge Function Changes

| Function | Change Required |
|---|---|
| `create-league` | Also create round 1 in `rounds` table with `status = 'pending'`. |
| `join-league` | Insert into both `league_members` AND `round_members` for the current round. If round is `'pending'` and member count reaches 5, transition to `'active'`. |
| `join-paid-league` | Same — insert into both tables. Stake `reference_id` references the round. Active paid league limit check uses `round_members` (see decision 12). Prize pot and platform fee live on `rounds` row, not `leagues`. |
| `submit-pick` | Include `round_id`. Used-teams query adds `.eq("round_id", currentRoundId)`. Member status check reads from `round_members`. |
| `settle-picks` | Query `round_members` for status. Winner detection is per round. Mass elimination reinstatement scoped by `round_id` (decision 7). Final-gameweek joint-winner check uses `gameweeks.round_number = 38` (decision 6). All `settlement_log` inserts include `round_id`. |
| `distribute-prizes` | Update `rounds` row (not `leagues`). Idempotency key: `distribute-prizes:${leagueId}:${roundId}`. Trigger auto-creation of next round with type-specific opt-in. Update `round_members` finishing positions. |
| `credit-winnings` | Already uses `round_id` in idempotency key. Verify caller passes `round_id`. |
| `refund-stake` | Per-round refund. Reference the specific round. Idempotency key includes `round_id`. Sets `rounds.status = 'cancelled'`, not `leagues.status`. |
| **NEW: `opt-in-round`** | Paid league re-entry: verify balance, deduct £5 stake, insert round_member, assign pseudonym. Transition round to `'active'` at 5+ players. Check active paid league limit (decision 12). |
| `leave-league` | Update `league_members` to `'left'`. Remove from current `round_members` if round is `'pending'`; set to `'eliminated'` if round is `'active'`. |
| `generate-gameweek-story` | Idempotency key includes `round_id` (decision 10). Story context queries scoped to current round. |
| `poll-live-scores` | No changes required (decision 8). Gameweek advancement is season-global. |

#### Postgres Function Changes

| Function | Change Required |
|---|---|
| `refresh_user_stats()` | Count wins from `round_members` instead of `league_members`. Count picks and streaks scoped per round (decision 9). |
| `check_and_insert_achievements()` | `full_house` badge scoped to round's gameweek range. `survival_streak` resets between rounds naturally via `round_members`. |
| `user_league_ids()` | No change — returns league IDs from `league_members` (membership, not competition status). |

### iOS Client Changes

- Queries for competition data (picks, standings, used teams) must filter by `round_id`.
- New "current round" concept: query `rounds` where `status IN ('pending', 'active')`.
- Round transition UI: round-end summary, opt-in prompt for paid leagues, "new round starting" for free leagues.
- Historical round browsing within the same league.

### RLS Policy Updates

- `round_members`: League members can view round_members for their league.
- `rounds`: League members can view rounds for their league.
- `picks`: Existing policies updated to account for `round_id`.

---

## Execution Phases

| Phase | Description | Dependency |
|---|---|---|
| **A: ADR Approval** | This document. GATE — requires human review. | None |
| **B: Schema Migration** | Create tables (`rounds`, `round_members`), add columns (`picks.round_id`, `settlement_log.round_id`), backfill data, create `league_member_status` enum, update `league_members`, update views, update Postgres functions (`refresh_user_stats`, `check_and_insert_achievements`), add RLS. Validated with row-count assertions. | Phase A approved |
| **C: Edge Function Migration** | Update each function to round-aware logic. Each gets its own PR. Order: `create-league` → `join-league` / `join-paid-league` → `submit-pick` → `settle-picks` → `distribute-prizes` → `credit-winnings` → `refund-stake` → `leave-league` → `generate-gameweek-story`. | Phase B merged |
| **D: New Round Flow** | `opt-in-round` Edge Function. Auto-creation logic in `distribute-prizes`. Free league auto-enroll with minimum player check. End-to-end test of full round lifecycle (create → play → settle → distribute → auto-create → round 2). | Phase C merged |
| **E: iOS Round Transition UI** | Round-end summary, opt-in prompt for paid leagues, auto-start notification for free leagues, round history navigation, round-scoped standings. | Phase D merged |

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Data migration corrupts existing leagues | Low | Critical | Backfill in single transaction. Validate counts before/after. Keep old columns as fallback. Test against dev snapshot first. |
| Settlement race with round transition | Medium | High | Round N+1 creation is sequential after distribute-prizes commits. Partial unique index prevents double-creation. Idempotency key on settlement_log. |
| Paid re-stake UX friction | Medium | Medium | Clear in-app prompt. Generous opt-in window (until next GW deadline). Refund if minimum not met. |
| Query performance regression | Low | Medium | Denormalised `league_id` on `round_members`. Indexes on `round_id`. Validate query plans in dev. |
| Season boundary — infinite round creation | Low | High | GW38 guard: if no unfinished GWs, set league to completed, skip round creation. |
| Concurrent opt-in race (paid leagues) | Medium | Medium | Unique constraint `(round_id, user_id)` prevents double-enrolment. Stake + member insert in single transaction. |
| Edge Function deployment ordering | Low | Medium | Deploy in dependency order. Old columns preserved during transition. |
| `user_stats` / achievements regression | Medium | Medium | `refresh_user_stats()` and `check_and_insert_achievements()` must be updated in Phase B (schema migration), not Phase C. If deployed after Edge Functions start writing to `round_members`, stats will undercount. |
| Free league round stalls below minimum | Low | Low | Free round stays `'pending'` until 5 members join. No financial impact. New members joining the league auto-enter the pending round. |

---

## References

- [Game Rules — Section 2.4: Rounds and Seasons](../game-rules/rules.md)
- [Game Rules — Section 3.1: One Pick Per Gameweek](../game-rules/rules.md)
- [Game Rules — Section 5: Prize Distribution](../game-rules/rules.md)
- [ADR-001: Database and Backend Platform Choice](ADR-001-database-backend-platform.md)
- Migration: `20260307000000_initial_schema.sql` — current schema baseline
- Migration: `20260308100000_paid_league_columns.sql` — league-level round columns being superseded
- Migration: `20260322000000_used_teams_round_number.sql` — current used_teams view being replaced
