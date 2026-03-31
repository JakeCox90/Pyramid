# Gameweek UI States — Homepage Lifecycle

**Status:** DRAFT
**Date:** 2026-03-31
**References:** [Game Rules](rules.md) §3–4, `HomeViewModel.swift`, `HomeView.swift`

---

## Overview

The homepage adapts to the current phase of the gameweek. Each league the user belongs to is displayed independently — a user can be alive in one league and eliminated in another, and each league tab reflects its own state.

The gameweek lifecycle has four phases, determined by `GameweekPhase` in `HomeViewModel.swift`. The homepage renders different content in each phase, and further branches on whether the user is alive or eliminated in the selected league.

---

## State Machine

### State 1: Pre-Deadline — `.upcoming`

The countdown is ticking. The user needs to make or confirm their pick before the first fixture kicks off.

**Trigger to enter:** A current gameweek exists and no fixtures have started yet. `deadline_at` is in the future and no fixture status is live or finished.

**Trigger to exit:** The first fixture kicks off (any fixture status becomes live, or the earliest kickoff time passes). See [Game Rules §3.2](rules.md#32-pick-deadline).

| Element | Alive | Eliminated |
|---------|-------|------------|
| Countdown header | "GAMEWEEK BEGINS" + `Xd XXh XXm XXs` timer | Same |
| Main card | Hero match card (current pick) or "MAKE YOUR PICK" empty state | EliminationCard or fallback (xmark + "ELIMINATED" + league name) |
| Players remaining | PlayersRemainingCard — green ring, "Top X% — Still standing" badge | PlayersRemainingCard — muted ring, "Eliminated in GW X" badge |
| Previous picks | Previous picks section | Previous picks section |
| Actions | "CHANGE PICK" button on hero card navigates to PicksView | None — eliminated users cannot pick |

**Key behaviour:**
- Picks are hidden from other league members until deadline (§3.5)
- Users can change their pick any number of times before their selected match kicks off (§3.4)
- No valid pick at deadline = auto-elimination (§3.3) — fires at first kick-off, not at FT

---

### State 2: Match Day — `.inProgress`

Fixtures are live. The user is watching to see if their pick survives.

**Trigger to enter:** Any fixture's status becomes live (`1H`, `HT`, `2H`, `ET`, `P`) or finished, or `isGameweekLocked` returns true (earliest kickoff ≤ now).

**Trigger to exit:** All fixtures in the gameweek reach `FT` status.

| Element | Alive | Eliminated |
|---------|-------|------------|
| Countdown header | "In Progress" with sportscourt icon | Same |
| Main card | Live match card (if pick fixture is live — shows updating score) or hero card (if pick fixture hasn't started yet) | EliminationCard |
| Players remaining | PlayersRemainingCard — counts update as settlements arrive | PlayersRemainingCard — muted state |
| Previous picks | Previous picks section | Previous picks section |

**Key behaviour:**
- All locked picks are now visible to league members (§3.5)
- Settlement is match-by-match as results come in (§4.4)
- A user's fate is determined when their picked team's match reaches FT
- Live score polling refreshes fixtures on a timer (`HomeViewModel+Actions.swift`)

---

### State 3: Post-Settlement — `.finished`

All fixtures are finished. Results are in.

**Trigger to enter:** All fixtures in the gameweek have `isFinished == true` (status `FT`).

**Trigger to exit:** A new gameweek is detected (next `load()` returns a different current gameweek).

| Element | Survived | Newly Eliminated |
|---------|----------|------------------|
| Countdown header | "Complete" with checkmark icon | Same |
| Main card | Survived match card variant (green flag) | EliminationCard with match result |
| Overlay | SurvivalOverlay — shown once per league per GW (UserDefaults: `survival_seen_{leagueId}_{gwName}`) | EliminationOverlay — shown once per league (UserDefaults: `elimination_seen_{leagueId}`) |
| Players remaining | PlayersRemainingCard — final counts for GW | PlayersRemainingCard — muted, "Eliminated in GW X" |
| Previous picks | Previous picks section | Previous picks section |

**Key behaviour:**
- Overlays are full-screen covers shown exactly once, controlled by UserDefaults flags
- Elimination overlay takes priority — survival overlay won't show while elimination overlay is active
- The full GW elimination list is locked once ALL matches in the GW are FT (§4.4)

---

### State 4: Between Gameweeks — `.unknown`

No current gameweek data available, or the gameweek has no fixtures.

**Trigger to enter:** `homeData?.fixtures` is empty or nil, or no current gameweek exists.

**Trigger to exit:** A new gameweek with fixtures is detected on next `load()`.

| Element | Display |
|---------|---------|
| Countdown header | Hidden (EmptyView) |
| Main card | Depends on last known state — may show previous pick or empty |
| Players remaining | May render with last known data |
| Previous picks | Previous picks section (historical data) |

---

## Eliminated User Experience

Elimination is **per-league**. A user can be alive in League A and eliminated in League B simultaneously. Each league tab on the homepage renders independently based on the user's status in that league.

### What changes when eliminated

1. **Main card:** Hero match card is replaced by `EliminationCard` (showing the losing match result) or a fallback card (xmark + "ELIMINATED" + league name) if result data isn't loaded yet
2. **Players remaining:** Always displays (not hidden). Shows muted ring colour, disabled text styling, and "Eliminated in GW X" red badge instead of "Top X% — Still standing" green badge
3. **League tab pill:** Shows `xmark.seal.fill` icon in red. Unselected eliminated pills render at reduced opacity (0.6) for scannability
4. **No pick actions:** "CHANGE PICK" / "MAKE YOUR PICK" buttons are not shown — the elimination section replaces them

### When does the eliminated state appear?

- **Auto-elimination (§3.3):** At the deadline (first kick-off). The user's status changes to `.eliminated` in the backend. On next `load()`, the homepage reflects this.
- **Match loss (§4.2):** When the user's picked team's match reaches FT with a loss. Settlement updates the status. On next `load()` or poll refresh, the homepage reflects this.

### When does the eliminated gameweek disappear?

The eliminated state is **permanent for that league**. It does not disappear. The user remains eliminated for the rest of the round. They can:
- View the league in spectator mode (PYR-161)
- See other leagues where they're still alive via league tab switching
- Join new leagues

### One-time overlays

| Overlay | Trigger | Dedup Key | Priority |
|---------|---------|-----------|----------|
| EliminationOverlay | User status == `.eliminated` AND result data available | `elimination_seen_{leagueId}` | Higher — blocks survival overlay |
| SurvivalOverlay | User status == `.active` AND survived result from last GW | `survival_seen_{leagueId}_{gwName}` | Lower — waits for elimination check |

---

## Edge Cases

### Auto-Elimination at Deadline (§3.3)

- If a user has no valid pending pick when the first fixture kicks off, they are **immediately eliminated**
- This happens at the transition from `.upcoming` → `.inProgress`
- The user will see the elimination state on their next homepage load
- No grace period — auto-elimination fires at the deadline, not when any match reaches FT

### Mass Elimination (§4.5)

- If **all remaining players** are eliminated in the same gameweek, no winner is declared
- All eliminated players are **reinstated** as survivors and continue to the next gameweek
- Users would see the elimination overlay, but on the next gameweek their status returns to `.active`
- The PlayersRemainingCard would show 0 active briefly, then reset on reinstatement

### Settlement Timing (§4.4)

- Settlement is **match-by-match**, not end-of-gameweek
- A user's fate is determined when their picked team's match reaches `FT`
- During `.inProgress`, some users may already be eliminated while others are still watching live matches
- The homepage polls for updates, so eliminated status can appear mid-match-day

### Pick Change Window (§3.4)

- Users can change their pick any number of times before their selected match kicks off
- Only the last submitted pick counts
- "CHANGE PICK" button is visible in the `.upcoming` phase on the hero match card
- Once a match kicks off, the pick for that match is locked — but the user could still change to a different match that hasn't started (if their current pick's match hasn't kicked off)

### Correction Window (§4.3)

- Result corrections can be applied within the 24-hour correction window
- After the window closes, results are final
- If a correction changes a user's outcome, their status updates on next `load()`

---

## Implementation Reference

| State | `GameweekPhase` | Countdown View | Content View | Key ViewModel Properties |
|-------|----------------|----------------|--------------|-------------------------|
| Pre-deadline | `.upcoming` | `countdownTimerView` — "GAMEWEEK BEGINS" + timer | `matchCard` / `matchCardEmpty` / `eliminationSection` | `countdown`, `currentPick`, `isEliminated(in:)` |
| Match day | `.inProgress` | `gameweekStatusView("In Progress")` — sportscourt icon | `matchCard` (live scores) / `eliminationSection` | `livePickContexts`, `hasLiveFixtures`, `isGameweekLocked` |
| Post-settlement | `.finished` | `gameweekStatusView("Complete")` — checkmark icon | `matchCard` (survived flag) / `eliminationSection` | `currentPick`, `survivalResult(for:)`, `eliminationResult(for:)` |
| Between GWs | `.unknown` | `EmptyView` | Fallback / previous data | — |

### Key files

| File | Responsibility |
|------|---------------|
| `HomeViewModel.swift` | Published state, `load()`, computed properties, `GameweekPhase` enum |
| `HomeViewModel+Helpers.swift` | `gameweekPhase`, `isEliminated(in:)`, `eliminationResult(for:)`, `survivalResult(for:)`, `isGameweekLocked` |
| `HomeViewModel+Actions.swift` | Countdown timer, live score polling, gameweek switching |
| `HomeView.swift` | Root layout, `leaguePageContent` per-league rendering |
| `HomeView+Countdown.swift` | Countdown section — switches on `gameweekPhase` |
| `HomeView+LeagueSelector.swift` | League tab pills with eliminated indicators |
| `HomeView+Elimination.swift` | `eliminationSection`, `checkForElimination`, elimination overlay trigger |
| `HomeView+Survival.swift` | `survivalSection`, `checkForSurvival`, survival overlay trigger |
| `PlayersRemainingCard.swift` | Players remaining ring, avatars, stats — handles both alive and eliminated states |
