import SwiftUI

// MARK: - Stats Header

extension LeagueDetailView {
    var statsHeader: some View {
        HStack(spacing: Theme.Spacing.s30) {
            if viewModel.isCompleted && viewModel.winnerCount > 0 {
                statBadge(
                    label: viewModel.winnerCount == 1 ? "Winner" : "Winners",
                    value: "\(viewModel.winnerCount)",
                    color: Theme.Color.Status.Warning.resting
                )
            } else {
                statBadge(
                    label: "Alive",
                    value: "\(viewModel.activeCount)",
                    color: Theme.Color.Status.Success.resting
                )
            }
            statBadge(
                label: "Eliminated",
                value: "\(viewModel.eliminatedCount)",
                color: Theme.Color.Status.Error.resting
            )
            if let gw = viewModel.currentGameweek {
                statBadge(
                    label: "Gameweek",
                    value: "\(gw.roundNumber)",
                    color: Theme.Color.Content.Text.disabled
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    func statBadge(label: String, value: String, color: Color) -> some View {
        Card {
            VStack(spacing: Theme.Spacing.s10) {
                Text(value)
                    .font(Theme.Typography.h3)
                    .foregroundStyle(color)
                Text(label)
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
