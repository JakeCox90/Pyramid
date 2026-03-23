import SwiftUI

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.s30) {
            rankView
            avatarView
            nameAndStats
            Spacer()
            trailingStats
        }
        .padding(Theme.Spacing.s30)
        .background(rowBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
        )
    }

    // MARK: - Subviews

    private var rankView: some View {
        Text("#\(entry.rank)")
            .font(Theme.Typography.subhead)
            .foregroundStyle(rankColor)
            .frame(minWidth: 32, alignment: .leading)
    }

    private var avatarView: some View {
        Circle()
            .fill(Theme.Color.Surface.Background.container)
            .frame(width: 36, height: 36)
            .overlay(
                Text(avatarInitial)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            )
    }

    private var nameAndStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.displayName ?? "Anonymous")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .lineLimit(1)

            HStack(spacing: Theme.Spacing.s10) {
                Text("\(entry.totalPicks) picks")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)

                if entry.wins > 0 {
                    Text("· \(entry.wins)W")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.Status.Warning.resting)
                }
            }
        }
    }

    private var trailingStats: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(entry.survivalRatePct)%")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Status.Success.resting)

            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Status.Warning.resting)
                Text("\(entry.longestStreak)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
        }
    }

    // MARK: - Helpers

    private var rankColor: Color {
        switch entry.rank {
        case 1, 2, 3:
            return Theme.Color.Status.Warning.resting
        default:
            return Theme.Color.Content.Text.subtle
        }
    }

    private var rowBackground: Color {
        if isCurrentUser {
            return Theme.Color.Primary.resting.opacity(0.15)
        }
        return Theme.Color.Surface.Background.container
    }

    private var avatarInitial: String {
        entry.displayName?.first.map(String.init) ?? "?"
    }
}
