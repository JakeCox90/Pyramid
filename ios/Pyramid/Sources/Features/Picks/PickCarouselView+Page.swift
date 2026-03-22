import SwiftUI

// MARK: - Carousel Page (Card + Stats)

extension PickCarouselView {
    func carouselPage(
        fixture: Fixture,
        index: Int,
        cardWidth: CGFloat
    ) -> some View {
        ZStack {
            MatchStatsPanel(
                fixture: fixture,
                stats: .placeholder
            )
            .frame(width: cardWidth)

            cardView(
                fixture: fixture,
                cardWidth: cardWidth
            )
            .offset(
                y: index == currentIndex
                    ? (isStatsRevealed ? -500 : cardOffsetY)
                    : 0
            )
            .allowsHitTesting(
                !(isStatsRevealed && index == currentIndex)
            )
        }
        .frame(height: 520)
        .mask(bottomFadeMask)
    }

    private func cardView(
        fixture: Fixture,
        cardWidth: CGFloat
    ) -> some View {
        MatchCarouselCard(
            fixture: fixture,
            selectedTeamId: viewModel.currentPick?.teamId,
            usedTeamIds: viewModel.usedTeamIds,
            isLocked: viewModel.isFixtureLocked(fixture),
            isSubmitting: viewModel.isSubmitting,
            submittingTeamId: viewModel.submittingTeamId
        ) { teamId, teamName in
            Task {
                await viewModel.submitPick(
                    fixtureId: fixture.id,
                    teamId: teamId,
                    teamName: teamName
                )
            }
        }
    }

    // Gradient fade at the bottom instead of hard clip
    private var bottomFadeMask: some View {
        VStack(spacing: 0) {
            Color.white
            LinearGradient(
                colors: [
                    Color.white,
                    Color.white.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
        }
    }
}
