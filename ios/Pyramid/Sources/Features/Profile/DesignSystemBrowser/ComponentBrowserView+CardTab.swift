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
    private static let mockMembers: [MemberSummary] = [
        MemberSummary(
            userId: "me",
            displayName: "You",
            avatarURL: nil,
            status: .active
        ),
        MemberSummary(
            userId: "u2",
            displayName: "Alice",
            avatarURL: nil,
            status: .active
        ),
        MemberSummary(
            userId: "u3",
            displayName: "Bob",
            avatarURL: nil,
            status: .eliminated
        ),
        MemberSummary(
            userId: "u4",
            displayName: "Carol",
            avatarURL: nil,
            status: .active
        )
    ]

    var body: some View {
        DemoPageStatic {
            VStack(spacing: Theme.Spacing.s30) {
                PlayersRemainingCard(
                    activeCount: 8,
                    totalCount: 12,
                    eliminatedThisWeek: 4,
                    survivalStreak: 3,
                    userStatus: .active,
                    currentUserId: "me",
                    members: Self.mockMembers
                )
                PlayersRemainingCard(
                    activeCount: 2,
                    totalCount: 10,
                    eliminatedThisWeek: 3,
                    survivalStreak: 2,
                    userStatus: .eliminated,
                    currentUserId: "u3",
                    members: Self.mockMembers
                )
            }
        }
    }
}
#endif
