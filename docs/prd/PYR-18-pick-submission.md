# PRD: Pick Submission

**Linear:** PYR-18
**Phase:** 1
**Status:** TODO
**Agents:** iOS Agent + Backend Agent
**Branch:** `feature/PYR-18-pick-submission`

---

## Goal

A surviving league member can pick one team per gameweek, change their pick before kick-off, and have their pick lock at the match deadline.

---

## User Story

> As a surviving league member, I want to pick a team each gameweek, knowing I can change my mind before kick-off, but that my pick locks when the match starts.

---

## Acceptance Criteria

### iOS
- [ ] Pick screen accessible from league detail view for current gameweek
- [ ] Fixture list: all matches for current gameweek, sorted by kick-off time
- [ ] Each fixture shows: home team, away team, kick-off time (local timezone), match status (NS/1H/HT/2H/FT)
- [ ] Teams already picked this season in this league are greyed out and unselectable (used_teams view)
- [ ] Player's current pick highlighted with selected state
- [ ] Countdown timer: "Locks in Xh Xm" until earliest unlocked match kick-off
- [ ] After match kick-off: picked match shown as locked (lock icon), cannot change
- [ ] If all matches kicked off and no pick made: show "eliminated — no pick submitted" state
- [ ] Confirmation: tapping a team shows confirmation sheet before submitting

### Backend (`submit-pick` Edge Function)
- [ ] Authenticated requests only
- [ ] Validate: player is active member of league, not already eliminated
- [ ] Validate: gameweek is current and not all matches finished
- [ ] Validate: chosen team's match has not yet kicked off (`kickoff_at > now()`)
- [ ] Validate: team not already used by this player in this league this season (query used_teams view)
- [ ] Upsert into `picks` (one per player per league per gameweek — unique constraint)
- [ ] Idempotent: submitting same pick twice = update with same value, return success
- [ ] Lock enforcement: if pick exists and is_locked=true, reject update
- [ ] Return: `{ pick_id, team_name, fixture_id, is_locked }`
- [ ] Error codes: `ALREADY_ELIMINATED` | `MATCH_STARTED` | `TEAM_USED` | `GAMEWEEK_CLOSED` | `PICK_LOCKED`

### Auto-elimination
- [ ] poll-live-scores / cron: after all matches in a gameweek have started, eliminate any active league member with no pick for that gameweek
- [ ] Write elimination to league_members.status='eliminated', eliminated_at, eliminated_in_gameweek_id
- [ ] Log to settlement_log

### Tests
- [ ] ViewModel: select team, change team, confirm, deadline passed state, used team greyed out
- [ ] Edge Function: happy path, team already used, match started, already eliminated, idempotency
- [ ] Auto-elimination: no pick submitted → eliminated after deadline
- [ ] 80%+ coverage

---

## Design

Figma designs required.
Key components: FixtureRow, TeamButton (selected/disabled states), CountdownTimer, DSButton (confirm)

---

## Game Rules References

- §3.1 One pick per gameweek
- §3.2 Pick deadline = match kick-off
- §3.3 No valid pick = eliminated
- §3.4 Pick change window
- §3.5 Pick visibility (hidden until deadline)

---

## Data Model

Uses existing schema. No migrations required.
`used_teams` view already excludes voided picks.

---

## Dependencies

- PYR-16 + PYR-17: league and member must exist
- sync-fixtures Edge Function must have seeded fixtures for the current gameweek
