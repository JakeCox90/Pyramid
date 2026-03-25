import SwiftUI

struct StoryStandingCard: View {
    let players: [StandingPlayer]
    let totalCount: Int
    let userStatus: UserStoryStatus

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s50) {
                Text("Still Standing")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Primary.resting)

                if userStatus == .winner {
                    VStack(spacing: Theme.Spacing.s30) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.Color.Primary.resting)
                        Text("You Won!")
                            .font(Theme.Typography.h2)
                            .foregroundStyle(Theme.Color.Content.Text.default)
                    }
                } else {
                    Text("\(players.count) of \(totalCount) remain")
                        .font(Theme.Typography.h3)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                }

                ScrollView {
                    VStack(spacing: Theme.Spacing.s10) {
                        ForEach(players) { player in
                            HStack {
                                Text(player.displayName)
                                    .font(
                                        player.isCurrentUser
                                            ? Theme.Typography.subhead
                                            : Theme.Typography.body
                                    )
                                    .foregroundStyle(
                                        player.isCurrentUser
                                            ? Theme.Color.Primary.resting
                                            : Theme.Color.Content.Text.default
                                    )

                                if player.isCurrentUser {
                                    Text("You")
                                        .font(Theme.Typography.overline)
                                        .foregroundStyle(Theme.Color.Content.Text.contrast)
                                        .padding(.horizontal, Theme.Spacing.s20)
                                        .padding(.vertical, 2)
                                        .background(Theme.Color.Primary.resting)
                                        .clipShape(Capsule())
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Color.Status.Success.resting)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, Theme.Spacing.s40)
                            .padding(.vertical, Theme.Spacing.s20)
                            .background(
                                player.isCurrentUser
                                    ? Theme.Color.Primary.resting.opacity(0.1)
                                    : Theme.Color.Border.light
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r20))
                        }
                    }
                }
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "\(players.count) of \(totalCount) players still standing: "
            + players.map { $0.displayName + ($0.isCurrentUser ? " (you)" : "") }.joined(separator: ", ")
        )
    }
}
