import SwiftUI

/// Hero card at the top of the Home tab showing the user's overall survival summary.
struct HeroStatusCard: View {
    let data: HomeData

    private var aliveCount: Int {
        data.memberStatuses.values.filter { $0 == .active }.count
    }

    private var eliminatedCount: Int {
        data.memberStatuses.values.filter { $0 == .eliminated }.count
    }

    private var picksNeeded: Int {
        data.leagues.filter { league in
            data.picks[league.id] == nil
                && data.memberStatuses[league.id] == .active
        }.count
    }

    private var isAllEliminated: Bool {
        !data.leagues.isEmpty && aliveCount == 0
    }

    private var hasNoLeagues: Bool {
        data.leagues.isEmpty
    }

    var body: some View {
        Group {
            if hasNoLeagues {
                noLeaguesCard
            } else if isAllEliminated {
                eliminatedCard
            } else {
                aliveCard
            }
        }
    }

    // MARK: - Alive State

    private var aliveCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            aliveHeader

            HStack(spacing: Theme.Spacing.s40) {
                statBadge(
                    value: picksNeeded,
                    label: picksNeeded == 1 ? "pick needed" : "picks needed",
                    color: Theme.Color.Status.Warning.resting
                )
                statBadge(
                    value: eliminatedCount,
                    label: "eliminated",
                    color: Theme.Color.Status.Error.resting
                )
            }

            if let gameweek = data.gameweek {
                Text(gameweek.name)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(Theme.Spacing.s50)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(aliveGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
    }

    private var aliveHeader: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Circle()
                .fill(Theme.Color.Status.Success.resting)
                .frame(width: 10, height: 10)
            Text("Alive in \(aliveCount) league\(aliveCount == 1 ? "" : "s")")
                .font(Theme.Typography.title3)
                .foregroundStyle(.white)
        }
    }

    private var aliveGradient: some View {
        LinearGradient(
            colors: [
                Theme.Color.Surface.Background.container,
                Theme.Color.Primary.resting
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Eliminated State

    private var eliminatedCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            HStack(spacing: Theme.Spacing.s20) {
                Image(systemName: Theme.Icon.Status.failure)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
                Text("Eliminated")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }

            Text(
                "You've been knocked out of all your leagues. "
                + "Join a new one to get back in the game."
            )
            .font(Theme.Typography.subheadline)
            .foregroundStyle(Theme.Color.Content.Text.subtle)

            if let gameweek = data.gameweek {
                Text(gameweek.name)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
        }
        .padding(Theme.Spacing.s50)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(eliminatedGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
    }

    private var eliminatedGradient: some View {
        LinearGradient(
            colors: [
                Theme.Color.Surface.Background.container,
                Theme.Color.Status.Error.subtle
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - No Leagues State

    private var noLeaguesCard: some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: Theme.Icon.League.trophy)
                .font(.system(size: 32))
                .foregroundStyle(Theme.Color.Primary.resting)

            Text("Join a league to get started")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text("Create or join a league from the Leagues tab.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.s50)
        .frame(maxWidth: .infinity)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
    }

    // MARK: - Stat Badge

    private func statBadge(
        value: Int,
        label: String,
        color: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.s10) {
            Text("\(value)")
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(Theme.Typography.caption1)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, Theme.Spacing.s30)
        .padding(.vertical, Theme.Spacing.s10)
        .background(color.opacity(0.3))
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.pill)
        )
    }
}
