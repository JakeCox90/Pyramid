# PYR-103: Shared Tension Moments — Design Spec

## Goal

Show post-deadline contextual banners in league detail that aggregate pick data into shared narrative moments: "3 players picked Arsenal — all watching nervously." Creates emotional engagement without revealing individual picks pre-deadline.

## Architecture

**No new backend work.** `StandingsService.fetchLockedPicks()` already returns all locked picks for a league+gameweek after the deadline (enforced by RLS). Client-side aggregation groups picks by `teamId` to derive tension data.

### Data Flow

1. `LeagueDetailViewModel` calls `fetchLockedPicks()` (existing, post-deadline only)
2. New computed property `tensionMoments` groups `lockedPicks` by `teamId`, filters to teams with 2+ pickers
3. `TensionBannerView` renders each moment as a compact card
4. Displayed in overview tab between `myPickCard` and `membersList`

### Anti-Collusion Safeguards

- Gated behind `isDeadlinePassed()` — RLS also enforces server-side
- Shows team name + count only — no individual player names
- Framed as passive observation, not coordination
- Works identically in free and paid leagues (counts don't reveal identity)

## Data Model

```swift
struct TensionMoment: Identifiable {
    let id: Int          // teamId
    let teamName: String
    let teamId: Int
    let pickCount: Int   // number of players who picked this team
}
```

Derived from existing `[String: MemberPick]` dictionary in `LeagueDetailViewModel`:

```swift
var tensionMoments: [TensionMoment] {
    let grouped = Dictionary(grouping: lockedPicks.values, by: \.teamId)
    return grouped.compactMap { teamId, picks in
        guard picks.count >= 2 else { return nil }
        return TensionMoment(
            id: teamId,
            teamName: picks[0].teamName,
            teamId: teamId,
            pickCount: picks.count
        )
    }
    .sorted { $0.pickCount > $1.pickCount }
    .prefix(3)  // max 3 banners
    .map { $0 }
}
```

## UI Component: TensionBannerView

### Layout

Compact horizontal card per tension moment:
- Team badge (24pt, from existing `TeamBadge` or SF Symbol fallback)
- Text: "{count} players picked {TeamName} — {flavor text}"
- Background: `Theme.Color.Surface.Background.container` with subtle brand tint
- Corner radius: `Theme.Radius.r30`
- Padding: `Theme.Spacing.s30`

### Flavor Text Variants

Based on `pickCount`:
- 2 players: "shared fate"
- 3 players: "all watching nervously"
- 4+ players: "biggest group at risk"

### Placement

In `LeagueDetailView+Standings.swift`, within `overviewContent`:
- After `myPickCard` section
- Before `membersList` section
- Only visible when `isDeadlinePassed() && !tensionMoments.isEmpty`
- Wrapped in VStack with `Theme.Spacing.s20` spacing

### Empty State

No banners shown if every player picked a unique team (no teams with 2+ picks). No placeholder or "no shared picks" message — section simply doesn't render.

## Files

### Create
- `ios/Pyramid/Sources/Features/Leagues/TensionBannerView.swift` — UI component
- `ios/Pyramid/Sources/Models/TensionMoment.swift` — data model

### Modify
- `ios/Pyramid/Sources/Features/Leagues/LeagueDetailViewModel.swift` — add `tensionMoments` computed property
- `ios/Pyramid/Sources/Features/Leagues/LeagueDetailView+Standings.swift` — integrate banners into overview tab

## Testing

- Verify banners only appear post-deadline (`isDeadlinePassed() == true`)
- Verify teams with <2 picks are excluded
- Verify max 3 banners displayed
- Verify correct count and team name rendering
- Verify flavor text matches count thresholds
- Build passes, SwiftLint passes

## Out of Scope

- HomeView integration (future ticket if wanted)
- Push notifications for tension moments
- Real-time updates during live matches
- Backend RPC or Edge Function changes
