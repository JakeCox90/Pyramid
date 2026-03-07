# PRD: League Creation (Free Leagues)

**Linear:** PYR-16
**Phase:** 1
**Status:** TODO
**Agents:** iOS Agent + Backend Agent
**Branch:** `feature/PYR-16-league-creation`

---

## Goal

A logged-in user can create a free league, receive a unique 6-character join code, and share it with friends.

---

## User Story

> As a registered user, I want to create a Last Man Standing league so I can invite friends to compete with me.

---

## Acceptance Criteria

### iOS
- [ ] "Create League" button visible on the Leagues tab (empty state and in header)
- [ ] Create League form: league name input (3–40 chars), submit button
- [ ] Inline validation: empty name and name too short/long show error
- [ ] Loading state on submit button while Edge Function call is in flight
- [ ] Post-creation success screen: displays join code prominently, share sheet action, copy-to-clipboard button
- [ ] New league immediately appears in My Leagues list after creation
- [ ] Error state if Edge Function returns an error (shown inline, not alert)

### Backend (`create-league` Edge Function)
- [ ] Authenticated requests only (verify JWT)
- [ ] Validate league name: 3–40 chars, non-empty
- [ ] Generate unique 6-char alphanumeric join code (uppercase). Retry on collision (max 5 attempts).
- [ ] Insert into `leagues` table: name, join_code, type='free', status='pending', created_by=auth.uid(), season=current_season
- [ ] Insert creator into `league_members` as first member (status='active')
- [ ] Return: `{ league_id, join_code, name }`
- [ ] Idempotent: if same user submits same name+code within 10s, return existing league
- [ ] Error responses: structured JSON `{ error: string, code: string }`

### Tests
- [ ] ViewModel: valid submit, name too short, name too long, network error
- [ ] Edge Function: happy path, collision retry, duplicate submission, unauthenticated request
- [ ] 80%+ coverage on both

---

## Design

Designs in Figma. See design-system spec: `docs/design-system/spec.md`
Key components: DSTextField, DSButton (primary), DSCard (join code display)

---

## Data Model

Uses existing schema (`leagues`, `league_members`). No migrations required.

---

## Out of Scope

- Paid leagues (Phase 2)
- Max player cap setting (Phase 2)
- League settings edit (Phase 2)
