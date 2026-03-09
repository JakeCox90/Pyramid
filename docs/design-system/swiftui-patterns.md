# SwiftUI Design Patterns — Agent Skill

> Actionable SwiftUI guidance for the iOS agent. Covers layout, tokens, components, and accessibility.
> Read `docs/design-system/usage-guide.md` first for the full token reference.

---

## Screen Structure

Every screen follows this skeleton:

```swift
struct ExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                mainContent
            }
        }
        .navigationTitle("Title")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s60) {
                // sections here
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}
```

**Rules:**
- `Theme.Color.Surface.Background.page` as root background — never a raw hex
- `Theme.Spacing.s40` for horizontal padding (page margins)
- `Theme.Spacing.s60` between top-level sections
- Loading / error / empty states in every screen — use `Group` to switch
- `.task {}` for async data loading, `.refreshable {}` for pull-to-refresh

---

## Layout Patterns

### Card Section

```swift
VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
    Text("Section Title")
        .font(Theme.Typography.headline)
        .foregroundStyle(Theme.Color.Content.Text.default)

    DSCard {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            // card content
        }
    }
}
```

### List of Items

```swift
VStack(spacing: Theme.Spacing.s20) {
    ForEach(items) { item in
        DSCard {
            HStack(spacing: Theme.Spacing.s30) {
                // row content
            }
        }
    }
}
```

### Stat Badges (horizontal row)

```swift
HStack(spacing: Theme.Spacing.s30) {
    statBadge(label: "Alive", value: "\(count)",
              color: Theme.Color.Status.Success.resting)
    statBadge(label: "Eliminated", value: "\(count)",
              color: Theme.Color.Status.Error.resting)
}

func statBadge(label: String, value: String, color: Color) -> some View {
    DSCard {
        VStack(spacing: Theme.Spacing.s10) {
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
        .frame(maxWidth: .infinity)
    }
}
```

### Empty State

```swift
VStack(spacing: Theme.Spacing.s40) {
    Image(systemName: Theme.Icon.League.members)
        .font(.system(size: 48))
        .foregroundStyle(Theme.Color.Border.default)
    Text("No items yet")
        .font(Theme.Typography.title3)
        .foregroundStyle(Theme.Color.Content.Text.default)
    Text("Create your first item to get started.")
        .font(Theme.Typography.subheadline)
        .foregroundStyle(Theme.Color.Content.Text.disabled)
        .multilineTextAlignment(.center)
}
.padding(.horizontal, Theme.Spacing.s40)
.padding(.top, Theme.Spacing.s70)
```

### Error State

```swift
VStack(spacing: Theme.Spacing.s40) {
    Image(systemName: Theme.Icon.Status.error)
        .font(.system(size: 48))
        .foregroundStyle(Theme.Color.Border.default)
    Text(message)
        .font(Theme.Typography.subheadline)
        .foregroundStyle(Theme.Color.Content.Text.disabled)
        .multilineTextAlignment(.center)
}
.padding(.horizontal, Theme.Spacing.s40)
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

### Sheet / Modal

```swift
.sheet(isPresented: $showSheet) {
    NavigationStack {
        VStack(spacing: Theme.Spacing.s60) {
            // content
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Color.Surface.Background.container)
        .navigationTitle("Sheet Title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showSheet = false }
            }
        }
    }
}
```

---

## Adaptive Colours

All `Theme.Color.*` tokens are adaptive — they automatically resolve to different values for light and dark mode using `UIColor { traits in }` under the hood.

| Element | Token |
|---------|-------|
| Screen background | `Theme.Color.Surface.Background.page` |
| Cards / containers | `Theme.Color.Surface.Background.container` |
| Primary text | `Theme.Color.Content.Text.default` |
| Secondary text | `Theme.Color.Content.Text.subtle` |
| Tertiary / disabled text | `Theme.Color.Content.Text.disabled` |
| Dividers / borders | `Theme.Color.Border.default` |
| Primary accent | `Theme.Color.Primary.resting` |
| Success | `Theme.Color.Status.Success.resting` |
| Error | `Theme.Color.Status.Error.resting` |
| Warning | `Theme.Color.Status.Warning.resting` |

**Never use `.foregroundStyle(.primary)` or `.foregroundColor(.black)`** — these don't adapt to the app's colour scheme.

---

## Component Usage

### Buttons

```swift
// Primary CTA — full width
Button("Join League") { /* action */ }
    .dsStyle(.primary, size: .large)

// Secondary — inline
Button("Cancel") { dismiss() }
    .dsStyle(.secondary, size: .medium, fullWidth: false)

// Destructive
Button("Leave League") { /* action */ }
    .dsStyle(.destructive, size: .large)

// Ghost — minimal
Button("Skip") { /* action */ }
    .dsStyle(.ghost, size: .small, fullWidth: false)

// Loading state
Button("Saving...") { }
    .dsStyle(.primary, size: .large, isLoading: true)
    .disabled(true)
```

### Cards

```swift
// Generic card wrapper — provides container background, r40 radius, md shadow, s40 padding
DSCard {
    Text("Content goes here")
        .font(Theme.Typography.body)
        .foregroundStyle(Theme.Color.Content.Text.default)
}

// Pre-built league card
LeagueCard(
    leagueName: "Office League",
    memberCount: 12,
    gameweek: 14,
    pickStatus: .survived
)
```

### Status Badges

```swift
PickStatusBadge(status: .survived)    // green
PickStatusBadge(status: .eliminated)  // red
PickStatusBadge(status: .pending)     // neutral
PickStatusBadge(status: .void)        // yellow
```

### Text Fields

```swift
DSTextField(
    label: "Email",
    text: $email,
    placeholder: "you@example.com",
    errorMessage: emailError
)
```

---

## Typography Rules

| Usage | Token | Never |
|-------|-------|-------|
| Hero numbers | `Theme.Typography.display` | `Font.system(size: 40)` |
| Screen titles | `Theme.Typography.title1` | `Font.system(size: 28)` |
| Section headers | `Theme.Typography.title2` / `.title3` | `Font.system(size: 24)` |
| List item primary | `Theme.Typography.headline` | `.headline` (system) |
| Body text | `Theme.Typography.body` | `Font.system(size: 16)` |
| Labels / metadata | `Theme.Typography.subheadline` | `Font.system(size: 14)` |
| Small labels | `Theme.Typography.caption1` | `Font.system(size: 12)` |
| Timestamps | `Theme.Typography.caption2` | `Font.system(size: 12)` |

**Always use `Theme.Typography.*`** — never `Font.system(size:weight:)` inline.

---

## Spacing Rules

| Context | Token | Never |
|---------|-------|-------|
| Page horizontal padding | `Theme.Spacing.s40` | `16` |
| Between sections | `Theme.Spacing.s60` | `24` |
| Inside cards | `Theme.Spacing.s40` (handled by DSCard) | `16` |
| Between items in a stack | `Theme.Spacing.s20` / `.s30` | `8` / `12` |
| Icon-to-text gap | `Theme.Spacing.s20` | `8` |
| Tight groupings | `Theme.Spacing.s10` | `4` |

**Never use magic numbers.** Every spacing value must come from `Theme.Spacing`.

---

## Icon Rules

| Context | Token | Never |
|---------|-------|-------|
| Navigation icons | `Theme.Icon.Navigation.*` | Hardcoded `"trophy"` |
| League context | `Theme.Icon.League.*` | Hardcoded `"person.2"` |
| Pick/gameweek | `Theme.Icon.Pick.*` | Hardcoded `"calendar"` |
| Status indicators | `Theme.Icon.Status.*` | Hardcoded `"checkmark.circle.fill"` |
| Wallet | `Theme.Icon.Wallet.*` | Hardcoded `"creditcard"` |
| Actions | `Theme.Icon.Action.*` | Hardcoded `"doc.on.doc"` |

```swift
// Always use tokens
Image(systemName: Theme.Icon.Status.success)
    .foregroundStyle(Theme.Color.Status.Success.resting)

// Never hardcode SF Symbol names in views
Image(systemName: "checkmark.circle.fill")  // ❌
```

---

## Accessibility

### Touch Targets
- Minimum 44x44pt for all interactive elements
- Use `.frame(minWidth: 44, minHeight: 44)` if the visual element is smaller

### Labels
- Every button: `.accessibilityLabel("descriptive action")`
- Every icon-only button: `.accessibilityLabel()` is mandatory
- Status badges: `.accessibilityLabel("Pick status: survived")`
- Decorative images: `.accessibilityHidden(true)`

### Dynamic Type
- `Theme.Typography.*` tokens use `Font.system()` which supports Dynamic Type scaling
- Do not use fixed frames on text containers — let them grow

---

## Anti-Patterns (Do Not Do)

```swift
// ❌ Hardcoded hex colours
private let bgPrimary = Color(hex: "0A0A0A")
// ✅ Use tokens
Theme.Color.Surface.Background.page

// ❌ Magic spacing numbers
VStack(spacing: 16) { ... }
    .padding(.horizontal, 16)
// ✅ Use tokens
VStack(spacing: Theme.Spacing.s40) { ... }
    .padding(.horizontal, Theme.Spacing.s40)

// ❌ Raw font calls
.font(.system(size: 17, weight: .semibold))
// ✅ Use tokens
.font(Theme.Typography.headline)

// ❌ System colours on dark background
.foregroundStyle(.primary)
.foregroundColor(.black)
// ✅ Use Theme text tokens
.foregroundStyle(Theme.Color.Content.Text.default)

// ❌ Building buttons from scratch
Text("Join")
    .padding()
    .background(Color.blue)
    .clipShape(RoundedRectangle(cornerRadius: 12))
// ✅ Use DSButton
Button("Join") { }
    .dsStyle(.primary, size: .large)

// ❌ Custom card containers
.background(Color(hex: "1C1C1E"))
.cornerRadius(16)
.shadow(radius: 8)
// ✅ Use DSCard
DSCard { content }

// ❌ Hardcoded SF Symbol names
Image(systemName: "trophy.fill")
// ✅ Use Theme.Icon
Image(systemName: Theme.Icon.League.trophyFill)
```

---

## Review Checklist

Before submitting any PR with UI changes, verify:

- [ ] No hardcoded hex values — all colours via `Theme.Color.*`
- [ ] No magic spacing numbers — all via `Theme.Spacing.*`
- [ ] No raw `Font.system(...)` — all via `Theme.Typography.*`
- [ ] No hardcoded SF Symbol strings — all via `Theme.Icon.*`
- [ ] DS components used where applicable (DSButton, DSCard, DSTextField, PickStatusBadge)
- [ ] Empty states and error states handled
- [ ] All interactive elements >= 44x44pt touch target
- [ ] Accessibility labels on interactive and status elements
