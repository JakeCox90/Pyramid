import SwiftUI

// MARK: - Post-Elimination Spectator Banner

extension LeagueDetailView {
    var spectatorBanner: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
                HStack(spacing: Theme.Spacing.s20) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                        .accessibilityHidden(true)

                    Text("Spectator Mode")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                }

                Text(spectatorMessage)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)

                Button {
                    showBrowseLeagues = true
                } label: {
                    HStack(spacing: Theme.Spacing.s10) {
                        Image(systemName: "magnifyingglass")
                        Text("Browse Leagues")
                            .font(Theme.Typography.label01)
                    }
                    .foregroundStyle(Theme.Color.Primary.resting)
                    .padding(.horizontal, Theme.Spacing.s30)
                    .padding(.vertical, Theme.Spacing.s20)
                    .background(Theme.Color.Primary.resting.opacity(0.1))
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Browse leagues to join a new one")
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var spectatorMessage: String {
        if let gw = viewModel.currentUserMember?.eliminatedInGameweekId {
            return "You were eliminated in Gameweek \(gw). "
                + "You can still follow this league's standings, recaps, and activity."
        }
        return "You've been eliminated from this league. "
            + "You can still follow the standings, recaps, and activity."
    }
}
