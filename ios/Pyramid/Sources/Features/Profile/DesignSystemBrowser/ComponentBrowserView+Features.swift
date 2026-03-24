#if DEBUG
import SwiftUI

// MARK: - Match Tab

extension ComponentBrowserView {
    var matchContent: some View {
        Group {
            teamBadgeSection
            teamsUsedPillSection
            confettiSection
            matchCardSection
            pickCarouselCardSection
            pickListCardSection
            statsCardSection
            resultCardSection
        }
    }
}

// MARK: - TeamBadge

extension ComponentBrowserView {
    var teamBadgeSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "TeamBadge")

            HStack(spacing: Theme.Spacing.s30) {
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Arsenal",
                        logoURL: nil,
                        size: 64
                    )
                    Text("64pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Chelsea",
                        logoURL: nil,
                        size: 48
                    )
                    Text("48pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Liverpool",
                        logoURL: nil,
                        size: 36
                    )
                    Text("36pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Unknown FC",
                        logoURL: nil,
                        size: 36
                    )
                    Text("fallback")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
            }
        }
    }
}

// MARK: - TeamsUsedPill

extension ComponentBrowserView {
    var teamsUsedPillSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "TeamsUsedPill")

            TeamsUsedPill(
                teamNames: [
                    "Arsenal", "Chelsea", "Liverpool"
                ],
                count: 3
            )
            TeamsUsedPill(
                teamNames: [
                    "Arsenal", "Chelsea", "Liverpool",
                    "Tottenham", "Man City", "Everton"
                ],
                count: 6
            )
        }
    }
}

// MARK: - ConfettiView

extension ComponentBrowserView {
    var confettiSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "ConfettiView")

            ZStack {
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
                .fill(
                    Theme.Color.Surface.Background
                        .container
                )
                .frame(height: 160)

                ConfettiView()
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}

// MARK: - MatchCard

extension ComponentBrowserView {
    var matchCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "MatchCard")

            // --- Variant: Pre-Game ---
            ComponentCaption(
                text: "Pre-Game (unlocked)"
            )
            MatchCard(
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                venue: "Emirates Stadium",
                kickoff: Calendar.current.date(
                    bySettingHour: 15,
                    minute: 0,
                    second: 0,
                    of: Date()
                        .addingTimeInterval(86400)
                ),
                broadcast: FixtureMetadata
                    .broadcastNote,
                phase: .preMatch,
                buttonTitle: "CHANGE PICK",
                onButtonTap: {}
            )

            ComponentCaption(
                text: "Pre-Game (locked)"
            )
            MatchCard(
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                venue: "Emirates Stadium",
                kickoff: Calendar.current.date(
                    bySettingHour: 15,
                    minute: 0,
                    second: 0,
                    of: Date()
                ),
                broadcast: FixtureMetadata
                    .broadcastNote,
                phase: .preMatch,
                isLocked: true
            )

            // --- Variant: In Progress ---
            ComponentCaption(
                text: "In Progress (0-0)"
            )
            MatchCard(
                pickedTeamName: "Liverpool",
                pickedTeamLogo: nil,
                opponentName: "Chelsea",
                homeTeamName: "Liverpool",
                homeScore: 0,
                awayScore: 0,
                phase: .live
            )

            ComponentCaption(
                text: "In Progress (2-1)"
            )
            MatchCard(
                pickedTeamName: "Liverpool",
                pickedTeamLogo: nil,
                opponentName: "Chelsea",
                homeTeamName: "Liverpool",
                homeScore: 2,
                awayScore: 1,
                phase: .live
            )

            // --- Variant: Full Time — Survived ---
            ComponentCaption(
                text: "Full Time — Survived"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 3,
                awayScore: 0,
                phase: .finished,
                survived: true,
                isLocked: true
            )

            // --- Variant: Full Time — Eliminated ---
            ComponentCaption(
                text: "Full Time — Eliminated"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 1,
                awayScore: 2,
                phase: .finished,
                survived: false,
                isLocked: true
            )

            // --- Variant: Full Time — Pending ---
            ComponentCaption(
                text: "Full Time — Pending"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 1,
                awayScore: 1,
                phase: .finished,
                isLocked: true
            )

            // --- Variant: Empty ---
            ComponentCaption(
                text: "Empty (no pick)"
            )
            MatchCard.empty(
                isLocked: false,
                onMakePick: {}
            )

            ComponentCaption(
                text: "Empty (locked)"
            )
            MatchCard.empty(isLocked: true)
        }
    }
}

// MARK: - Toast

extension ComponentBrowserView {
    var toastSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "Toast")

            Toast(config: ToastConfiguration(
                icon: "trophy.fill",
                title: "Achievement Unlocked",
                subtitle: "You earned a new badge",
                style: .success
            ))

            Toast(config: ToastConfiguration(
                icon: "exclamationmark.triangle",
                title: "Connection Lost",
                style: .warning
            ))
        }
    }
}

// MARK: - IconBadge

extension ComponentBrowserView {
    var iconBadgeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "IconBadge")

            ComponentCaption(text: "Active badges")
            HStack(spacing: Theme.Spacing.s20) {
                IconBadge(config: IconBadgeConfiguration(
                    icon: "shield.fill",
                    label: "Survivor",
                    tier: 1,
                    style: .success
                ))
                IconBadge(config: IconBadgeConfiguration(
                    icon: "trophy.fill",
                    label: "Champion",
                    tier: 2,
                    style: .warning
                ))
            }

            ComponentCaption(text: "Locked badge")
            IconBadge(config: IconBadgeConfiguration(
                icon: "lock.fill",
                label: "Locked",
                isActive: false,
                style: .neutral
            ))
        }
    }
}

// MARK: - DetailSheet

extension ComponentBrowserView {
    var detailSheetSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "DetailSheet")

            DetailSheet(config: DetailSheetConfiguration(
                icon: "flame.fill",
                iconStyle: .warning,
                title: "Iron Wall",
                subtitle: "Survive 5 consecutive gameweeks",
                metadata: [
                    ("Unlocked", "March 23, 2026"),
                    ("League", "Office League"),
                ],
                body: "You survived 5 gameweeks in a row without being eliminated."
            ))
        }
    }
}

#endif
