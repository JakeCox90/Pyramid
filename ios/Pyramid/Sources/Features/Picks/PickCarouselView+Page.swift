import SwiftUI

// MARK: - Carousel Page (Card + Stats)

extension PickCarouselView {
    func carouselPage(
        fixture: Fixture,
        index: Int,
        cardWidth: CGFloat
    ) -> some View {
        VStack(spacing: 16) {
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
                    y: isStatsRevealed ? -500 : cardOffsetY
                )
                .allowsHitTesting(!isStatsRevealed)
            }
            .frame(height: 452)
            .mask(bottomFadeMask)
            .contentShape(Rectangle())
            .simultaneousGesture(dragGesture)
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

            fixtureInfo(fixture: fixture)
        }
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

    private func fixtureInfo(
        fixture: Fixture
    ) -> some View {
        VStack(spacing: 4) {
            if let venue = FixtureMetadata.venue(
                forHomeTeam: fixture.homeTeamName
            ) {
                Text(venue)
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Color.white.opacity(0.5)
                    )
            }

            Text(
                fixture.kickoffAt,
                format: .dateTime
                    .weekday(.abbreviated)
                    .day(.defaultDigits)
                    .month(.abbreviated)
                    .hour(.defaultDigits(
                        amPM: .abbreviated
                    ))
                    .minute(.twoDigits)
            )
            .font(Theme.Typography.label01)
            .textCase(.uppercase)
            .foregroundStyle(
                Color.white.opacity(0.4)
            )

            Text(FixtureMetadata.broadcastNote)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Color.white.opacity(0.3)
                )
        }
    }

    // Gradient fade at the bottom instead of hard clip
    private var bottomFadeMask: some View {
        VStack(spacing: 0) {
            Color.white
            LinearGradient(
                colors: [Color.white, Color.white.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
        }
    }

    // Vertical-only gesture for stats reveal
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                // Only handle vertical drags
                guard abs(dy) > abs(dx) else { return }
                if isStatsRevealed && dy > 0 {
                    cardOffsetY = dy
                } else if !isStatsRevealed && dy < 0 {
                    cardOffsetY = dy
                }
            }
            .onEnded { value in
                let dy = value.translation.height
                if isStatsRevealed && dy > 80 {
                    isStatsRevealed = false
                } else if !isStatsRevealed && dy < -100 {
                    isStatsRevealed = true
                }
                cardOffsetY = 0
            }
    }
}
