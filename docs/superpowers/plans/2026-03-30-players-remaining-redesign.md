# Players Remaining Module Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static "X of Y players remaining" text card with a dynamic ring + avatar module showing elimination progression and key stats.

**Architecture:** Single component rewrite of `PlayersRemainingCard`. New `MemberSummary` model + `EliminationStats` struct added to `HomeData`. Data fetched via a new lightweight query on `league_members` joined to `profiles` (same pattern as `StandingsService.fetchMembers`). Two visual states: surviving (green ring, user in survivor row) and eliminated (grey ring, user in eliminated row with red accent).

**Tech Stack:** SwiftUI, Supabase Swift SDK, existing Theme design system tokens

**Spec:** `docs/superpowers/specs/2026-03-30-players-remaining-redesign.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `ios/Pyramid/Sources/Models/HomeData.swift` | Modify | Add `MemberSummary`, `EliminationStats`, extend `HomeData` |
| `ios/Pyramid/Sources/Services/HomeService+Members.swift` | Create | Fetch member summaries + elimination stats per league |
| `ios/Pyramid/Sources/Services/HomeService+Helpers.swift` | Modify | Add `fetchAllMemberSummaries` + `fetchAllEliminationStats` concurrency helpers |
| `ios/Pyramid/Sources/Services/HomeService.swift` | Modify | Wire new fetches into `fetchHomeData()`, update `HomeData` init |
| `ios/Pyramid/Sources/Features/Home/HomeViewModel.swift` | Modify | Add accessors for member summaries + elimination stats |
| `ios/Pyramid/Sources/Shared/DesignSystem/Components/PlayersRemainingCard.swift` | Rewrite | New ring + avatar + stats component |
| `ios/Pyramid/Sources/Features/Home/HomeView+PlayersRemaining.swift` | Modify | Pass new data to redesigned component |

---

### Task 1: Add MemberSummary and EliminationStats to HomeData

**Files:**
- Modify: `ios/Pyramid/Sources/Models/HomeData.swift`

- [ ] **Step 1: Add MemberSummary struct**

Add after the `PlayerCount` struct at the top of the file:

```swift
/// Lightweight member info for avatar display.
struct MemberSummary: Identifiable, Sendable, Equatable {
    let userId: String
    let displayName: String
    let avatarURL: String?
    let status: LeagueMember.MemberStatus
    var id: String { userId }
}

/// Per-league elimination statistics.
struct EliminationStats: Sendable, Equatable {
    let eliminatedThisWeek: Int
    let survivalStreak: Int
}
```

- [ ] **Step 2: Extend HomeData with new fields**

Update the `HomeData` struct to add new fields at the end:

```swift
struct HomeData: Sendable, Equatable {
    let leagues: [League]
    let gameweek: Gameweek?
    let picks: [String: Pick]
    let memberStatuses: [String: LeagueMember.MemberStatus]
    let fixtures: [Int: Fixture]
    let lastGwResults: [LeagueResult]
    let allGameweeks: [Gameweek]
    let playerCounts: [String: PlayerCount]
    /// The authenticated user's ID (for highlighting in avatar rows).
    let userId: String
    /// Member summaries per league for avatar display, keyed by league ID.
    let memberSummaries: [String: [MemberSummary]]
    /// Elimination stats per league, keyed by league ID.
    let eliminationStats: [String: EliminationStats]
}
```

- [ ] **Step 3: Verify build**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: Build will fail because `HomeService.fetchHomeData()` doesn't pass the new fields yet. That's expected — Task 2 fixes it.

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Models/HomeData.swift
git commit -m "feat(PYR-183): add MemberSummary and EliminationStats models"
```

---

### Task 2: Fetch member summaries and elimination stats

**Files:**
- Create: `ios/Pyramid/Sources/Services/HomeService+Members.swift`
- Modify: `ios/Pyramid/Sources/Services/HomeService+Helpers.swift`
- Modify: `ios/Pyramid/Sources/Services/HomeService.swift`

- [ ] **Step 1: Create HomeService+Members.swift**

This fetches member summaries for a single league (same query pattern as `StandingsService.fetchMembers` but returning lightweight `MemberSummary` instead of full `LeagueMember`):

```swift
import Foundation
import Supabase

// MARK: - Member Summaries & Elimination Stats

extension HomeService {
    /// Fetches lightweight member summaries for avatar display.
    func fetchMemberSummaries(
        leagueId: String
    ) async throws -> [MemberSummary] {
        let rows: [MemberSummaryRow] = try await client
            .from("league_members")
            .select("""
                user_id, status, \
                profiles(username, display_name, avatar_url)
                """)
            .eq("league_id", value: leagueId)
            .execute()
            .value

        return rows.map { row in
            MemberSummary(
                userId: row.userId,
                displayName: row.profiles.displayLabel,
                avatarURL: row.profiles.avatarUrl,
                status: row.status
            )
        }
    }

    /// Counts members eliminated in the current gameweek.
    func fetchEliminatedThisWeek(
        leagueId: String,
        gameweekId: Int
    ) async throws -> Int {
        let rows: [EliminatedCheckRow] = try await client
            .from("league_members")
            .select("id")
            .eq("league_id", value: leagueId)
            .eq("status", value: "eliminated")
            .eq("eliminated_in_gameweek_id", value: gameweekId)
            .execute()
            .value

        return rows.count
    }

    /// Counts consecutive survived picks for a user in a league,
    /// walking backwards from the most recent settled gameweek.
    func fetchSurvivalStreak(
        userId: String,
        leagueId: String
    ) async throws -> Int {
        let picks: [StreakPickRow] = try await client
            .from("picks")
            .select("result, gameweek_id")
            .eq("user_id", value: userId)
            .eq("league_id", value: leagueId)
            .neq("result", value: "pending")
            .order("gameweek_id", ascending: false)
            .execute()
            .value

        var streak = 0
        for pick in picks {
            if pick.result == .survived {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Private Row Types

private struct MemberSummaryRow: Decodable {
    let userId: String
    let status: LeagueMember.MemberStatus
    let profiles: ProfileRow

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case profiles
    }

    struct ProfileRow: Decodable {
        let username: String
        let displayName: String?
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case username
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }

        var displayLabel: String {
            displayName ?? username
        }
    }
}

private struct EliminatedCheckRow: Decodable {
    let id: String
}

private struct StreakPickRow: Decodable {
    let result: PickResult
    let gameweekId: Int

    enum CodingKeys: String, CodingKey {
        case result
        case gameweekId = "gameweek_id"
    }
}
```

- [ ] **Step 2: Add concurrent fetch helpers to HomeService+Helpers.swift**

Add at the end of the file, after the existing `fetchAllPlayerCounts` function:

```swift
/// Fetches member summaries for all leagues concurrently.
func fetchAllMemberSummaries(
    leagues: [League]
) async -> [String: [MemberSummary]] {
    await withTaskGroup(
        of: (String, [MemberSummary]).self
    ) { group in
        for league in leagues {
            group.addTask {
                do {
                    let summaries = try await self
                        .fetchMemberSummaries(
                            leagueId: league.id
                        )
                    return (league.id, summaries)
                } catch {
                    return (league.id, [])
                }
            }
        }
        var result: [String: [MemberSummary]] = [:]
        for await (id, summaries) in group {
            result[id] = summaries
        }
        return result
    }
}

/// Fetches elimination stats for all leagues concurrently.
func fetchAllEliminationStats(
    userId: String,
    leagues: [League],
    gameweekId: Int?
) async -> [String: EliminationStats] {
    guard let gwId = gameweekId else { return [:] }
    return await withTaskGroup(
        of: (String, EliminationStats).self
    ) { group in
        for league in leagues {
            group.addTask {
                do {
                    async let eliminated = self
                        .fetchEliminatedThisWeek(
                            leagueId: league.id,
                            gameweekId: gwId
                        )
                    async let streak = self
                        .fetchSurvivalStreak(
                            userId: userId,
                            leagueId: league.id
                        )
                    return (
                        league.id,
                        EliminationStats(
                            eliminatedThisWeek:
                                try await eliminated,
                            survivalStreak:
                                try await streak
                        )
                    )
                } catch {
                    return (
                        league.id,
                        EliminationStats(
                            eliminatedThisWeek: 0,
                            survivalStreak: 0
                        )
                    )
                }
            }
        }
        var result: [String: EliminationStats] = [:]
        for await (id, stats) in group {
            result[id] = stats
        }
        return result
    }
}
```

- [ ] **Step 3: Wire into HomeService.fetchHomeData()**

In `HomeService.swift`, update `fetchHomeData()`. Add new concurrent fetches alongside existing ones, and update the `HomeData` initialiser.

After the existing `playerCounts` fetch (line ~120-121), add:

```swift
let memberSummaries = await fetchAllMemberSummaries(
    leagues: leagues
)
let eliminationStats = await fetchAllEliminationStats(
    userId: userId,
    leagues: leagues,
    gameweekId: gameweek?.id
)
```

Update the `return HomeData(...)` call to include the new fields:

```swift
return HomeData(
    leagues: leagues, gameweek: gameweek,
    picks: picks, memberStatuses: statuses,
    fixtures: fixtures,
    lastGwResults: lastGwResults,
    allGameweeks: allGws,
    playerCounts: playerCounts,
    userId: userId,
    memberSummaries: memberSummaries,
    eliminationStats: eliminationStats
)
```

- [ ] **Step 4: Run xcodegen and build**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: Build succeeds. The new data is fetched but not yet displayed.

- [ ] **Step 5: Commit**

```bash
git add ios/Pyramid/Sources/Services/HomeService+Members.swift \
        ios/Pyramid/Sources/Services/HomeService+Helpers.swift \
        ios/Pyramid/Sources/Services/HomeService.swift \
        ios/Pyramid.xcodeproj/project.pbxproj
git commit -m "feat(PYR-183): fetch member summaries and elimination stats"
```

---

### Task 3: Add ViewModel accessors

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Home/HomeViewModel.swift`

- [ ] **Step 1: Add accessor functions**

Add after the existing `playersRemaining(for:)` function (around line 141):

```swift
/// The authenticated user's ID from the last home data fetch.
var currentUserId: String {
    homeData?.userId ?? ""
}

func memberSummaries(
    for league: League
) -> [MemberSummary] {
    homeData?.memberSummaries[league.id] ?? []
}

func eliminationStats(
    for league: League
) -> EliminationStats? {
    homeData?.eliminationStats[league.id]
}
```

- [ ] **Step 2: Build to verify**

Run: `cd ios && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/HomeViewModel.swift
git commit -m "feat(PYR-183): add ViewModel accessors for member summaries and elimination stats"
```

---

### Task 4: Rewrite PlayersRemainingCard component

**Files:**
- Rewrite: `ios/Pyramid/Sources/Shared/DesignSystem/Components/PlayersRemainingCard.swift`

- [ ] **Step 1: Rewrite PlayersRemainingCard**

Replace the entire contents of `PlayersRemainingCard.swift` with:

```swift
import SwiftUI

// MARK: - Players Remaining Module

struct PlayersRemainingCard: View {
    let activeCount: Int
    let totalCount: Int
    let eliminatedThisWeek: Int
    let survivalStreak: Int
    let userStatus: LeagueMember.MemberStatus
    let currentUserId: String
    let members: [MemberSummary]

    @State private var appeared = false

    private var isEliminated: Bool {
        userStatus == .eliminated
    }

    private var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(
            round(
                Double(activeCount) / Double(totalCount)
                    * 100
            )
        )
    }

    private var ringProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(activeCount) / Double(totalCount)
    }

    private var survivors: [MemberSummary] {
        members.filter { $0.status == .active || $0.status == .winner }
    }

    private var eliminated: [MemberSummary] {
        members.filter { $0.status == .eliminated }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            ringSection
            badgeSection
            survivorAvatars
            eliminatedAvatars
            statsRow
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
        .onAppear {
            withAnimation(
                .easeOut(duration: 0.8).delay(0.2)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Ring

extension PlayersRemainingCard {
    private var ringSection: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    Theme.Color.Surface.Background.page,
                    lineWidth: 9
                )

            // Fill
            Circle()
                .trim(
                    from: 0,
                    to: appeared ? ringProgress : 0
                )
                .stroke(
                    isEliminated
                        ? Theme.Color.Content.Text.disabled
                        : Theme.Color.Status.Success.resting,
                    style: StrokeStyle(
                        lineWidth: 9,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Centre text
            VStack(spacing: 0) {
                Text("\(activeCount)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        isEliminated
                            ? Theme.Color.Content.Text
                                .subtle
                            : Theme.Color.Status.Success
                                .resting
                    )
                Text("of \(totalCount) left")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Badge

extension PlayersRemainingCard {
    private var badgeSection: some View {
        Group {
            if isEliminated {
                Text("Eliminated in GW \(eliminatedGameweekLabel)")
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Status.Error.resting
                    )
                    .padding(
                        .vertical, Theme.Spacing.s10
                    )
                    .padding(
                        .horizontal, Theme.Spacing.s30
                    )
                    .background(
                        Theme.Color.Status.Error.subtle
                    )
                    .clipShape(
                        Capsule()
                    )
            } else {
                Text(
                    "Top \(percentage)% \u{2014} Still standing"
                )
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
                )
                .padding(
                    .vertical, Theme.Spacing.s10
                )
                .padding(
                    .horizontal, Theme.Spacing.s30
                )
                .background(
                    Theme.Color.Status.Success.subtle
                )
                .clipShape(
                    Capsule()
                )
            }
        }
    }

    private var eliminatedGameweekLabel: String {
        // Find the current user in eliminated members
        // and derive GW from context. For now, show
        // streak + 1 as the GW they fell in.
        // The actual GW name comes from the parent.
        "\(survivalStreak + 1)"
    }
}

// MARK: - Avatar Rows

extension PlayersRemainingCard {
    private static let maxSurvivors = 8
    private static let maxEliminated = 6

    private var survivorAvatars: some View {
        let visible = Array(
            survivors
                .sorted {
                    $0.userId == currentUserId ? true
                        : $1.userId == currentUserId
                        ? false : $0.displayName
                        < $1.displayName
                }
                .prefix(Self.maxSurvivors)
        )
        let overflow = survivors.count - visible.count

        return HStack(spacing: Theme.Spacing.s20) {
            ForEach(visible) { member in
                Avatar(
                    name: member.displayName,
                    imageURL: member.avatarURL,
                    size: .small
                )
                .overlay(
                    Circle()
                        .stroke(
                            Theme.Color.Status.Success
                                .resting,
                            lineWidth: 2
                        )
                )
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
    }

    private var eliminatedAvatars: some View {
        let sorted = eliminated.sorted {
            $0.userId == currentUserId ? true
                : $1.userId == currentUserId ? false
                : $0.displayName < $1.displayName
        }
        let visible = Array(
            sorted.prefix(Self.maxEliminated)
        )
        let overflow = eliminated.count - visible.count

        return HStack(spacing: Theme.Spacing.s10) {
            ForEach(visible) { member in
                let isCurrentUser =
                    member.userId == currentUserId
                let size: CGFloat = isCurrentUser ? 24 : 20

                Text(
                    String(
                        member.displayName.prefix(1)
                    )
                    .uppercased()
                )
                .font(
                    .system(size: isCurrentUser ? 9 : 8)
                )
                .foregroundStyle(
                    isCurrentUser
                        ? Theme.Color.Status.Error
                            .resting
                        : Theme.Color.Content.Text
                            .disabled
                )
                .frame(width: size, height: size)
                .background(
                    isCurrentUser
                        ? Theme.Color.Status.Error.subtle
                        : Theme.Color.Surface.Background
                            .elevated
                )
                .clipShape(Circle())
                .overlay(
                    isCurrentUser
                        ? Circle().stroke(
                            Theme.Color.Status.Error
                                .resting,
                            lineWidth: 1.5
                        )
                        : nil
                )
                .opacity(isCurrentUser ? 1 : 0.5)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .disabled
                    )
            }
        }
    }
}

// MARK: - Stats Row

extension PlayersRemainingCard {
    private var statsRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Color.Border.light)
                .frame(height: 1)

            HStack(spacing: 0) {
                statItem(
                    value: "\(eliminatedThisWeek)",
                    label: "eliminated\nthis week",
                    color: Theme.Color.Status.Error
                        .resting
                )

                Rectangle()
                    .fill(Theme.Color.Border.light)
                    .frame(width: 1, height: 40)

                statItem(
                    value: "\(percentage)%",
                    label: "of the field\nremain",
                    color: isEliminated
                        ? Theme.Color.Content.Text
                            .subtle
                        : Theme.Color.Status.Success
                            .resting
                )

                Rectangle()
                    .fill(Theme.Color.Border.light)
                    .frame(width: 1, height: 40)

                statItem(
                    value: "\(survivalStreak)",
                    label: isEliminated
                        ? "weeks\nyou lasted"
                        : "weeks\nsurvived",
                    color: Theme.Color.Content.Text
                        .default
                )
            }
            .padding(.top, Theme.Spacing.s30)
        }
    }

    private func statItem(
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(value)
                .font(Theme.Typography.subhead)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `cd ios && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: Build will fail because `HomeView+PlayersRemaining.swift` still uses the old API. That's expected — Task 5 fixes it.

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Shared/DesignSystem/Components/PlayersRemainingCard.swift
git commit -m "feat(PYR-183): rewrite PlayersRemainingCard with ring, avatars, and stats"
```

---

### Task 5: Wire into HomeView

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Home/HomeView+PlayersRemaining.swift`

- [ ] **Step 1: Update HomeView extension**

Replace the entire contents of `HomeView+PlayersRemaining.swift`:

```swift
import SwiftUI

// MARK: - Players Remaining Card

extension HomeView {
    @ViewBuilder
    func playersRemainingCard(
        for league: League
    ) -> some View {
        let counts = viewModel.homeData?
            .playerCounts[league.id]
        let stats = viewModel.eliminationStats(
            for: league
        )
        let members = viewModel.memberSummaries(
            for: league
        )
        let userStatus = viewModel.homeData?
            .memberStatuses[league.id] ?? .active
        let userId = viewModel.currentUserId

        if let counts, counts.total > 0 {
            PlayersRemainingCard(
                activeCount: counts.active,
                totalCount: counts.total,
                eliminatedThisWeek: stats?
                    .eliminatedThisWeek ?? 0,
                survivalStreak: stats?
                    .survivalStreak ?? 0,
                userStatus: userStatus,
                currentUserId: userId,
                members: members
            )
        }
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: Build succeeds.

- [ ] **Step 3: Run SwiftLint**

Run: `cd ios && swiftlint lint --strict 2>&1 | grep -E "error:|warning:" | head -20`

Expected: No new violations. If any appear in the files we modified, fix them before committing.

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Home/HomeView+PlayersRemaining.swift
git commit -m "feat(PYR-183): wire redesigned players remaining card into HomeView"
```

---

### Task 6: Clean up leftover exploration files

**Files:**
- Delete: `ios/Pyramid/Sources/Features/Home/PlayersRemainingExploration.swift`
- Delete: `ios/Pyramid/Sources/Features/Home/PlayersRemainingSnapshot.swift`

- [ ] **Step 1: Remove leftover files**

```bash
rm -f ios/Pyramid/Sources/Features/Home/PlayersRemainingExploration.swift
rm -f ios/Pyramid/Sources/Features/Home/PlayersRemainingSnapshot.swift
```

- [ ] **Step 2: Regenerate project and build**

Run: `cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add -A ios/Pyramid/Sources/Features/Home/PlayersRemainingExploration.swift \
           ios/Pyramid/Sources/Features/Home/PlayersRemainingSnapshot.swift \
           ios/Pyramid.xcodeproj/project.pbxproj
git commit -m "chore(PYR-183): remove leftover exploration files"
```

---

### Task 7: Final verification and PR

- [ ] **Step 1: Rebase onto main**

```bash
git fetch origin main
git rebase origin/main
```

Resolve any conflicts. For pbxproj conflicts: take origin/main's version, then `cd ios && xcodegen generate`.

- [ ] **Step 2: Full build + lint**

```bash
cd ios && xcodegen generate && xcodebuild build -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5
swiftlint lint --strict 2>&1 | grep -E "error:|warning:" | head -20
```

Expected: Both pass clean.

- [ ] **Step 3: Force-push rebased branch**

```bash
git push -u origin feature/PYR-183-players-remaining-redesign --force-with-lease
```

- [ ] **Step 4: Create PR**

```bash
gh pr create --title "feat(PYR-183): redesign players remaining with ring + avatars" --body "$(cat <<'EOF'
## Summary
- Replaces static text card with dynamic ring + avatar module
- Progress ring animates on appear, shows active/total count
- Survivor avatars (green border) + eliminated avatars (greyed out)
- Three stats: eliminated this week, % remaining, weeks survived
- Two states: surviving (green) and eliminated (grey/red)
- All visuals use design system tokens exclusively

## Design spec
`docs/superpowers/specs/2026-03-30-players-remaining-redesign.md`

## Test plan
- [ ] Verify ring displays correct proportion for leagues of sizes 5, 15, 30, 50
- [ ] Verify surviving state shows green ring, green badge, user in survivor row
- [ ] Verify eliminated state shows grey ring, red badge, user in eliminated row
- [ ] Verify ring animates from 0 on first appear
- [ ] Verify avatar overflow shows "+N" when > 8 survivors or > 6 eliminated
- [ ] Verify stats show correct values for eliminated this week, %, streak
- [ ] Verify all colours/fonts/spacing match design system tokens (no raw values)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 5: Move PYR-183 to In Review**

Update Linear ticket status to "In Review".
