# PRD: League Joining (Join via Code)

**Linear:** PYR-17
**Phase:** 1
**Status:** TODO
**Agents:** iOS Agent + Backend Agent
**Branch:** `feature/PYR-17-league-joining`

---

## Goal

A logged-in user can join a free league by entering a 6-character alphanumeric join code.

---

## User Story

> As a registered user who has received a join code from a friend, I want to join their Last Man Standing league.

---

## Acceptance Criteria

### iOS
- [ ] "Join League" button visible on Leagues tab alongside "Create League"
- [ ] Join League screen: 6-char text input (auto-uppercase, monospace font), submit button
- [ ] After valid code entered: League Preview screen shows league name, creator, member count, start gameweek
- [ ] Confirm Join button on preview screen → joins league
- [ ] Joined league appears in My Leagues list
- [ ] Error states: invalid code (league not found), already a member, league already started, league full

### Backend (`join-league` Edge Function)
- [ ] Authenticated requests only (verify JWT)
- [ ] Validate join code format: 6 chars, alphanumeric
- [ ] Look up league by join_code, return `{ id, name, member_count, start_gameweek }` for preview
- [ ] On confirm: check league is still joinable (status='pending')
- [ ] Insert into `league_members`: league_id, user_id=auth.uid(), status='active'
- [ ] Prevent duplicate joins (unique constraint already in schema)
- [ ] Error responses: `{ error: string, code: 'NOT_FOUND' | 'ALREADY_MEMBER' | 'STARTED' | 'FULL' }`

### Tests
- [ ] ViewModel: valid code flow, invalid code, already member, league started
- [ ] Edge Function: happy path, invalid code, duplicate join attempt, unauthenticated
- [ ] 80%+ coverage

---

## Design

Figma designs required before iOS implementation starts.
Key components: DSTextField (code input), DSCard (league preview), DSButton

---

## Data Model

Uses existing schema. No migrations required.

---

## Dependencies

- PYR-16 (create-league) must be complete — a league must exist to join

---

## Out of Scope

- Paid league joining / entry fee payment (Phase 2)
- Public matchmaking queue (Phase 2)
