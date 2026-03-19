import SwiftUI

// MARK: - Leagues Section

extension HomeView {
    func leaguesSection(_ data: HomeData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            Text("Your Leagues")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            if data.leagues.isEmpty {
                Text(
                    "No leagues yet. Join or create one "
                    + "from the Leagues tab."
                )
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            } else {
                ForEach(data.leagues) { league in
                    leagueRow(league, data: data)
                }
            }
        }
    }

    @ViewBuilder
    private func leagueRow(
        _ league: League,
        data: HomeData
    ) -> some View {
        let status = data.memberStatuses[league.id]
        let pick = data.picks[league.id]

        HStack {
            leagueRowContent(
                league: league,
                status: status,
                pick: pick
            )

            Spacer()

            leagueRowTrailing(status: status, pick: pick)
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r30)
        )
    }

    @ViewBuilder
    private func leagueRowContent(
        league: League,
        status: LeagueMember.MemberStatus?,
        pick: Pick?
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text(league.name)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            HStack(spacing: Theme.Spacing.s20) {
                if let status {
                    Text(status.rawValue.capitalized)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(statusColor(status))
                }

                if let count = league.memberCount {
                    HStack(spacing: Theme.Spacing.s10) {
                        Image(
                            systemName: Theme.Icon.League.members
                        )
                            .font(Theme.Typography.caption2)
                        Text("\(count)")
                            .font(Theme.Typography.caption1)
                    }
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func leagueRowTrailing(
        status: LeagueMember.MemberStatus?,
        pick: Pick?
    ) -> some View {
        if let pick {
            Text(pick.teamName)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        } else if status == .active {
            Text("Pick needed")
                .font(Theme.Typography.caption1)
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
        }
    }

    func statusColor(
        _ status: LeagueMember.MemberStatus
    ) -> Color {
        switch status {
        case .active:
            return Theme.Color.Status.Success.resting
        case .eliminated:
            return Theme.Color.Status.Error.resting
        case .winner:
            return Theme.Color.Status.Warning.resting
        }
    }
}
