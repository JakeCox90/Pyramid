# PRD: settle-picks Edge Function

**Linear:** PYR-20
**Phase:** 1
**Status:** TODO
**Agent:** Backend Agent
**Branch:** `feature/PYR-20-settle-picks`

---

## ⚠️ HUMAN REVIEW REQUIRED BEFORE PROD DEPLOY

Settlement logic handles real player outcomes. Per golden-principles.md:
> Never ship settlement changes without human review.

Create a [GATE REQUIRED] Notion page and Linear task before deploying to production.

---

## Goal

When a fixture reaches FT status (polled by poll-live-scores), settle all picks for that fixture across all leagues. Apply game rules precisely. Guarantee idempotency.

---

## Acceptance Criteria

### Edge Function: `settle-picks`

**Trigger**
- [ ] Called by poll-live-scores when a fixture's status transitions to `FT`
- [ ] Input: `{ fixture_id: bigint }`

**Settlement Logic**
- [ ] Look up all `picks` for this fixture_id with result='pending'
- [ ] For each pick:
  - Home team won + player picked home team → `survived`
  - Away team won + player picked away team → `survived`
  - Draw → `eliminated`
  - Loss → `eliminated`
  - Fixture status PST or ABD → `void` (pick not counted, team not marked as used)
- [ ] Update `picks.result`, `picks.settled_at`
- [ ] Update `league_members.status`:
  - If eliminated: set `status='eliminated'`, `eliminated_at=now()`, `eliminated_in_gameweek_id`
  - If survived: leave as `active`

**Mass Elimination**
- [ ] After settling all picks in a gameweek for a league: if all remaining active members are now eliminated in this gameweek
- [ ] Reinstate all: set `status='active'`, clear `eliminated_at`, clear `eliminated_in_gameweek_id` for all members eliminated in this GW
- [ ] Log mass_elimination=true in settlement_log

**Idempotency**
- [ ] Before processing: check `settlement_log` for existing entry with same `idempotency_key = 'fixture-{fixture_id}-league-{league_id}'`
- [ ] If found: return early, log "already settled", exit with success
- [ ] After processing: insert into `settlement_log` with idempotency_key

**Audit Log**
- [ ] Every run inserts into `settlement_log`: fixture_id, gameweek_id, league_id, picks_processed, eliminations, survivors, voids, is_mass_elimination, settled_at, idempotency_key, notes

**Error Handling**
- [ ] If fixture result data is ambiguous (e.g., missing scores): hold settlement, log to settlement_log with notes="HELD: ambiguous result", alert Orchestrator
- [ ] Never partially settle a league — use a transaction

### Tests (mandatory)
- [ ] Happy path: home win → home pick survives, away pick eliminated
- [ ] Draw: both picks eliminated
- [ ] Loss: loser's pick eliminated
- [ ] Void (PST): pick voided, team not marked as used, player survives
- [ ] Mass elimination: all players eliminated same GW → all reinstated
- [ ] Idempotency: run twice for same fixture → second run is no-op, no duplicate changes
- [ ] Ambiguous result: settlement held, not applied
- [ ] Transaction rollback: if any update fails, no partial state written
- [ ] 80%+ coverage

---

## Game Rules References

- §4.1 Win condition (survived)
- §4.2 Elimination conditions (draw, loss, no pick)
- §4.3 FT only triggers settlement
- §4.4 Settlement timing
- §4.5 Mass elimination → reinstatement
- §7.1–7.2 Postponed/abandoned → void

---

## Data Model

Uses existing schema. No migrations required.
`used_teams` view automatically excludes voided picks (result != 'void').

---

## Dependencies

- PYR-18: picks must exist in the picks table
- poll-live-scores must invoke settle-picks when transitioning to FT
