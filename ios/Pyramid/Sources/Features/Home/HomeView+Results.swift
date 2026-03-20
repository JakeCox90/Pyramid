import SwiftUI

// MARK: - Last Gameweek Results

extension HomeView {
    @ViewBuilder
    func lastGwResultsSection(_ data: HomeData) -> some View {
        if !data.lastGwResults.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                Text("Last Results")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )

                ForEach(data.lastGwResults) { result in
                    resultCard(result)
                }
            }
        }
    }

    @ViewBuilder
    private func resultCard(
        _ result: LeagueResult
    ) -> some View {
        let survived = result.result == .survived

        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            resultCardHeader(result, survived: survived)
            resultCardScore(result)
            resultCardBadge(result)
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
                .strokeBorder(
                    survived
                        ? Theme.Color.Status.Success.resting
                        : Theme.Color.Status.Error.resting,
                    lineWidth: 1.5
                )
        )
    }

    @ViewBuilder
    private func resultCardHeader(
        _ result: LeagueResult,
        survived: Bool
    ) -> some View {
        HStack {
            Text(result.leagueName)
                .font(Theme.Typography.caption2)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .textCase(.uppercase)

            Spacer()

            Text(result.gameweekName)
                .font(Theme.Typography.caption2)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
    }

    @ViewBuilder
    private func resultCardScore(
        _ result: LeagueResult
    ) -> some View {
        HStack {
            TeamBadge(
                teamName: result.homeTeamName,
                logoURL: result.homeTeamLogo,
                size: 28
            )
            Text(result.homeTeamShort)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            Spacer()

            Text("\(result.homeScore)  \u{2013}  \(result.awayScore)")
                .font(Theme.Typography.title2)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .monospacedDigit()

            Spacer()

            Text(result.awayTeamShort)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
            TeamBadge(
                teamName: result.awayTeamName,
                logoURL: result.awayTeamLogo,
                size: 28
            )
        }
    }

    @ViewBuilder
    private func resultCardBadge(
        _ result: LeagueResult
    ) -> some View {
        switch result.result {
        case .survived:
            Label("Survived", systemImage: "checkmark.circle.fill")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
                )
        case .eliminated:
            Label("Eliminated", systemImage: "xmark.circle.fill")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
        case .void:
            Label("Void", systemImage: "minus.circle")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
        case .pending:
            EmptyView()
        }
    }
}
