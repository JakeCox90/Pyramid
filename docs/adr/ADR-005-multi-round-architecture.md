# ADR-005: Multi-Round League Architecture

**Status:** PROPOSED — requires human GATE approval (changes settlement logic and financial flows)
**Date:** 2026-03-27
**Deciders:** Architect Agent, Orchestrator
**Approver:** Human owner (GATE)
**Linear:** TBD

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

**6. Backwards-compatible migration**

The migration preserves all existing data:

a. Create `rounds` table. Insert one "round 1" row per league, copying `start_gameweek_id`, `prize_pot_pence`, `platform_fee_pence`, `round_started_at` → `started_at`, `round_ended_at` → `ended_at`. Map status from `leagues.status`.

b. Create `round_members` table. Copy all `league_members` rows, linking each to its league's round 1.

c. Add `round_id` to `picks`. Backfill from the auto-created round for each league.

d. Replace unique constraint on `picks` from `(league_id, user_id, gameweek_id)` to `(round_id, user_id, gameweek_id)`.

e. Update `used_teams` view to include `round_id`.

f. Keep old league columns temporarily. Mark as deprecated. Drop in a future migration.

The entire backfill runs in a single transaction. Post-migration validation checks: every league has exactly one round, every league_member has a corresponding round_member, every pick has a non-null round_id, and row counts match.

---

## Architecture Implications

### Edge Function Changes

| Function | Change Required |
|---|---|
| `create-league` | Also create round 1 in `rounds` table with `status = 'pending'`. |
| `join-league` | Insert into both `league_members` AND `round_members` for the current round. |
| `join-paid-league` | Same — insert into both tables. Stake `reference_id` references the round. |
| `submit-pick` | Include `round_id`. Used-teams query adds `.eq("round_id", currentRoundId)`. |
| `settle-picks` | Query `round_members` for status. Winner detection is per round. |
| `distribute-prizes` | Update `rounds` row. Trigger auto-creation of next round with type-specific opt-in. |
| `refund-stake` | Per-round refund. Reference the specific round. |
| **NEW: `opt-in-round`** | Paid league re-entry: verify balance, deduct £5 stake, insert round_member, assign pseudonym. Transition round to `active` at 5+ players. |
| `leave-league` | Update `league_members` to `'left'`. Remove from current `round_members` if pending; eliminate if active. |

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
| **B: Schema Migration** | Create tables, backfill data, update views, add RLS. Validated with row-count assertions. | Phase A approved |
| **C: Edge Function Migration** | Update each function to round-aware logic. Each gets its own PR. Order: `create-league` → `join-league` → `submit-pick` → `settle-picks` → `distribute-prizes`. | Phase B merged |
| **D: New Round Flow** | `opt-in-round` Edge Function. Auto-creation logic in `distribute-prizes`. End-to-end test of full round lifecycle. | Phase C merged |
| **E: iOS Round Transition UI** | Round-end summary, opt-in prompt, round history navigation. | Phase D merged |

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

---

## References

- [Game Rules — Section 2.4: Rounds and Seasons](../game-rules/rules.md)
- [Game Rules — Section 3.1: One Pick Per Gameweek](../game-rules/rules.md)
- [Game Rules — Section 5: Prize Distribution](../game-rules/rules.md)
- [ADR-001: Database and Backend Platform Choice](ADR-001-database-backend-platform.md)
- Migration: `20260307000000_initial_schema.sql` — current schema baseline
- Migration: `20260308100000_paid_league_columns.sql` — league-level round columns being superseded
- Migration: `20260322000000_used_teams_round_number.sql` — current used_teams view being replaced
