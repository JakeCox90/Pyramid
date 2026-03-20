import SwiftUI

// MARK: - Stats Grid

extension ProfileView {
    func statsGrid(stats: ProfileStats) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.s20
        ) {
            statBadge(
                label: "Leagues",
                value: "\(stats.totalLeaguesJoined)",
                color: Theme.Color.Content.Text.default
            )
            statBadge(
                label: "Wins",
                value: "\(stats.wins)",
                color: Theme.Color.Status.Warning.resting
            )
            statBadge(
                label: "Picks",
                value: "\(stats.totalPicksMade)",
                color: Theme.Color.Content.Text.default
            )
            statBadge(
                label: "Best Streak",
                value: "\(stats.longestSurvivalStreak)",
                color: Theme.Color.Status.Success.resting
            )
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func statBadge(
        label: String,
        value: String,
        color: Color
    ) -> some View {
        DSCard {
            VStack(spacing: Theme.Spacing.s10) {
                Text(value)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(color)
                Text(label)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Active Streaks

extension ProfileView {
    func activeStreaksSection(
        streaks: [LeagueStreak]
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Current Streaks")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .padding(.horizontal, Theme.Spacing.s40)

            VStack(spacing: Theme.Spacing.s10) {
                ForEach(streaks) { streak in
                    streakRow(streak: streak)
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    private func streakRow(streak: LeagueStreak) -> some View {
        DSCard {
            HStack {
                Text(streak.leagueName)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .lineLimit(1)

                Spacer()

                HStack(spacing: Theme.Spacing.s10) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(
                            Theme.Color.Status.Warning.resting
                        )
                        .accessibilityHidden(true)
                    Text("\(streak.currentStreak)")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(
                            Theme.Color.Status.Warning.resting
                        )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Active streak, \(streak.currentStreak) gameweeks")
            }
        }
    }
}

// MARK: - League History

extension ProfileView {
    func leagueHistorySection(
        history: [CompletedLeague]
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("League History")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .padding(.horizontal, Theme.Spacing.s40)

            VStack(spacing: Theme.Spacing.s10) {
                ForEach(history) { league in
                    leagueHistoryRow(league: league)
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    private func leagueHistoryRow(
        league: CompletedLeague
    ) -> some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(league.leagueName)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                        .lineLimit(1)
                    Text("Season \(league.season)")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                }

                Spacer()

                resultBadge(for: league)
            }
        }
    }

    @ViewBuilder
    private func resultBadge(
        for league: CompletedLeague
    ) -> some View {
        switch league.result {
        case .winner:
            Label("Winner", systemImage: "trophy.fill")
                .font(Theme.Typography.caption1)
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
        case .eliminated:
            if let gw = league.eliminatedGameweek {
                Text("Eliminated GW\(gw)")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Status.Error.text
                    )
            } else {
                Text("Eliminated")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Status.Error.text
                    )
            }
        }
    }
}
