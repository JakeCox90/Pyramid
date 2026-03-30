# Players Remaining Module — Redesign Spec

**Ticket:** PYR-183
**Date:** 2026-03-30
**Status:** Approved

## Goal

Replace the static "X of Y players remaining" text card with a dynamic, visual module that creates urgency, pride, and emotional engagement — keeping users hooked on the narrowing field.

## Design Direction

Hybrid of two researched approaches:
- **Layout from "The Arena"** — progress ring as hero visual, avatar rows showing survivors vs eliminated
- **Data from "The Gauntlet"** — three key stats (eliminated this week, % remaining, weeks survived)

Inspired by: FanDuel survivor depleting bar, DraftKings donut, Survivor TV memory wall, battle royale counters, poker tournament field depletion.

## Two States

### 1. Surviving (user is active)

```
┌──────────────────────────────────────────┐
│                                          │
│           ┌──────────────┐               │
│           │   Progress   │               │
│           │    Ring      │               │
│           │  (green)     │               │
│           │   7          │               │
│           │  of 32 left  │               │
│           └──────────────┘               │
│                                          │
│    [ Top 22% — Still standing ]          │  ← green pill
│                                          │
│   (You) (T) (S) (M) (J) (A) (R)         │  ← survivor avatars, green border
│      (k) (d) (p) (l) (n) +20            │  ← eliminated avatars, greyed out
│                                          │
│  ─────────────────────────────────────   │
│     5          │   22%     │    6        │
│  eliminated    │  of field │  weeks      │
│  this week     │  remain   │  survived   │
└──────────────────────────────────────────┘
```

### 2. Eliminated (user is out)

```
┌──────────────────────────────────────────┐
│                                          │
│           ┌──────────────┐               │
│           │   Progress   │               │
│           │    Ring      │               │
│           │  (grey)      │               │
│           │   7          │               │
│           │  of 32 left  │               │
│           └──────────────┘               │
│                                          │
│    [ Eliminated in GW 29 ]               │  ← red pill
│                                          │
│   (T) (S) (M) (J) (A) (R) (W)           │  ← survivor avatars, green border
│   (You) (k) (d) (p) (l) (n) +19         │  ← eliminated row, user has red border
│                                          │
│  ─────────────────────────────────────   │
│     6          │   22%     │    5        │
│  eliminated    │  of field │  weeks      │
│  this week     │  remain   │  you lasted │
└──────────────────────────────────────────┘
```

### Key differences in eliminated state

- Ring fill desaturates from green to muted grey
- Badge flips from green "Still standing" to red "Eliminated in GW N"
- User's avatar moves from survivor row to eliminated row (slightly larger, red border)
- "Weeks survived" becomes "weeks you lasted" (past tense)
- % and eliminated count remain — user stays engaged as spectator (PYR-161)

## Token Mapping

Every visual element maps to the design system. No raw values.

### Container
| Element | Token |
|---------|-------|
| Background | `Theme.Color.Surface.Background.container` |
| Corner radius | `Theme.Radius.r50` (24pt) |
| Inner padding | `Theme.Spacing.s40` (16pt) |

### Progress Ring
| Element | Token |
|---------|-------|
| Track colour | `Theme.Color.Surface.Background.page` |
| Fill (surviving) | `Theme.Color.Status.Success.resting` |
| Fill (eliminated) | `Theme.Color.Content.Text.disabled` |
| Stroke width | 9pt |
| Ring diameter | 130pt |

### Counter (inside ring)
| Element | Token |
|---------|-------|
| Number font | `Theme.Typography.h2` |
| Number colour (surviving) | `Theme.Color.Status.Success.resting` |
| Number colour (eliminated) | `Theme.Color.Content.Text.subtle` |
| "of X left" font | `Theme.Typography.caption` |
| "of X left" colour | `Theme.Color.Content.Text.subtle` |

### Status Badge (pill)
| Element | Token |
|---------|-------|
| Background (surviving) | `Theme.Color.Status.Success.subtle` |
| Text (surviving) | `Theme.Color.Status.Success.resting` |
| Background (eliminated) | `Theme.Color.Status.Error.subtle` |
| Text (eliminated) | `Theme.Color.Status.Error.resting` |
| Corner radius | `Theme.Radius.pill` |
| Font | `Theme.Typography.label01` |
| Vertical padding | `Theme.Spacing.s10` (4pt) |
| Horizontal padding | `Theme.Spacing.s30` (12pt) |

### Avatars
| Element | Token |
|---------|-------|
| Survivor avatars | Existing `Avatar` component, size `.small` (32pt) |
| Survivor border | 2pt, `Theme.Color.Status.Success.resting` |
| Current user bg (surviving) | `Theme.Color.Primary.resting` |
| Eliminated avatars | 20pt circles, `Theme.Color.Surface.Background.elevated`, opacity 0.5 |
| Current user (eliminated) | 24pt, border `Theme.Color.Status.Error.resting` |
| Avatar gap | `Theme.Spacing.s20` (8pt) |
| Row gap (survivors to eliminated) | `Theme.Spacing.s30` (12pt) |

### Stats Row
| Element | Token |
|---------|-------|
| Top border | `Theme.Color.Border.light` |
| Dividers | `Theme.Color.Border.light` |
| Number font | `Theme.Typography.subhead` |
| Label font | `Theme.Typography.caption` |
| Label colour | `Theme.Color.Content.Text.subtle` |
| "Eliminated" number | `Theme.Color.Status.Error.resting` |
| "% remain" number (surviving) | `Theme.Color.Status.Success.resting` |
| "% remain" number (eliminated) | `Theme.Color.Content.Text.subtle` |
| "Weeks" number | `Theme.Color.Content.Text.default` |
| Padding top | `Theme.Spacing.s30` (12pt) |

### Section Spacing
| Element | Token |
|---------|-------|
| Ring to badge | `Theme.Spacing.s40` (16pt) |
| Badge to survivor avatars | `Theme.Spacing.s40` (16pt) |
| Survivors to eliminated row | `Theme.Spacing.s30` (12pt) |
| Eliminated row to stats | `Theme.Spacing.s40` (16pt) |

## Animation

- Ring animates from 0 to current fill percentage when the component scrolls into view
- Triggered by `.onAppear` setting an `appeared` state flag
- Animation: `.easeOut(duration: 0.8)`
- No other animations for MVP

## Interaction

- No tap action for MVP — the card is display-only
- Future: tappable to expand into full standings or elimination timeline

## Data Model

### New: `MemberSummary`
```swift
struct MemberSummary: Identifiable, Equatable {
    let userId: String
    let displayName: String
    let avatarURL: String?
    let status: LeagueMember.MemberStatus
    var id: String { userId }
}
```

### Extended: `HomeData`
Add new field:
```swift
let memberSummaries: [String: [MemberSummary]]  // keyed by league ID
```

### New: `EliminationStats`
Computed per league, not stored on `PlayerCount`:
```swift
struct EliminationStats: Equatable {
    let eliminatedThisWeek: Int
    let survivalStreak: Int
}
```
Added to `HomeData` as `let eliminationStats: [String: EliminationStats]` keyed by league ID.

### ViewModel access
`HomeViewModel` exposes `eliminationStats(for:)` which reads from `HomeData.eliminationStats[leagueId]`. No separate computed property needed — stats are fetched with the rest of home data.

## Data Fetching

### Member summaries query
New lightweight query on `league_members` joined to `profiles`:
```
SELECT lm.user_id, p.display_name, p.avatar_url, lm.status
FROM league_members lm
JOIN profiles p ON p.id = lm.user_id
WHERE lm.league_id = $1
```

### Eliminated this week
Count members with `status = 'eliminated'` whose elimination happened in the current gameweek. Options:
1. Track `eliminated_at_gameweek` on `league_members` (preferred — explicit)
2. Count picks with `result = 'eliminated'` for current GW (derived — works with existing schema)

For MVP, use option 2 (no migration needed).

### Survival streak
Count consecutive picks with `result = 'survived'` for the current user in the league, walking backwards from the most recent settled gameweek.

## Files Affected

### Modified
- `ios/Pyramid/Sources/Shared/DesignSystem/Components/PlayersRemainingCard.swift` — full rewrite
- `ios/Pyramid/Sources/Features/Home/HomeView+PlayersRemaining.swift` — pass new data
- `ios/Pyramid/Sources/Models/HomeData.swift` — add `memberSummaries`, extend `PlayerCount`
- `ios/Pyramid/Sources/Features/Home/HomeViewModel.swift` — add `survivalStreak(for:)`
- `ios/Pyramid/Sources/Services/HomeService.swift` — fetch member summaries
- `ios/Pyramid/Sources/Services/HomeService+Helpers.swift` — new `fetchMemberSummaries` helper

### New
- None — all changes modify existing files

### Deleted
- `ios/Pyramid/Sources/Features/Home/PlayersRemainingExploration.swift` — leftover from previous session
- `ios/Pyramid/Sources/Features/Home/PlayersRemainingSnapshot.swift` — leftover from previous session

## Scaling Behaviour

- **5 players:** All avatars visible, no "+N" overflow
- **15 players:** All survivors visible, eliminated may overflow to "+N"
- **30 players:** Survivors visible (up to ~8 before "+N"), eliminated overflow
- **50 players:** Both rows overflow with "+N" counters
- Max visible avatars per row: 8 (survivors) / 6 (eliminated) — the rest collapse to "+N"

## Anti-Collusion

Per game rules: no pre-deadline information leaks. The module only shows:
- Player counts and statuses (already public post-deadline)
- Member names/avatars (already visible in league member list)
- No pick information is surfaced in this module
