import SwiftUI

// MARK: - Empty State

extension LeaguesView {
    var emptyStateContent: some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(spacing: Theme.Spacing.s50) {
                emptyStateIllustration

                VStack(spacing: Theme.Spacing.s30) {
                    Text("No leagues yet")
                        .font(Theme.Typography.h3)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )

                    Text(
                        "Pick one team per gameweek. "
                        + "Win or draw, you survive. "
                        + "Lose, you're out."
                    )
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .multilineTextAlignment(.center)

                    Text(
                        "Browse open leagues, create your own, "
                        + "or join one with a code."
                    )
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                    .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: Theme.Spacing.s30) {
                Button("Browse Free Leagues") {
                    showBrowseLeagues = true
                }
                .themed(.primary)

                Button("Create a League") {
                    showCreateLeague = true
                }
                .themed(.secondary)

                Button("Join with Code") {
                    showJoinLeague = true
                }
                .themed(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var emptyStateIllustration: some View {
        ZStack {
            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.system(size: 64))
                .foregroundStyle(Theme.Color.Primary.resting)

            Image(systemName: Theme.Icon.League.members)
                .font(.system(size: 22))
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .offset(x: -48, y: -20)

            Image(
                systemName: Theme.Icon.Pick.noRepeat
            )
            .font(.system(size: 18))
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
            .offset(x: 50, y: -22)

            Image(
                systemName: Theme.Icon.Status.success
            )
            .font(.system(size: 16))
            .foregroundStyle(
                Theme.Color.Status.Success.resting
            )
            .offset(x: -40, y: 28)

            Image(
                systemName: Theme.Icon.Status.failure
            )
            .font(.system(size: 16))
            .foregroundStyle(
                Theme.Color.Status.Error.resting
            )
            .offset(x: 42, y: 28)
        }
        .frame(height: Theme.Spacing.s120)
    }
}
