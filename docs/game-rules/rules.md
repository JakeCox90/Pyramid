# Pyramid — Game Rules Specification

**Status:** Draft — Pending GATE 0 approval
**Date:** 2026-03-07
**Author:** PM Agent / Orchestrator
**Approver:** Human owner (GATE 0)
**Linear:** PYR-13 / LMS-009

> **IMPORTANT:** Any change to these rules after Gate 0 approval requires human escalation.
> These rules govern real money. Changes must be reviewed and approved before deployment.

---

## 1. Overview

Pyramid is a Premier League Last Man Standing competition. Players pick one Premier League team to win each gameweek. If their team wins, they survive. If their team draws or loses, they are eliminated. The last player (or players) standing wins.

Two league types are supported:
- **Free leagues** — no entry fee, no prize pot, bragging rights only
- **Paid staking leagues** — entry fee collected, prize pot distributed to winner(s)

---

## 2. League Structure

### 2.1 Creating a League

- Any registered user can create a league
- Creator becomes the league admin
- League has a unique join code (6 characters, alphanumeric)
- League settings set at creation and cannot be changed after the first gameweek begins:
  - League name
  - League type (free / paid)
  - Entry fee (paid leagues only)
  - Maximum players (optional cap)
  - Start gameweek (default: Gameweek 1 of current season)

### 2.2 Joining a League

- Players join via join code before the league's start gameweek deadline
- No joining after the start gameweek pick deadline has passed
- Paid leagues: entry fee must be paid at join time (payment integration: GATE — pending Phase 2)

### 2.3 Season

- One season = one Premier League season (August to May)
- 38 gameweeks
- A league runs until one player remains or all players are eliminated (see consolation rules)

---

## 3. Pick Rules

### 3.1 One Pick Per Gameweek

- Each surviving player must select exactly one Premier League team per gameweek
- A player can only pick each team **once per season** across all gameweeks (no repeat picks)
- Exception: if a player has used all 20 teams (extremely unlikely in practice), repeats are permitted

### 3.2 Pick Deadline

- The pick deadline for each gameweek is **kick-off of the first match in that gameweek**
- Example: if GW12 starts with Man City vs Arsenal at 12:30 on Saturday, the deadline is 12:30 Saturday
- Picks cannot be changed or submitted after the deadline — the system hard-locks submissions
- If a player has not submitted a pick by the deadline, they are auto-eliminated (no grace period)

### 3.3 Pick Change Window

- Players may change their pick any number of times **before the deadline**
- Only the last submitted pick counts
- Pick changes are logged with timestamps for audit purposes

### 3.4 Pick Visibility

- Picks are **hidden from other players until the deadline passes**
- After the deadline, all picks for that gameweek become visible to all league members
- This prevents copycat picks

### 3.5 Eligible Teams

- Only teams currently in the Premier League for that season are eligible to pick
- Relegated/promoted teams update at season start; the fixture list is the source of truth

---

## 4. Result and Elimination Rules

### 4.1 Win Condition

A player **survives** the gameweek if:
- The team they picked **wins** their match (home or away)

### 4.2 Elimination Conditions

A player is **eliminated** if any of the following occur:
- Their team **draws**
- Their team **loses**
- They did not submit a pick before the deadline (auto-eliminated)

### 4.3 Result Source

- Results are sourced from API-Football (see ADR-003)
- Only `FT` (full time) status triggers settlement — never live, half-time, or extra time scores
- Settlement runs automatically after each match reaches `FT` status

### 4.4 Settlement Timing

- Settlement is processed match-by-match as results come in
- A player's fate is determined when their picked team's match reaches `FT`
- Players who picked teams playing early in a gameweek may be eliminated before the gameweek's final matches are played — this is by design (information asymmetry is part of the game)
- Final elimination list for a gameweek is locked once all matches in that gameweek are `FT`

### 4.5 Multi-Match Gameweeks

- Some gameweeks span multiple days (e.g., matches on Saturday, Sunday, and Monday)
- A player survives as long as their team's match result was a win — regardless of when in the gameweek it was played
- Results from other matches do not affect a player's result

---

## 5. Consolation Rules

### 5.1 All Players Eliminated in Same Gameweek

If all remaining players are eliminated in the same gameweek (all their teams drew or lost):
- **No winner** is declared for that gameweek
- All eliminated players are **reinstated** as survivors and continue to the next gameweek
- This is called a "mass elimination" event — it is rare but possible (e.g., all remaining players picked teams that drew)

### 5.2 Final Gameweek (GW38)

If multiple players survive until Gameweek 38 and all survive GW38:
- **Joint winners** are declared
- In paid leagues: prize pot split equally between joint winners (rounded to pence; any remainder donated to a specified charity — GATE: charity designation requires human approval)

### 5.3 Tiebreaker

- There is no tiebreaker. Joint winners share the prize.
- This prevents any unfair secondary competition that players did not sign up for.

---

## 6. Postponed and Abandoned Matches

### 6.1 Postponed Match (`PST`)

If a player's picked team's match is postponed (e.g., weather, bereavement fixture, stadium issues):
- The player's pick for that gameweek is **voided**
- The player **survives** the gameweek (no penalty for a postponed match)
- The player receives a **wildcard pick** for the gameweek in which the postponed match is rescheduled:
  - They may pick any team (including one already used) for that specific gameweek only
  - This is a one-off exception — their used-teams list is not affected

> **GATE:** The exact wildcard pick rule for postponements requires human approval at Gate 0.

### 6.2 Abandoned Match (`ABD`)

If a match is abandoned after kick-off (e.g., crowd trouble, floodlight failure):
- Treat as postponed — pick is voided, player survives
- Settlement is held until the match is replayed and reaches `FT`
- If the match is not replayed within the same season: treat as a void result, player survives

### 6.3 VAR Overturns

- VAR decisions that change the final score are reflected in the official result
- API-Football returns the correct final score including VAR overturns
- Settlement always uses the final official `FT` result — never a provisional score

---

## 7. Staking and Prize Pool Rules

> **GATE:** All payment processing and staking rules require human approval and compliance review before Phase 2 implementation.

### 7.1 Free Leagues

- No entry fee
- No prize pot
- League is purely competitive — eliminations and survival are the game

### 7.2 Paid Staking Leagues

- Entry fee set by league creator at creation (minimum: £1, maximum: £100 — GATE: limits require human approval)
- Entry fee collected at join time
- Prize pot = (entry fee × number of players) minus platform fee (GATE: fee % requires human approval)
- Prize pot is held in escrow until a winner is declared
- Winner receives prize pot directly to their registered payment method

### 7.3 Refund Policy

- If a league fails to start (e.g., fewer than 2 players join by start gameweek): full refund to all players
- If a league is cancelled by admin before Gameweek 1: full refund to all players
- No refunds once Gameweek 1 pick deadline has passed

### 7.4 Platform Fee

- GATE: Platform fee percentage requires human approval
- Fee is deducted from prize pot before distribution

---

## 8. Edge Cases Summary

| Scenario | Outcome |
|---|---|
| Player picks a postponed team | Pick voided, player survives, wildcard for rescheduled GW |
| Player picks an abandoned match team | Same as postponed |
| All remaining players eliminated same GW | Mass elimination — all reinstated, continue |
| VAR changes result after FT logged | Use corrected FT result (API-Football returns official score) |
| Player forgets to pick | Auto-eliminated at deadline |
| Two players survive to end of season | Joint winners, split prize equally |
| Match result API data is ambiguous | Hold settlement, alert Orchestrator, human review before proceeding |
| Settlement function runs twice (idempotency test) | Second run is a no-op — no double-elimination |

---

## 9. Rules Change Policy

- These rules are locked at Gate 0 approval
- Any change to pick rules, elimination rules, or prize rules after Gate 0 requires:
  1. Human owner approval
  2. Existing players in active leagues must be notified
  3. Changes take effect from the next season only (never mid-season)
- Settlement logic changes always require human review regardless of phase

---

## 10. Glossary

| Term | Definition |
|---|---|
| Gameweek (GW) | A round of Premier League fixtures, typically Saturday–Monday |
| Pick | A player's selection of one PL team for a gameweek |
| Survivor | A player who has not yet been eliminated |
| Eliminated | A player whose team did not win in their active gameweek |
| Mass elimination | All remaining players eliminated in the same gameweek |
| Wildcard | A one-off exception allowing a repeat team pick |
| Prize pot | The total entry fees collected in a paid league, minus platform fee |
| Settlement | The process of determining which players survive or are eliminated after a result |
| FT | Full Time — the only result status that triggers settlement |
| PST | Postponed — match has not been played, pick is void |
| ABD | Abandoned — match was started but not completed |
