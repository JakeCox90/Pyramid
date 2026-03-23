import SwiftUI

// MARK: - League completion subviews

extension LeagueDetailView {
    var winnerBanner: some View {
        Button { showCompleteView = true } label: {
            Card {
                HStack(spacing: Theme.Spacing.s30) {
                    Image(systemName: Theme.Icon.League.trophyFill)
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Color.Status.Warning.resting)

                    VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                        Text("League Complete")
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(Theme.Color.Content.Text.default)

                        winnerSubtitle
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.overline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.s40)
    }

    @ViewBuilder private var winnerSubtitle: some View {
        if viewModel.winnerCount == 1,
           let winner = viewModel.winners.first {
            Text("\(winner.profiles.displayLabel) wins!")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        } else if viewModel.winnerCount > 1 {
            Text("\(viewModel.winnerCount) Joint Winners")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }
}
