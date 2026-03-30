import SwiftUI

// MARK: - Players Remaining Card

extension HomeView {
    @ViewBuilder
    func playersRemainingCard(
        for league: League
    ) -> some View {
        if let counts = viewModel.playerCounts(
            for: league
        ), counts.total > 0 {
            PlayersRemainingCard(
                playerCount: counts,
                onTap: nil
            )
        }
    }
}
