# Pyramid — Game Rules Specification

**Status:** APPROVED — Gate 0 signed off 2026-03-07
**Date:** 2026-03-07
**Author:** PM Agent / Orchestrator
**Approver:** Human owner (GATE 0)
**Linear:** PYR-13 / LMS-009

> **IMPORTANT:** Any change to these rules after Gate 0 approval requires human escalation.
> These rules govern real money. Changes must be reviewed and approved before deployment.

---

## 1. Overview

Pyramid is a Premier League Last Man Standing competition. Players pick one Premier League team to win each gameweek. If their team wins, they survive. If their team draws or loses, they are eliminated. The top 3 surviving players share the prize pot.

Two league types are supported:
- **Free leagues** — no entry fee, no prize pot, bragging rights only
- **Paid public matchmaking leagues** — random allocation, pseudonymous play, prize pot split between top 3 finishers

---

## 2. League Structure

### 2.1 Free Leagues

- Any registered user can create a free league
- Creator becomes the league admin
- League has a unique join code (6 characters, alphanumeric)
- Players join via join code before the league's start gameweek deadline
- Full player identities are visible to all members in free leagues

### 2.2 Public Paid Matchmaking Leagues

- Public paid leagues are formed via **random allocation** — users cannot browse or select a specific paid public league
- Users enter a stake amount and are randomly placed into a league with other users at the same stake level
- Users may join up to **5 paid public matchmaking leagues per gameweek**
- Each join requires sufficient wallet funds for the stake amount
- **Purpose:** prevents users coordinating to stack the same league, and reduces league-hopping

### 2.3 Identity and Visibility in Paid Leagues

- In paid public matchmaking leagues, participants are shown as **pseudonyms** during the league
- Participant profiles are **revealed only when the league ends**
- **Purpose:** reduces collusion and targeted abuse while keeping play fair

### 2.4 Season

- One season = one Premier League season (August to May)
- 38 gameweeks

---

## 3. Pick Rules

### 3.1 One Pick Per Gameweek

- Each surviving player must select exactly one Premier League team per gameweek
- A player can only pick each team **once per season** (no repeat picks within a paid league)
- Exception: if a player has used all 20 teams (extremely unlikely in practice), repeats are permitted

### 3.2 Pick Deadline

- A pick is valid only if submitted **before the kick-off time of the selected match**
- Once the selected match kicks off, the pick is **locked** and cannot be changed
- Players may change their pick to a different match (one that has not yet kicked off) at any time before that match's kick-off

### 3.3 No Valid Pick

- If a player fails to submit a valid pick before any match in the gameweek kicks off, they are **eliminated** from that league
- No grace period — the system hard-locks submissions at each match's kick-off

### 3.4 Pick Change Window

- Players may change their pick any number of times before the selected match kicks off
- Only the last submitted pick counts
- Pick changes are logged with timestamps for audit purposes

### 3.5 Pick Visibility

- Picks are **hidden from other players until the deadline passes** (first kick-off of the gameweek)
- After the first match of the gameweek kicks off, all locks picks become visible to league members
- This prevents copycat picks

### 3.6 Eligible Teams

- Only teams currently in the Premier League for that season are eligible
- The fixture list sourced from API-Football is the source of truth

---

## 4. Result and Elimination Rules

### 4.1 Win Condition

A player **survives** the gameweek if:
- The team they picked **wins** their match (home or away)

### 4.2 Elimination Conditions

A player is **eliminated** if any of the following occur:
- Their team **draws**
- Their team **loses**
- They did not submit a valid pick before their chosen match kicked off (auto-eliminated)

### 4.3 Result Source of Truth

- Match outcomes are determined by API-Football (see ADR-003)
- Only `FT` (full time) status triggers settlement — never live, half-time, or extra time scores
- Corrections to results are applied only within the **24-hour correction window** (aligned with the dispute window)
- After the correction window ends, results are final and not changed retroactively

### 4.4 Settlement Timing

- Settlement is processed match-by-match as results come in
- A player's fate is determined when their picked team's match reaches `FT`
- Final elimination list for a gameweek is locked once all matches in that gameweek are `FT`

### 4.5 Mass Elimination

If all remaining players are eliminated in the same gameweek:
- **No winner** is declared for that gameweek
- All eliminated players are **reinstated** as survivors and continue to the next gameweek
- This is called a "mass elimination" event

---

## 5. Prize Distribution

### 5.1 Top 3 Split

The prize pot (after platform fee) is distributed to the **top 3 surviving players**:

| Position | Share |
|----------|-------|
| 1st (last survivor, or last surviving group) | 65% |
| 2nd | 25% |
| 3rd | 10% |

### 5.2 Determining Positions

- **1st place:** the last player(s) surviving when all others are eliminated
- **2nd place:** the player(s) eliminated in the gameweek immediately before 1st place was decided
- **3rd place:** the player(s) eliminated in the gameweek before 2nd place
- If multiple players share a position (eliminated in the same gameweek), they split that position's share equally

### 5.3 Joint Winners (Paid Leagues)

- If multiple players survive to the end of the season (GW38), they are **joint 1st place winners**
- Their combined share (65%) is split equally between them
- If the split does not divide evenly to the penny, the remainder goes to the 2nd place finishers

### 5.4 Platform Fee

- Platform take rate: **8%** of gross prize pot
- Fee is deducted before distribution and displayed clearly to users at join time

---

## 6. Wallet System

### 6.1 Wallet Balances

Each user has two wallet balance states:

| Balance type | Description |
|---|---|
| **Available to play** | Winnings credited immediately after league settlement. Can be used to join new leagues. Cannot be withdrawn until dispute window expires. |
| **Withdrawable** | Funds available for withdrawal. Requires 24-hour dispute window to have passed. |

### 6.2 Dispute Window

- Winnings are credited as **Available to play** immediately after league outcome is settled
- Winnings become **Withdrawable** after a **24-hour dispute window**
- During the dispute window, users may use "Available to play" funds to join other leagues

### 6.3 Corrections During Dispute Window

- If a result is corrected within the 24-hour dispute window, wallet balances may be adjusted accordingly
- If a user has already re-staked corrected funds and their balance becomes negative:
  - They cannot join new paid leagues or withdraw until the balance is restored
  - Free-to-play participation remains available

---

## 7. Postponed and Abandoned Matches

### 7.1 Postponed Match (`PST`)

**Postponed before kick-off:**
- The player's pick for that gameweek is **voided**
- The player must **repick** from matches in the same gameweek that **have not yet kicked off**
- The repick locks at the replacement match's kick-off
- The repick follows normal rules — the player cannot pick a team they have already used this season

**No repick possible (all remaining gameweek fixtures have started):**
- If a postponement is announced after all remaining gameweek fixtures have already kicked off, no repick is possible
- The player **survives** that gameweek and the team is **not marked as used**
- The player picks normally in the next gameweek

### 7.2 Abandoned Match (`ABD`)

- Treat as postponed — pick is voided, player survives
- Settlement is held until the match is replayed and reaches `FT`
- If the match is not replayed within the same season: treat as a void result, player survives

### 7.3 VAR Overturns

- VAR decisions are reflected in the official result returned by API-Football
- Settlement always uses the final official `FT` result — never a provisional score

---

## 8. Withdrawals

- Minimum withdrawal: **£20**
- Maximum withdrawal frequency: **1 per day**
- Withdrawal fees are **passed through to the user** at cost, shown clearly before confirmation
- Withdrawals can only be made from **Withdrawable** balance (post 24-hour dispute window)

---

## 9. Anti-Collusion and Integrity Policy

### 9.1 Prohibited Behaviour

- Coordinating with others to manipulate outcomes or unfairly increase chances of winning
- Using multiple accounts or allowing others to use your account
- Attempting to enter the same paid public league through repeated joining across accounts

### 9.2 Enforcement

- The platform may take action including warnings, restricting paid entry, suspending accounts, reversing winnings, or banning accounts where prohibited behaviour is detected
- Decisions use internal integrity signals (device, payment, and behavioural patterns) and audit logs

---

## 10. Edge Cases Summary

| Scenario | Outcome |
|---|---|
| Player picks a postponed team (repick available) | Pick voided, must repick from remaining GW fixtures |
| Player picks a postponed team (no repick possible) | Pick voided, player survives, team not used |
| Player picks an abandoned match team | Same as postponed |
| All remaining players eliminated same GW | Mass elimination — all reinstated, continue |
| VAR changes result after FT logged | Use corrected FT result (API-Football returns official score) |
| Player forgets to pick | Auto-eliminated at deadline |
| Multiple players survive to GW38 | Joint 1st place, split 65% equally |
| Multiple players eliminated same GW | Share that position's prize split equally |
| Match result API data is ambiguous | Hold settlement, alert Orchestrator, human review before proceeding |
| Settlement function runs twice (idempotency test) | Second run is a no-op — no double-elimination |
| User's balance goes negative after correction | Cannot join paid leagues or withdraw until restored; free play unaffected |

---

## 11. Rules Change Policy

- These rules are locked at Gate 0 approval
- Any change to pick rules, elimination rules, or prize rules after Gate 0 requires:
  1. Human owner approval
  2. Existing players in active leagues must be notified
  3. Changes take effect from the next season only (never mid-season)
- Settlement logic changes always require human review regardless of phase

---

## 12. Glossary

| Term | Definition |
|---|---|
| Gameweek (GW) | A round of Premier League fixtures, typically Saturday–Monday |
| Pick | A player's selection of one PL team for a gameweek |
| Survivor | A player who has not yet been eliminated |
| Eliminated | A player whose team did not win in their active gameweek |
| Mass elimination | All remaining players eliminated in the same gameweek |
| Prize pot | Entry fees collected in a paid league, minus platform fee |
| Settlement | The process of determining which players survive or are eliminated after a result |
| Correction window | 24-hour window after settlement during which results can be corrected |
| Available to play | Wallet funds credited post-settlement, usable for new leagues, not yet withdrawable |
| Withdrawable | Wallet funds available for withdrawal (post 24-hour dispute window) |
| FT | Full Time — the only result status that triggers settlement |
| PST | Postponed — match has not been played, pick is void |
| ABD | Abandoned — match was started but not completed |
