# Gameweek Summary — Post-Settlement Experience Redesign

**Date:** 2026-03-31
**Status:** Draft
**Replaces:** SurvivalOverlay, EliminationOverlay, per-league overlay trigger system

## Problem

The current post-settlement overlay system is broken:
- `checkForSurvival` and `checkForElimination` both `return` after the first league match, so users in multiple leagues only ever see one result
- `.onChange(of: homeData)` doesn't re-fire after overlay dismissal, so remaining leagues are never shown
- The two separate overlays (survival + elimination) create an inconsistent, spammy experience for multi-league users

## Solution

Replace the per-league overlay system with two new components:

1. **Gameweek Summary overlay** — a single full-screen overlay with a horizontal card carousel showing performance across all leagues
2. **Gameweek Result Card** — a compact homepage card per league showing the user's result, tappable to re-open the overlay

## Data Model

### GameweekSummaryItem

```swift
struct GameweekSummaryItem: Identifiable {
    let id: String           // leagueId
    let leagueName: String
    let result: Result
    let pickedTeamName: String
    let opponentName: String
    let homeScore: Int
    let awayScore: Int
    let pickedHome: Bool
    let survivalStreak: Int
    let playersRemaining: Int
    let totalPlayers: Int

    enum Result {
        case survived
        case eliminated
    }
}
```

Built from existing data in `HomeViewModel` — `lastGwResults`, `memberStatuses`, `playersRemaining`. No new API calls required.

## Trigger Logic

- `HomeViewModel` builds `gameweekSummaryItems: [GameweekSummaryItem]` from settled league results
- New published property: `showGameweekSummary: Bool`
- On `load()`, after data arrives: if `gameweekPhase == .finished` AND summary items exist AND `UserDefaults` key `gw_summary_seen_{gwId}` is not set → set `showGameweekSummary = true`
- Single UserDefaults key per gameweek (not per league) — the summary is one grouped view
- Re-access: tapping the homepage result card sets `showGameweekSummary = true` regardless of UserDefaults state

## Gameweek Summary Overlay

### Container
- Full-screen cover with dark semi-transparent background + blur
- Swipe-down gesture to dismiss (drag threshold ~100pt vertical)
- Tap on background outside card area to dismiss
- Fade-in entrance, card scales up from 0.9 with spring animation

### Card Carousel
- Horizontal `ScrollView` with snap behaviour using `scrollTargetBehavior(.paging)` + `scrollTargetLayout()` (iOS 17+)
- Each card takes ~85% of screen width; next card peeks ~15% from right edge, signalling swipeability
- One card snaps at a time
- Page dots below carousel indicate league count and current position
- Single league: one centered card, no peek, no dots

### Card Content (per league)
Visual hierarchy — result dominates, supporting info is secondary:

1. **League name** — section label at top of card
2. **Result icon** — green `checkmark.seal` (survived) or red `xmark.seal` (eliminated), ~60pt
3. **Result title** — "SURVIVED" or "ELIMINATED" in bold, coloured green/red
4. **Score block** — Home vs Away with scores, picked team highlighted
5. **Supporting info pills** (two pills below score):
   - Survival streak: "Streak: 4" or "Streak ended"
   - Players remaining: "8 of 12 left"

Cards have rounded corners (`Theme.Radius.r50`), solid background (`Theme.Color.Surface.Background.container`).

## Gameweek Result Card (Homepage)

Compact card shown per-league on the homepage when the gameweek is settled. Replaces both `EliminationCard` and the stale match card.

### Layout
- Full-width, rounded corners, standard container background
- **Left:** Result icon — green checkmark.seal or red xmark.seal (~32pt)
- **Center (stacked vertically):**
  - Result label: "Survived" or "Eliminated" (bold, green/red)
  - Pick summary: "You picked Arsenal vs Chelsea 2-1" (subtle text)
- **Right edge:** Chevron icon indicating tappable

### Behaviour
- Tapping opens the Gameweek Summary overlay, scrolled to that league's card position
- Shown in `leaguePageContent` where the match card / elimination section currently appears
- Uses the same `GameweekSummaryItem` model as the overlay

### Homepage Logic

```
if gameweek is settled AND summaryItem exists {
    GameweekResultCard(item: summaryItem)
} else if viewModel.isEliminated(in: league) {
    eliminationSection(for: league)
} else if let context = viewModel.currentPick(for: league) {
    matchCard(context)
} else {
    matchCardEmpty()
}
```

## HomeView Integration

### Removed
- `@State var showEliminationOverlay` / `eliminationOverlayResult`
- `@State var showSurvivalOverlay` / `survivalOverlayResult`
- `checkForElimination(data:)` function
- `checkForSurvival(data:)` function
- `.onChange(of: viewModel.homeData)` handler that called those functions
- Both `.fullScreenCover` modifiers for elimination and survival overlays

### Added
- Single `.fullScreenCover(isPresented: $viewModel.showGameweekSummary)` presenting `GameweekSummaryView`
- Pass `viewModel.gameweekSummaryItems` and `summaryStartIndex` (for re-access from a specific league)

### Trigger Moved to ViewModel
- `HomeViewModel.load()` builds summary items and checks UserDefaults
- Sets `showGameweekSummary = true` when auto-show conditions met
- View no longer contains trigger logic

## Files

### New
- `GameweekSummaryView.swift` — overlay with card carousel
- `GameweekResultCard.swift` — compact homepage card
- `GameweekSummaryItem.swift` — shared data model

### Modified
- `HomeView.swift` — remove overlay state/modifiers, add single summary fullScreenCover
- `HomeView+Elimination.swift` — remove `checkForElimination`, keep `eliminationSection` for pre-settlement
- `HomeView+Survival.swift` — remove `checkForSurvival`
- `HomeViewModel.swift` — add `showGameweekSummary`, `gameweekSummaryItems`, `summaryStartIndex`
- `HomeViewModel+Helpers.swift` — add summary item builder logic

### Deleted
- `SurvivalOverlay.swift` — replaced by overlay league page
- `EliminationOverlay.swift` — replaced by overlay league page

## Fixes Addressed
- **PYR-219:** Multi-league overlay only showing first league — fully replaced by grouped carousel
- Inconsistent post-settlement UI (different cards for survived vs eliminated) — unified under GameweekResultCard
