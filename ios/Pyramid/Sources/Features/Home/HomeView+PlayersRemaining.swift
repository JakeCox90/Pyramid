import SwiftUI

// MARK: - Players Remaining Card

extension HomeView {
    @ViewBuilder
    func playersRemainingCard(
        for league: League
    ) -> some View {
        let remaining = viewModel.playersRemaining(
            for: league
        )
        if !remaining.isEmpty {
            PlayersRemainingCard(
                remaining: remaining
            )
        }
    }
}
