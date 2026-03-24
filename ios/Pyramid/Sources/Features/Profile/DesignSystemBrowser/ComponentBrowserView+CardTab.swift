#if DEBUG
import SwiftUI

// MARK: - Card Tab

extension ComponentBrowserView {
    var cardContent: some View {
        Group {
            cardSection
            matchCardSection
            statsCardSection
            resultCardSection
            pickCarouselCardSection
            pickListCardSection
            leagueCardSection
            playersRemainingSection
        }
    }
}

// MARK: - Card

extension ComponentBrowserView {
    var cardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "Card")

            Card {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s20
                ) {
                    Text("Card")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .default
                        )
                    Text(
                        "Generic container with padding, background, radius, and shadow."
                    )
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                }
            }
        }
    }
}

// MARK: - LeagueCardView

extension ComponentBrowserView {
    var leagueCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "LeagueCardView")

            ComponentCaption(text: "Pending")
            LeagueCardView(
                league: League(
                    id: "1",
                    name: "Sunday League",
                    joinCode: "ABC123",
                    type: .free,
                    status: .pending,
                    season: 2025,
                    createdAt: Date(),
                    emoji: "⚽",
                    description: "Waiting for the boys"
                )
            )

            ComponentCaption(text: "Active")
            LeagueCardView(
                league: League(
                    id: "2",
                    name: "Office Crew",
                    joinCode: "XYZ789",
                    type: .free,
                    status: .active,
                    season: 2025,
                    createdAt: Date(),
                    emoji: "🔥",
                    description: "The lads"
                )
            )

            ComponentCaption(text: "Completed")
            LeagueCardView(
                league: League(
                    id: "3",
                    name: "Champions League",
                    joinCode: "WIN999",
                    type: .free,
                    status: .completed,
                    season: 2025,
                    createdAt: Date(),
                    emoji: "🏆"
                )
            )

            ComponentCaption(text: "No description")
            LeagueCardView(
                league: League(
                    id: "4",
                    name: "Quick Game",
                    joinCode: "QCK111",
                    type: .free,
                    status: .active,
                    season: 2025,
                    createdAt: Date(),
                    emoji: "⚡"
                )
            )
        }
    }
}

// MARK: - PlayersRemainingCard

extension ComponentBrowserView {
    var playersRemainingSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "PlayersRemainingCard"
            )

            PlayersRemainingCard(remaining: "8/12")

            ComponentCaption(
                text: "With action button"
            )
            PlayersRemainingCard(
                remaining: "5/10",
                onSeeResults: {}
            )
        }
    }
}
#endif
