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
