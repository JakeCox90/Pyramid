import SwiftUI

// MARK: - Carousel Page (Card + Stats)

extension PickCarouselView {
    func carouselPage(
        fixture: Fixture,
        index: Int,
        cardWidth: CGFloat
    ) -> some View {
        ZStack {
            // Stats panel behind the card
            MatchStatsPanel(
                fixture: fixture,
                stats: .placeholder
            )
            .frame(width: cardWidth)
            .contentShape(Rectangle())
            .gesture(
                isStatsRevealed
                    ? swipeDownGesture : nil
            )

            // Card in front, slides up on drag
            cardWithGesture(
                fixture: fixture,
                cardWidth: cardWidth
            )
        }
        .frame(height: 500)
        .clipped()
    }

    private func cardWithGesture(
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
        .offset(y: isStatsRevealed ? -380 : cardOffsetY)
        .gesture(verticalDragGesture)
        .animation(
            .spring(
                response: 0.4,
                dampingFraction: 0.8
            ),
            value: isStatsRevealed
        )
        .animation(
            .spring(
                response: 0.4,
                dampingFraction: 0.8
            ),
            value: cardOffsetY
        )
    }

    // Swipe up on card to reveal stats
    var verticalDragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let dy = value.translation.height
                if !isStatsRevealed && dy < 0 {
                    cardOffsetY = dy
                }
            }
            .onEnded { value in
                if value.translation.height < -100 {
                    isStatsRevealed = true
                }
                cardOffsetY = 0
            }
    }

    // Swipe down on stats panel to dismiss
    var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let dy = value.translation.height
                if isStatsRevealed && dy > 0 {
                    cardOffsetY = dy
                }
            }
            .onEnded { value in
                if value.translation.height > 80 {
                    isStatsRevealed = false
                }
                cardOffsetY = 0
            }
    }
}
