# Shared Tension Moments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show post-deadline banners in league detail aggregating pick data into shared narrative moments ("3 players picked Arsenal — all watching nervously").

**Architecture:** Client-side aggregation of existing `lockedPicks` data in `LeagueDetailViewModel`. No backend changes. New `TensionMoment` model, computed property on ViewModel, and `TensionBannerView` UI component integrated into the overview tab.

**Tech Stack:** SwiftUI, existing Theme design system, existing `MemberPick` model

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `ios/Pyramid/Sources/Models/TensionMoment.swift` | Create | Data model for a tension moment (teamId, teamName, pickCount) |
| `ios/Pyramid/Sources/Features/Leagues/TensionBannerView.swift` | Create | UI component rendering tension moment cards |
| `ios/Pyramid/Sources/Features/Leagues/LeagueDetailViewModel.swift` | Modify | Add `tensionMoments` computed property |
| `ios/Pyramid/Sources/Features/Leagues/LeagueDetailView+Standings.swift` | Modify | Integrate tension banners into overview tab |

---

### Task 1: TensionMoment Model

**Files:**
- Create: `ios/Pyramid/Sources/Models/TensionMoment.swift`

- [ ] **Step 1: Create the TensionMoment model**

```swift
import Foundation

struct TensionMoment: Identifiable, Equatable {
    let id: Int
    let teamName: String
    let teamId: Int
    let pickCount: Int

    var flavorText: String {
        switch pickCount {
        case 2:
            return "shared fate"
        case 3:
            return "all watching nervously"
        default:
            return "biggest group at risk"
        }
    }
}
```

- [ ] **Step 2: Run SwiftLint to verify**

Run: `cd ios && swiftlint --path Pyramid/Sources/Models/TensionMoment.swift`
Expected: No violations

- [ ] **Step 3: Run xcodegen and verify build**

Run: `cd ios && xcodegen generate && xcodebuild build -project Pyramid.xcodeproj -scheme Pyramid -destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Models/TensionMoment.swift
git commit -m "feat(PYR-103): add TensionMoment model"
```

---

### Task 2: ViewModel computed property

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Leagues/LeagueDetailViewModel.swift`

**Context:** `lockedPicks` is `[String: MemberPick]` keyed by userId. Each `MemberPick` has `teamId: Int` and `teamName: String`. We group by `teamId`, keep teams with 2+ picks, sort descending by count, cap at 3.

- [ ] **Step 1: Add tensionMoments computed property**

Add this after the `isSurviving` computed property (after line 100) in `LeagueDetailViewModel.swift`:

```swift
    var tensionMoments: [TensionMoment] {
        guard isDeadlinePassed() else { return [] }
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
        .prefix(3)
        .map { $0 }
    }
```

- [ ] **Step 2: Run build to verify**

Run: `cd ios && xcodebuild build -project Pyramid.xcodeproj -scheme Pyramid -destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Leagues/LeagueDetailViewModel.swift
git commit -m "feat(PYR-103): add tensionMoments computed property to LeagueDetailViewModel"
```

---

### Task 3: TensionBannerView UI component

**Files:**
- Create: `ios/Pyramid/Sources/Features/Leagues/TensionBannerView.swift`

**Context:** Follow existing patterns from `LeagueDetailView+Standings.swift`. Use `Theme.Typography`, `Theme.Spacing`, `Theme.Color`, and `Theme.Radius` tokens. The view takes an array of `TensionMoment` and renders compact cards. Use the existing `Card` component pattern (background container, rounded corners) but lighter — no shadow, subtle tint.

- [ ] **Step 1: Create TensionBannerView**

```swift
import SwiftUI

struct TensionBannerView: View {
    let moments: [TensionMoment]

    var body: some View {
        VStack(spacing: Theme.Spacing.s20) {
            ForEach(moments) { moment in
                tensionCard(moment)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func tensionCard(
        _ moment: TensionMoment
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
                .accessibilityHidden(true)

            Text(bannerText(for: moment))
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Status.Warning.resting
                .opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r30
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            accessibilityText(for: moment)
        )
    }

    private func bannerText(
        for moment: TensionMoment
    ) -> String {
        "\(moment.pickCount) players picked \(moment.teamName) — \(moment.flavorText)"
    }

    private func accessibilityText(
        for moment: TensionMoment
    ) -> String {
        "\(moment.pickCount) players picked \(moment.teamName), \(moment.flavorText)"
    }
}
```

- [ ] **Step 2: Run SwiftLint**

Run: `cd ios && swiftlint --path Pyramid/Sources/Features/Leagues/TensionBannerView.swift`
Expected: No violations

- [ ] **Step 3: Run xcodegen and verify build**

Run: `cd ios && xcodegen generate && xcodebuild build -project Pyramid.xcodeproj -scheme Pyramid -destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Leagues/TensionBannerView.swift
git commit -m "feat(PYR-103): add TensionBannerView UI component"
```

---

### Task 4: Integrate into LeagueDetailView overview tab

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Leagues/LeagueDetailView+Standings.swift`

**Context:** The `overviewContent` in `LeagueDetailView+Standings.swift` currently has this structure inside its VStack:
1. gwRecapButton / gwRecapUnavailable
2. myPickCard
3. spectatorBanner (if eliminated)
4. membersList / emptyMembersView
5. activitySection
6. leaveLeagueButton

We insert the tension banners between `spectatorBanner` and the members list. The banners only render when `tensionMoments` is non-empty (the computed property already returns `[]` pre-deadline).

- [ ] **Step 1: Add tension banner section to overviewContent**

In `LeagueDetailView+Standings.swift`, replace the `overviewContent` computed property (lines 86-110):

```swift
    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s40) {
                if viewModel.currentGameweek != nil {
                    if viewModel.isRecapAvailable {
                        gwRecapButton
                    } else {
                        gwRecapUnavailable
                    }
                }
                myPickCard
                if viewModel.isCurrentUserEliminated {
                    spectatorBanner
                }
                if !viewModel.tensionMoments.isEmpty {
                    TensionBannerView(
                        moments: viewModel.tensionMoments
                    )
                }
                if viewModel.members.isEmpty {
                    emptyMembersView
                } else {
                    membersList
                }
                activitySection
                leaveLeagueButton
            }
            .padding(.vertical, Theme.Spacing.s20)
        }
    }
```

- [ ] **Step 2: Run SwiftLint on modified file**

Run: `cd ios && swiftlint --path Pyramid/Sources/Features/Leagues/LeagueDetailView+Standings.swift`
Expected: No violations

- [ ] **Step 3: Run full build**

Run: `cd ios && xcodegen generate && xcodebuild build -project Pyramid.xcodeproj -scheme Pyramid -destination "platform=iOS Simulator,name=iPhone 16,OS=18.2" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run SwiftLint across all modified/new files**

Run: `cd ios && swiftlint --strict`
Expected: No violations

- [ ] **Step 5: Commit**

```bash
git add ios/Pyramid/Sources/Features/Leagues/LeagueDetailView+Standings.swift
git commit -m "feat(PYR-103): integrate tension banners into league detail overview"
```

---

## Self-Review

**Spec coverage:**
- Post-deadline banners with aggregated pick data: Task 2 (computed property with `isDeadlinePassed()` guard) + Task 4 (integration)
- Tension text variants by count: Task 1 (`flavorText` property)
- Max 3 banners: Task 2 (`.prefix(3)`)
- Teams with 2+ picks only: Task 2 (`guard picks.count >= 2`)
- Anti-collusion (post-deadline only): Task 2 (`guard isDeadlinePassed()`)
- No individual player names shown: Task 3 (only shows count + team name)
- Empty state (no banners if no shared picks): Task 4 (`if !viewModel.tensionMoments.isEmpty`)

**Placeholder scan:** No TBDs, TODOs, or vague steps found. All code blocks are complete.

**Type consistency:** `TensionMoment` used consistently across all tasks. `tensionMoments` property name matches between Task 2 (ViewModel) and Task 4 (View integration). `flavorText` defined in Task 1, used in Task 3.
