# Design System — Usage Guide

> How to use Pyramid's design tokens and components in SwiftUI.
> All tokens live in `ios/Pyramid/Sources/Shared/DesignSystem/`.

---

## Architecture

The design system uses a unified `Theme.*` namespace with adaptive light/dark colour support:

```
Theme.Color.*       — semantic colours (adaptive light/dark)
Theme.Typography.*  — font scale (SF Pro)
Theme.Spacing.*     — spacing scale (4pt base grid)
Theme.Radius.*      — corner radius tokens
Theme.Shadow.*      — elevation shadows
Theme.Icon.*        — SF Symbol names
```

Colours are defined using adaptive helpers that resolve different values for light and dark mode automatically.

**Rule: Always use the `Theme.*` API.** Never reference raw hex values or system colours.

---

## Token Reference

### Colours — `Theme.Color.*`

| Namespace | Tokens | Usage |
|-----------|--------|-------|
| `Theme.Color.Primary` | `.resting`, `.pressed`, `.selected`, `.text`, `.disabled` | Buttons, active states |
| `Theme.Color.Secondary` | `.resting`, `.pressed`, `.selected`, `.text`, `.disabled` | Secondary actions |
| `Theme.Color.Content.Text` | `.default`, `.subtle`, `.contrast`, `.disabled` | Text hierarchy |
| `Theme.Color.Content.Link` | `.resting`, `.pressed`, `.contrast`, `.disabled` | Link styles |
| `Theme.Color.Surface.Background` | `.container`, `.highlight`, `.page`, `.disabled`, `.transparent` | Backgrounds |
| `Theme.Color.Surface.Overlay` | `.default`, `.heavy` | Modal overlays |
| `Theme.Color.Surface.Skeleton` | `.default`, `.heavy` | Loading placeholders |
| `Theme.Color.Border` | `.default`, `.heavy` | Borders, dividers |
| `Theme.Color.Status.Info` | `.resting`, `.pressed`, `.text`, `.subtle`, `.border` | Info indicators |
| `Theme.Color.Status.Error` | `.resting`, `.pressed`, `.text`, `.subtle`, `.border` | Error / eliminated |
| `Theme.Color.Status.Success` | `.resting`, `.pressed`, `.text`, `.subtle`, `.border` | Success / survived |
| `Theme.Color.Status.Warning` | `.resting`, `.pressed`, `.text`, `.subtle`, `.border` | Warning / deadline |
| `Theme.Color.Status.Breaking` | `.resting`, `.pressed`, `.text`, `.border` | Breaking news |

### Typography — `Theme.Typography.*`

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `.display` | 40pt | Bold | Hero numbers |
| `.title1` | 28pt | Bold | Screen titles |
| `.title2` | 24pt | Semibold | Section headers |
| `.title3` | 20pt | Semibold | Sub-sections |
| `.headline` | 18pt | Semibold | List primaries, card titles |
| `.body` | 16pt | Regular | Body copy |
| `.callout` | 16pt | Regular | Secondary body |
| `.subheadline` | 14pt | Regular | Labels, metadata |
| `.footnote` | 14pt | Regular | Captions |
| `.caption1` | 12pt | Regular | Small labels |
| `.caption2` | 12pt | Regular | Timestamps |

### Spacing — `Theme.Spacing.*`

4pt base grid. Named by scale tier (s10 = 4pt, s20 = 8pt, etc.).

| Token | Value | Usage |
|-------|-------|-------|
| `.s10` | 4pt | Icon gaps, tight groupings |
| `.s20` | 8pt | Within components |
| `.s30` | 12pt | Label-to-content |
| `.s40` | 16pt | Standard padding, page margins |
| `.s50` | 20pt | — |
| `.s60` | 24pt | Section gaps |
| `.s70` | 32pt | Large section gaps |
| `.s80` | 44pt | — |
| `.s90` | 48pt | — |
| `.s100` | 64pt | — |

### Radius — `Theme.Radius.*`

| Token | Value | Usage |
|-------|-------|-------|
| `.r10` | 4pt | Tags, small badges |
| `.r20` | 8pt | Compact elements |
| `.default` | 12pt | Buttons, inputs |
| `.r40` | 16pt | Cards |
| `.r50` | 24pt | Large feature cards |
| `.pill` | 80pt | Pills, capsules |
| `.full` | 160pt | Circles, avatars |

### Shadows — `Theme.Shadow.*`

| Token | Blur | Y | Opacity | Usage |
|-------|------|---|---------|-------|
| `.sm` | 2 | 1 | 6% | Subtle lift |
| `.md` | 8 | 2 | 10% | Standard cards |
| `.lg` | 16 | 4 | 12% | Modals, sheets |

Apply with the `.themeShadow()` modifier:

```swift
.themeShadow(Theme.Shadow.md)
```

### Icons — `Theme.Icon.*`

SF Symbol names organised by domain:

| Namespace | Example tokens |
|-----------|---------------|
| `Theme.Icon.Navigation` | `.leagues`, `.profile`, `.notifications`, `.disclosure`, `.add` |
| `Theme.Icon.League` | `.trophy`, `.trophyFill`, `.members`, `.join`, `.create`, `.paid` |
| `Theme.Icon.Pick` | `.gameweek`, `.deadline`, `.timeRemaining`, `.locked`, `.noRepeat` |
| `Theme.Icon.Wallet` | `.empty`, `.topUp`, `.withdrawal`, `.refund`, `.winnings` |
| `Theme.Icon.Action` | `.copy`, `.copied`, `.share` |
| `Theme.Icon.Status` | `.success`, `.failure`, `.error`, `.errorFill`, `.info` |

Usage:

```swift
Image(systemName: Theme.Icon.Status.success)
```

---

## Naming Conventions

| Token type | Pattern | Example |
|------------|---------|---------|
| Colour | `Theme.Color.{Group}.{name}` | `Theme.Color.Primary.resting` |
| Font | `Theme.Typography.{name}` | `Theme.Typography.headline` |
| Spacing | `Theme.Spacing.{name}` | `Theme.Spacing.s40` |
| Radius | `Theme.Radius.{name}` | `Theme.Radius.default` |
| Shadow | `Theme.Shadow.{name}` | `Theme.Shadow.md` |
| Icon | `Theme.Icon.{Group}.{name}` | `Theme.Icon.League.trophy` |

---

## Components

Pre-built components live in `DesignSystem/Components/`. Use these instead of building from scratch.

### Button (.themed)

All action buttons MUST use the `.themed()` modifier. No call-site style overrides are permitted — background, foreground, font, shape, frame, opacity, and clip shape are all owned by the component.

```swift
Button("Join League") { /* action */ }
    .themed(.primary)
```

Variants: `.primary` (yellow), `.secondary` (white 10%), `.destructive` (red), `.ghost` (clear)

```swift
// Full-width loading button
Button("Submitting...") { }
    .themed(.primary, isLoading: true)

// Inline secondary button
Button("Cancel") { dismiss() }
    .themed(.secondary, fullWidth: false)

// Disabled with lock icon
Button {} label: {
    Label("LOCKED", systemImage: Theme.Icon.Pick.locked)
}
.themed(.secondary)
.disabled(true)
```

**Permitted at call site:** `.disabled()`, `.accessibilityLabel()`, `.accessibilityHint()`, label content (text/icons passed to Button's label closure).

**Forbidden at call site:** `.background()`, `.clipShape()`, `.foregroundStyle()`, `.font()`, `.opacity()`, `.frame(height:)`, `.tracking()`, custom gradients, or any visual modifier that overrides the component's styling.

### IconButton

For icon-only action buttons (stats, share, etc.). Encapsulates 44×44 frame, capsule shape, and variant colours.

```swift
IconButton(icon: "chart.bar", action: { showStats() })
IconButton(icon: "square.and.arrow.up", variant: .secondary, action: { share() })
```

### Card

```swift
DSCard {
    VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
        Text("Premier League")
            .font(Theme.Typography.title3)
            .foregroundStyle(Theme.Color.Content.Text.default)
        Text("12 players remaining")
            .font(Theme.Typography.subheadline)
            .foregroundStyle(Theme.Color.Content.Text.disabled)
    }
}
```

Provides `Surface.Background.container` + `Radius.r40` + `Shadow.md` + `Spacing.s40` padding automatically.

### Flag

```swift
Flag(label: "Survived", intent: .success)
Flag(label: "Eliminated", intent: .error)
Flag(label: "Pending", intent: .neutral)
Flag(label: "Void", intent: .warning)
```

Pick status has a convenience mapping via `PickStatus.flagIntent`:

```swift
Flag(
    label: PickStatus.survived.label,
    intent: PickStatus.survived.flagIntent
)
```

### LeagueCard

```swift
LeagueCard(
    leagueName: "Work League",
    memberCount: 8,
    gameweek: 14,
    pickStatus: .survived
)
```

### MatchCard (Component Family)

Match cards display fixture information across different contexts. All variants share the same purple gradient background (`225deg, #5E4E81 0% → #2D253D 72%`), 24px border radius, and `1px rgba(255,255,255,0.1)` stroke.

| Variant | Struct | Location | Size | Context |
|---------|--------|----------|------|---------|
| **Fixture** (pre-match) | `MatchCard` (`.preMatch`) | `DesignSystem/Components/MatchCard.swift` | 446pt | Home — shows picked team, opponent, venue, kickoff, change-pick CTA |
| **Live** | `MatchCard` (`.live`) | `DesignSystem/Components/MatchCard.swift` | 446pt | Home — green gradient, live score, LIVE pill, locked |
| **Result** | `MatchCard` (`.finished`) | `DesignSystem/Components/MatchCard+Result.swift` | 446pt | Home — final score, survived/eliminated badge |
| **Empty** | `MatchCard+Empty` | `DesignSystem/Components/MatchCard+Empty.swift` | 446pt | Home — no pick made yet |
| **Pick Card Large** | `MatchCarouselCard` | `Features/Picks/MatchCarouselCard.swift` | 420pt | Pick screen carousel — two-team matchup, VS circle, PICK HOME/AWAY buttons, stats flip |
| **Pick Card Small** | `FixturePickRow` | `Features/Picks/FixturePickRow.swift` | 212pt | Pick screen list — compact two-team matchup, VS label, HOME/AWAY buttons |

**Key rules:**
- Pick variants (Carousel + List) always show "VS" — never live scores. These are selection cards, not result cards.
- Pick variants show a locked pill (lock icon + "LOCKED") when `isLocked`, replacing the pick buttons entirely.
- Used teams show desaturated badges at 0.4 opacity with "USED GWn" button text.
- The Fixture/Live/Result variants are for displaying a user's existing pick on the Home screen.

### DSTextField

```swift
DSTextField(
    label: "League Name",
    text: $name,
    placeholder: "Enter a name",
    errorMessage: nameError
)
```

---

## Worked Examples

### Example 1: Settings Row

```swift
struct SettingsRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Text(subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
            Spacer()
            Image(systemName: Theme.Icon.Navigation.disclosure)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }
}
```

### Example 2: Deadline Banner

```swift
struct DeadlineBanner: View {
    let timeRemaining: String

    var body: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: Theme.Icon.Pick.deadline)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
            Text("Pick deadline: \(timeRemaining)")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.Status.Warning.subtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }
}
```

---

## Rules for Agents

1. **Never use raw hex values** — always `Theme.Color.*`
2. **Never use `Font.system(...)`** — always `Theme.Typography.*`
3. **Never use magic numbers for spacing** — always `Theme.Spacing.*`
4. **Use DS components** (`Card`, `.themed()`, `IconButton`, etc.) before building custom ones
5. **Use `Theme.Icon.*`** for SF Symbol names — never hardcode strings
6. **Accessibility** — minimum 44pt touch targets, 4.5:1 contrast ratio for text
7. **No call-site overrides on atomic components** — buttons, icon buttons, cards, and inputs define their own visual styling. Call sites pass content and state (label, disabled, loading), never style (background, font, foreground, shape, opacity, frame). This is a core design system principle.
8. **All new components must be added to the design system browser** on the Profile page. Extend existing components where possible. Flag new component proposals to the human.
