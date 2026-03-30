#if DEBUG
import SwiftUI

struct CardDemo: View {
    var body: some View {
        DemoPageStatic {
            Card {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s20
                ) {
                    Text("Card")
                        .font(
                            Theme.Typography.subhead
                        )
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .default
                        )
                    Text(
                        "Generic container with padding, background, radius, and shadow."
                    )
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .subtle
                    )
                }
            }
        }
    }
}

struct LeagueCardDemo: View {
    var body: some View {
        DemoPageStatic {
            VStack(spacing: Theme.Spacing.s30) {
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
                        description:
                            "Waiting for the boys"
                    )
                )
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
            }
        }
    }
}

struct PlayersRemainingDemo: View {
    var body: some View {
        DemoPageStatic {
            VStack(spacing: Theme.Spacing.s30) {
                PlayersRemainingCard(
                    playerCount: PlayerCount(
                        active: 8, total: 12,
                        eliminationHistory: [
                            EliminationSnapshot(
                                gameweekId: 1,
                                eliminated: 2
                            ),
                            EliminationSnapshot(
                                gameweekId: 2,
                                eliminated: 2
                            ),
                        ]
                    ),
                    onTap: nil
                )
                PlayersRemainingCard(
                    playerCount: PlayerCount(
                        active: 2, total: 30,
                        eliminationHistory: [
                            EliminationSnapshot(
                                gameweekId: 1,
                                eliminated: 5
                            ),
                            EliminationSnapshot(
                                gameweekId: 2,
                                eliminated: 8
                            ),
                            EliminationSnapshot(
                                gameweekId: 3,
                                eliminated: 10
                            ),
                            EliminationSnapshot(
                                gameweekId: 4,
                                eliminated: 5
                            ),
                        ]
                    ),
                    onTap: {}
                )
            }
        }
    }
}
#endif
