import SwiftUI

// MARK: - Carousel Page (Card + Stats Flip)

extension PickCarouselView {
    func carouselPage(
        fixture: Fixture,
        index: Int,
        cardWidth: CGFloat
    ) -> some View {
        let isCurrent = index == currentIndex
        let flipped = isCurrent && isStatsRevealed

        return ZStack {
            // Back face: Stats card (pre-rotated 180°)
            MatchCarouselCardStats(
                fixture: fixture,
                stats: .placeholder,
                onBack: {
                    withAnimation(flipAnimation) {
                        isStatsRevealed = false
                    }
                }
            )
            .rotation3DEffect(
                .degrees(flipped ? 0 : -180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .opacity(flipped ? 1 : 0)

            // Front face: Match card
            cardView(
                fixture: fixture,
                cardWidth: cardWidth
            )
            .rotation3DEffect(
                .degrees(flipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .opacity(flipped ? 0 : 1)
        }
        .frame(width: cardWidth, height: 440)
        .clipped()
        .mask(bottomFadeMask)
        .animation(flipAnimation, value: isStatsRevealed)
    }

    private var flipAnimation: Animation {
        .spring(response: 0.5, dampingFraction: 0.85)
    }

    private func cardView(
        fixture: Fixture,
        cardWidth: CGFloat
    ) -> some View {
        MatchCarouselCard(
            fixture: fixture,
            selectedTeamId: viewModel.currentPick?.teamId,
            usedTeamIds: viewModel.usedTeamIds,
            usedTeamRounds: viewModel.usedTeamRounds,
            isLocked: viewModel.isFixtureLocked(fixture),
            isSubmitting: viewModel.isSubmitting,
            submittingTeamId: viewModel.submittingTeamId,
            onPick: { teamId, teamName in
                Task {
                    await viewModel.submitPick(
                        fixtureId: fixture.id,
                        teamId: teamId,
                        teamName: teamName
                    )
                }
            },
            onStats: {
                withAnimation(flipAnimation) {
                    isStatsRevealed = true
                }
            }
        )
    }

    // Gradient fade at the bottom instead of hard clip.
    // The solid region must extend past the button area
    // so taps are not blocked by the transparent mask.
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
            .frame(height: 12)
        }
    }
}
