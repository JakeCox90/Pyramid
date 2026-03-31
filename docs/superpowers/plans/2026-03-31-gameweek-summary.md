# Gameweek Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken per-league overlay system with a unified Gameweek Summary carousel overlay and per-league result cards on the homepage.

**Architecture:** New `GameweekSummaryItem` model aggregates settled results per league. `HomeViewModel` builds these items and controls a single `showGameweekSummary` flag. A `GameweekSummaryView` overlay presents a horizontal card carousel. A compact `GameweekResultCard` replaces both `EliminationCard` and stale match cards on the homepage post-settlement.

**Tech Stack:** SwiftUI, iOS 17+ `scrollTargetBehavior(.paging)`, UserDefaults for one-shot auto-show

**Spec:** `docs/superpowers/specs/2026-03-31-gameweek-summary-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `ios/Pyramid/Sources/Models/GameweekSummaryItem.swift` | Create | Data model for one league's settled result |
| `ios/Pyramid/Sources/Features/Home/GameweekSummaryView.swift` | Create | Full-screen overlay with card carousel |
| `ios/Pyramid/Sources/Features/Home/GameweekResultCard.swift` | Create | Compact homepage result card |
| `ios/Pyramid/Sources/Features/Home/HomeViewModel.swift` | Modify | Add `showGameweekSummary`, `gameweekSummaryItems`, `summaryStartIndex` |
| `ios/Pyramid/Sources/Features/Home/HomeViewModel+Helpers.swift` | Modify | Add `buildSummaryItems()` method |
| `ios/Pyramid/Sources/Features/Home/HomeView.swift` | Modify | Remove old overlay state/modifiers, add summary fullScreenCover, update `leaguePageContent` |
| `ios/Pyramid/Sources/Features/Home/HomeView+Elimination.swift` | Modify | Remove `checkForElimination`, keep `eliminationSection` for pre-settlement |
| `ios/Pyramid/Sources/Features/Home/HomeView+Survival.swift` | Modify | Remove `checkForSurvival`, keep `survivalSection` for pre-settlement |
| `ios/Pyramid/Sources/Shared/DesignSystem/Components/SurvivalOverlay.swift` | Delete | Replaced by GameweekSummaryView |
| `ios/Pyramid/Sources/Shared/DesignSystem/Components/EliminationOverlay.swift` | Delete | Replaced by GameweekSummaryView |

---

## Task 1: Create GameweekSummaryItem Model

**Files:**
- Create: `ios/Pyramid/Sources/Models/GameweekSummaryItem.swift`

- [ ] **Step 1: Create the model file**

```swift
import Foundation

/// One league's settled result for the Gameweek Summary overlay and homepage result card.
struct GameweekSummaryItem: Identifiable, Equatable {
    let leagueId: String
    let leagueName: String
    let result: SummaryResult
    let pickedTeamName: String
    let opponentName: String
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    let pickedHome: Bool
    let survivalStreak: Int
    let playersRemaining: Int
    let totalPlayers: Int

    var id: String { leagueId }

    enum SummaryResult: Equatable {
        case survived
        case eliminated
    }

    /// The picked team's logo URL.
    var pickedTeamLogo: String? {
        pickedHome ? homeTeamLogo : awayTeamLogo
    }
}
```

- [ ] **Step 2: Run build to verify it compiles**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Models/GameweekSummaryItem.swift
git commit -m "feat(gameweek-summary): add GameweekSummaryItem model"
```

---

## Task 2: Add Summary Builder to HomeViewModel

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Home/HomeViewModel+Helpers.swift`
- Modify: `ios/Pyramid/Sources/Features/Home/HomeViewModel.swift`

- [ ] **Step 1: Add buildSummaryItems method to HomeViewModel+Helpers.swift**

Add this extension at the end of `HomeViewModel+Helpers.swift`:

```swift
// MARK: - Gameweek Summary Builder

extension HomeViewModel {
    /// Builds summary items for all leagues that have settled results.
    func buildSummaryItems() -> [GameweekSummaryItem] {
        guard let data = homeData else { return [] }
        let results = data.lastGwResults

        return data.leagues.compactMap { league in
            // Find a result for this league (survived or eliminated)
            guard let result = results.first(where: {
                $0.leagueId == league.id
            }) else { return nil }

            let summaryResult: GameweekSummaryItem.SummaryResult
            switch result.result {
            case .survived:
                summaryResult = .survived
            case .eliminated:
                summaryResult = .eliminated
            default:
                return nil
            }

            let counts = data.playerCounts[league.id]
            let stats = data.eliminationStats[league.id]

            return GameweekSummaryItem(
                leagueId: league.id,
                leagueName: result.leagueName,
                result: summaryResult,
                pickedTeamName: result.teamName,
                opponentName: result.pickedHome
                    ? result.awayTeamName
                    : result.homeTeamName,
                homeTeamName: result.homeTeamName,
                homeTeamShort: result.homeTeamShort,
                homeTeamLogo: result.homeTeamLogo,
                awayTeamName: result.awayTeamName,
                awayTeamShort: result.awayTeamShort,
                awayTeamLogo: result.awayTeamLogo,
                homeScore: result.homeScore,
                awayScore: result.awayScore,
                pickedHome: result.pickedHome,
                survivalStreak: stats?.survivalStreak ?? 0,
                playersRemaining: counts?.active ?? 0,
                totalPlayers: counts?.total ?? 0
            )
        }
    }
}
```

- [ ] **Step 2: Add published properties to HomeViewModel.swift**

In `HomeViewModel.swift`, add these three published properties after the existing `@Published var selectedLeague: League?` line:

```swift
@Published var showGameweekSummary = false
@Published var gameweekSummaryItems: [GameweekSummaryItem] = []
@Published var summaryStartIndex: Int = 0
```

- [ ] **Step 3: Add summary trigger logic to load()**

In `HomeViewModel.swift`, inside `load()`, after the `updatePolling()` and `startCountdown()` calls (after line 69), add:

```swift
// Build gameweek summary and auto-show if first time
gameweekSummaryItems = buildSummaryItems()
if gameweekPhase == .finished,
   !gameweekSummaryItems.isEmpty,
   let gwId = homeData?.gameweek?.id {
    let key = "gw_summary_seen_\(gwId)"
    if !UserDefaults.standard.bool(forKey: key) {
        UserDefaults.standard.set(true, forKey: key)
        summaryStartIndex = 0
        showGameweekSummary = true
    }
}
```

- [ ] **Step 4: Add helper to open summary for a specific league**

Add this method to `HomeViewModel.swift` after the `selectLeague` method:

```swift
/// Opens the Gameweek Summary overlay scrolled to a specific league.
func showSummary(for leagueId: String) {
    if let index = gameweekSummaryItems.firstIndex(
        where: { $0.leagueId == leagueId }
    ) {
        summaryStartIndex = index
    }
    showGameweekSummary = true
}
```

- [ ] **Step 5: Run build to verify it compiles**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/HomeViewModel.swift ios/Pyramid/Sources/Features/Home/HomeViewModel+Helpers.swift
git commit -m "feat(gameweek-summary): add summary builder and trigger logic to HomeViewModel"
```

---

## Task 3: Create GameweekSummaryView (Overlay)

**Files:**
- Create: `ios/Pyramid/Sources/Features/Home/GameweekSummaryView.swift`

- [ ] **Step 1: Create the overlay view**

```swift
import SwiftUI

/// Full-screen overlay with a horizontal card carousel showing
/// the user's gameweek results across all leagues.
struct GameweekSummaryView: View {
    let items: [GameweekSummaryItem]
    let startIndex: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0

    private let dismissThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Dimmed background — tap to dismiss
            Color.black.opacity(appeared ? 0.7 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: Theme.Spacing.s40) {
                Spacer()
                carousel
                pageIndicator
                Spacer()
            }
            .offset(y: dragOffset)
            .gesture(swipeToDismiss)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1 : 0)
        }
        .background(.clear)
        .onAppear {
            currentIndex = startIndex
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
            ) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Carousel

extension GameweekSummaryView {
    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Theme.Spacing.s30) {
                ForEach(
                    Array(items.enumerated()),
                    id: \.element.id
                ) { index, item in
                    summaryCard(item)
                        .containerRelativeFrame(
                            .horizontal,
                            count: 1,
                            spacing: Theme.Spacing.s30
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(
            id: Binding(
                get: { items[safe: currentIndex]?.id },
                set: { newId in
                    if let newId,
                       let idx = items.firstIndex(
                           where: { $0.id == newId }
                       ) {
                        currentIndex = idx
                    }
                }
            )
        )
        .contentMargins(.horizontal, Theme.Spacing.s40)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: Theme.Spacing.s10) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == currentIndex
                                ? Theme.Color.Content.Text.default
                                : Theme.Color.Content.Text.disabled
                        )
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Summary Card

extension GameweekSummaryView {
    private func summaryCard(
        _ item: GameweekSummaryItem
    ) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            // League name
            Text(item.leagueName)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            // Result icon
            Image(
                systemName: item.result == .survived
                    ? "checkmark.seal.fill"
                    : "xmark.seal.fill"
            )
            .font(.system(size: 60))
            .foregroundStyle(resultColor(item))
            .shadow(
                color: resultShadow(item),
                radius: 20
            )

            // Result title
            Text(
                item.result == .survived
                    ? "SURVIVED"
                    : "ELIMINATED"
            )
            .font(Theme.Typography.h2)
            .foregroundStyle(resultColor(item))

            // Score block
            scoreBlock(item)

            // Supporting pills
            HStack(spacing: Theme.Spacing.s20) {
                pill(
                    text: item.result == .survived
                        ? "Streak: \(item.survivalStreak)"
                        : "Streak ended",
                    color: resultColor(item)
                )
                pill(
                    text: "\(item.playersRemaining) of \(item.totalPlayers) left",
                    color: Theme.Color.Content.Text.subtle
                )
            }
        }
        .padding(.vertical, Theme.Spacing.s60)
        .padding(.horizontal, Theme.Spacing.s40)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
        )
    }

    private func scoreBlock(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: 0) {
            // Home side
            HStack(spacing: Theme.Spacing.s20) {
                TeamBadge(
                    teamName: item.homeTeamName,
                    logoURL: item.homeTeamLogo,
                    size: 32
                )
                Text(item.homeTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Score
            HStack(spacing: Theme.Spacing.s10) {
                if item.pickedHome {
                    pickDot(item)
                }
                Text("\(item.homeScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .monospacedDigit()
                Text("\u{2013}")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                Text("\(item.awayScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .monospacedDigit()
                if !item.pickedHome {
                    pickDot(item)
                }
            }

            // Away side
            HStack(spacing: Theme.Spacing.s20) {
                Spacer()
                Text(item.awayTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                TeamBadge(
                    teamName: item.awayTeamName,
                    logoURL: item.awayTeamLogo,
                    size: 32
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func pickDot(
        _ item: GameweekSummaryItem
    ) -> some View {
        Image(
            systemName: item.result == .survived
                ? "checkmark.circle.fill"
                : "xmark.circle.fill"
        )
        .font(.system(size: 14))
        .foregroundStyle(resultColor(item))
    }

    private func pill(
        text: String,
        color: Color
    ) -> some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s20)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func resultColor(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    private func resultShadow(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? .green.opacity(0.6)
            : .red.opacity(0.6)
    }
}

// MARK: - Swipe to Dismiss Gesture

extension GameweekSummaryView {
    private var swipeToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

- [ ] **Step 2: Run build to verify it compiles**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/GameweekSummaryView.swift
git commit -m "feat(gameweek-summary): add GameweekSummaryView overlay with card carousel"
```

---

## Task 4: Create GameweekResultCard (Homepage)

**Files:**
- Create: `ios/Pyramid/Sources/Features/Home/GameweekResultCard.swift`

- [ ] **Step 1: Create the compact homepage result card**

```swift
import SwiftUI

/// Compact result card shown per-league on the homepage after settlement.
/// Tapping opens the Gameweek Summary overlay at this league's position.
struct GameweekResultCard: View {
    let item: GameweekSummaryItem
    let onTap: () -> Void

    private var isSurvived: Bool {
        item.result == .survived
    }

    private var resultColor: Color {
        isSurvived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.s30) {
                // Result icon
                Image(
                    systemName: isSurvived
                        ? "checkmark.seal.fill"
                        : "xmark.seal.fill"
                )
                .font(.system(size: 32))
                .foregroundStyle(resultColor)

                // Text stack
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s10
                ) {
                    Text(isSurvived ? "Survived" : "Eliminated")
                        .font(Theme.Typography.h4)
                        .foregroundStyle(resultColor)

                    Text(pickSummary)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
            .padding(Theme.Spacing.s40)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r50
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var pickSummary: String {
        "You picked \(item.pickedTeamName) vs \(item.opponentName) \(item.homeScore)-\(item.awayScore)"
    }
}
```

- [ ] **Step 2: Run build to verify it compiles**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/GameweekResultCard.swift
git commit -m "feat(gameweek-summary): add GameweekResultCard for homepage"
```

---

## Task 5: Integrate into HomeView — Remove Old Overlays

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Home/HomeView.swift`
- Modify: `ios/Pyramid/Sources/Features/Home/HomeView+Elimination.swift`
- Modify: `ios/Pyramid/Sources/Features/Home/HomeView+Survival.swift`

- [ ] **Step 1: Remove old overlay state from HomeView.swift**

Remove these four state properties from `HomeView`:

```swift
// DELETE these lines:
@State var showEliminationOverlay = false
@State var eliminationOverlayResult: LeagueResult?
@State var showSurvivalOverlay = false
@State var survivalOverlayResult: LeagueResult?
```

- [ ] **Step 2: Remove the two .fullScreenCover modifiers and .onChange handler from HomeView.swift body**

Remove the entire `.fullScreenCover(isPresented: $showEliminationOverlay)` block (lines 32-51 in the current file).

Remove the entire `.fullScreenCover(isPresented: $showSurvivalOverlay)` block (lines 52-71 in the current file).

Remove the `.onChange(of: viewModel.homeData)` block (lines 72-77 in the current file) that calls `checkForElimination` and `checkForSurvival`.

- [ ] **Step 3: Add the new .fullScreenCover for GameweekSummaryView**

In `HomeView.swift`, add this modifier in the NavigationStack body (where the old fullScreenCover modifiers were):

```swift
.fullScreenCover(
    isPresented: $viewModel.showGameweekSummary
) {
    GameweekSummaryView(
        items: viewModel.gameweekSummaryItems,
        startIndex: viewModel.summaryStartIndex,
        onDismiss: {
            viewModel.showGameweekSummary = false
        }
    )
    .background(.clear)
    .presentationBackground(.clear)
}
```

- [ ] **Step 4: Update leaguePageContent to use GameweekResultCard**

In `HomeView.swift`, replace the current conditional block inside `leaguePageContent` that starts with `if viewModel.isEliminated(in: league)`. The new version:

```swift
func leaguePageContent(
    _ league: League
) -> some View {
    ScrollView(showsIndicators: false) {
        VStack(spacing: Theme.Spacing.s40) {
            // Post-settlement: show result card
            if let summaryItem = viewModel
                .gameweekSummaryItems
                .first(where: { $0.leagueId == league.id }) {
                GameweekResultCard(item: summaryItem) {
                    viewModel.showSummary(
                        for: league.id
                    )
                }
            // Pre-settlement: existing cards
            } else if viewModel.isEliminated(in: league) {
                eliminationSection(for: league)
            } else if let context = viewModel
                .currentPick(for: league) {
                matchCard(context)
                    .opacity(matchCardVisible ? 1 : 0)
                    .offset(
                        y: matchCardVisible ? 0 : 20
                    )
            } else {
                matchCardEmpty()
            }

            playersRemainingCard(for: league)

            previousPicksSection(for: league)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.bottom, Theme.Spacing.s80)
    }
    .refreshable { await viewModel.load() }
}
```

- [ ] **Step 5: Remove checkForElimination from HomeView+Elimination.swift**

Delete the entire `checkForElimination(data:)` method (lines 9-36). Keep `eliminationSection(for:)` and `eliminationFallback(for:)` — they are still used for pre-settlement eliminated state.

- [ ] **Step 6: Remove checkForSurvival from HomeView+Survival.swift**

Delete the entire `checkForSurvival(data:)` method (lines 9-40). Keep `survivalSection(for:)` — it is still used for pre-settlement survival state.

- [ ] **Step 7: Run build to verify it compiles**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/HomeView.swift ios/Pyramid/Sources/Features/Home/HomeView+Elimination.swift ios/Pyramid/Sources/Features/Home/HomeView+Survival.swift
git commit -m "feat(gameweek-summary): integrate overlay and result card into HomeView, remove old overlay system"
```

---

## Task 6: Delete Old Overlay Files

**Files:**
- Delete: `ios/Pyramid/Sources/Shared/DesignSystem/Components/SurvivalOverlay.swift`
- Delete: `ios/Pyramid/Sources/Shared/DesignSystem/Components/EliminationOverlay.swift`

- [ ] **Step 1: Check for any remaining references to the old overlays**

Run: `grep -r "SurvivalOverlay\|EliminationOverlay" ios/Pyramid/Sources/ --include="*.swift" -l`

Expected: No results (the references in HomeView.swift were removed in Task 5). If any remain in design system browser or preview files, remove those references too.

- [ ] **Step 2: Delete the files**

```bash
rm ios/Pyramid/Sources/Shared/DesignSystem/Components/SurvivalOverlay.swift
rm ios/Pyramid/Sources/Shared/DesignSystem/Components/EliminationOverlay.swift
```

- [ ] **Step 3: Run build to verify nothing breaks**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED. If it fails because the design system browser references these types, remove those references.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(gameweek-summary): delete SurvivalOverlay and EliminationOverlay — replaced by GameweekSummaryView"
```

---

## Task 7: Update Design System Browser References

**Files:**
- Modify: Any design system browser files that reference `SurvivalOverlay`, `EliminationOverlay`, `SurvivalCard`, or `EliminationCard`

- [ ] **Step 1: Search for references**

Run: `grep -r "SurvivalOverlay\|EliminationOverlay\|SurvivalCard\|EliminationCard" ios/Pyramid/Sources/Features/Profile/DesignSystemBrowser/ --include="*.swift" -l`

- [ ] **Step 2: Update or remove references as needed**

For any file found:
- If it previews `SurvivalOverlay` or `EliminationOverlay`, remove those preview entries
- If it previews `SurvivalCard` or `EliminationCard`, these still exist so keep them (they remain useful for the pre-settlement display)
- Add preview entries for `GameweekSummaryView` and `GameweekResultCard` if appropriate

- [ ] **Step 3: Run build to verify**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(gameweek-summary): update design system browser for new components"
```

---

## Task 8: Final Verification

- [ ] **Step 1: Clean build**

Run: `cd ios && xcodegen generate && xcodebuild clean build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Verify no references to removed overlay trigger functions**

Run: `grep -r "checkForElimination\|checkForSurvival\|showEliminationOverlay\|showSurvivalOverlay\|eliminationOverlayResult\|survivalOverlayResult" ios/Pyramid/Sources/ --include="*.swift"`
Expected: No results

- [ ] **Step 3: Verify new components are present**

Run: `find ios/Pyramid/Sources -name "GameweekSummary*" -o -name "GameweekResult*" | sort`
Expected:
```
ios/Pyramid/Sources/Features/Home/GameweekResultCard.swift
ios/Pyramid/Sources/Features/Home/GameweekSummaryView.swift
ios/Pyramid/Sources/Models/GameweekSummaryItem.swift
```

- [ ] **Step 4: Verify old overlay files are deleted**

Run: `find ios/Pyramid/Sources -name "SurvivalOverlay*" -o -name "EliminationOverlay*"`
Expected: No results

- [ ] **Step 5: Run SwiftLint**

Run: `cd ios && swiftlint lint --strict 2>&1 | grep "error\|warning" | head -20`
Expected: No errors or warnings in the new/modified files
